/* 
    base model and most of these functions are either directly from 
    or heavily derived from Google's Filament
    https://google.github.io/filament/Filament.md.html#materialsystem/diffusebrdf

    good references for many of these functions:
    https://github.com/google/filament/blob/main/shaders/src/surface_light_indirect.fs
    https://github.com/google/filament/blob/main/shaders/src/surface_shading_model_cloth.fs
    https://github.com/google/filament/blob/main/shaders/src/surface_shading_model_standard.fs
*/

// TODO: make this file readable for god's sake
// TODO: actual subsurface shading model maybe

float3 F_Schlick(float u, float3 f0)
{
    return f0 + (float3(1.0, 1.0, 1.0) - f0) * pow(1.0 - u, 5.0);
}

float D_GGX(float NoH, float a) 
{
    float a2 = a * a;
    float f = (NoH * a2 - NoH) * NoH + 1.0;
    return a2 / (PI * f * f);
}

float D_GGX_Anisotropic(float at, float ab, float ToH, float BoH, float NoH) {
    // Burley 2012, "Physically-Based Shading at Disney"

    float a2 = at * ab;
    float3 d = float3(ab * ToH, at * BoH, a2 * NoH);
    float d2 = dot(d, d);
    float b2 = a2 / d2;
    return a2 * b2 * b2 * (1.0 / PI);
}

float D_Charlie(float NoH, float roughness) {
    // Estevez and Kulla 2017, "Production Friendly Microfacet Sheen BRDF"
    float invAlpha  = 1.0 / roughness;
    float cos2h = NoH * NoH;
    float sin2h = max(1.0 - cos2h, 0.0078125);
    return (2.0 + invAlpha) * pow(sin2h, invAlpha * 0.5) / (2.0 * PI);
}

float V_SmithGGXCorrelated(float NoV, float NoL, float a) 
{
    float a2 = a * a;
    float GGXL = NoV * sqrt((-NoL * a2 + NoL) * NoL + a2);
    float GGXV = NoL * sqrt((-NoV * a2 + NoV) * NoV + a2);
    return 0.5 / (GGXV + GGXL);
}

float V_SmithGGXCorrelated_Anisotropic(float at, float ab, float ToV, float BoV,
        float ToL, float BoL, float NoV, float NoL) {
    // Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
    // TODO: lambdaV can be pre-computed for all the lights, it should be moved out of this function
    float lambdaV = NoL * length(float3(at * ToV, ab * BoV, NoV));
    float lambdaL = NoV * length(float3(at * ToL, ab * BoL, NoL));
    // 0.0000077 = nextafter(0.5 / MEDIUMP_FLT_MAX, 1.0) in fp16, so we don't overflow
    float v = PREVENT_DIV0(0.5, lambdaV + lambdaL, 0.0000077);
    return v;
}

float V_Neubelt(float NoV, float NoL) {
    // Neubelt and Pettineo 2013, "Crafting a Next-gen Material Pipeline for The Order: 1886"
    return PREVENT_DIV0(1.0, 4.0 * (NoL + NoV - NoL * NoV), 0.00001532);
}

float Fd_Lambert() 
{
    return 1.0 / PI;
}

// Oren-Nayar reflectance-diffuse model 
// https://www.cs.cornell.edu/~srm/publications/EGSR07-btdf.pdf
// https://dl.acm.org/doi/10.1145/192161.192213

float Fd_Oren_Nayar(in float NoL, in float LoV, in float NoV, in float Rough, in float diffuse)
{
    float s = LoV - NoL * NoV;
    float t = lerp(1.0, max(NoL, NoV), step(0.0, s));
    float A = 1.0 + Rough * (diffuse / (Rough + 0.13) + 0.5 / (Rough + 0.33));
    float B = 0.45 * Rough / (Rough + 0.09);

    return max(0.0, NoL) * (A + B * s / t) / PI;
}

float4 PrepareDFG(in LightingData ld)
{
    float2 dfgUV = float2(ld.NoV, _Roughness);
    #ifdef _PM_NDF_CHARLIE
        float4 dfgSample = TEX2D_SAMPLE_SAMPLER(_dfg_cloth, dfg_bilinear_clamp_sampler, dfgUV);
    #else
        float4 dfgSample = TEX2D_SAMPLE_SAMPLER(_dfg, dfg_bilinear_clamp_sampler, dfgUV);
    #endif
    return dfgSample;
}

void PrepareEnergyCompensation(inout LightingData ld)
{
    float4 dfgSample = PrepareDFG(ld);
    half3 energyCompensation = 1.0 + ld.f0 * (1.0 / max(dfgSample.y, 0.005) - 1.0);
    ld.energyCompensation = energyCompensation;
}

float ComputeSpecularAO(in float NoV, in float ao, in float roughness)
{
    return clamp(pow(NoV + ao, exp2(-16.0 * roughness - 1.0)) - 1.0 + ao, 0.0, 1.0);
}

float3 PrepareDirectSpecularTerm(in LightingData ld, in AnisotropyData ad)
{
    float D = 0;
    float V = 0;
    float3 spec = 0;
    float F = 0;

    #ifdef _PM_NDF_GGX
        #ifdef _PM_FT_ANISOTROPICS
            // Kulla 2017, "Revisiting Physically Based Shading at Imageworks"
            float at = max(_Roughness * (1.0 + _AnisotropicsStrength), 0.04);
            float ab = max(_Roughness * (1.0 - _AnisotropicsStrength), 0.04);

            float ToH = dot(ad.t, ld.h);
            float BoH = dot(ad.b, ld.h);
            float ToV = dot(ad.t, ld.viewDir);
            float BoV = dot(ad.b, ld.viewDir);
            float ToL = dot(ad.t, ld.lightDir);
            float BoL = dot(ad.b, ld.lightDir);

            D = D_GGX_Anisotropic(at, ab, ToH, BoH, ld.NoH);
            V = V_SmithGGXCorrelated_Anisotropic(at, ab, ToV, BoV, ToL, BoL, ld.NoV, ld.NoL);
            F = F_Schlick(ld.LoH, ld.f0);
        #else
            D = D_GGX(ld.NoH, _Roughness);
            V = V_SmithGGXCorrelated(ld.NoV, ld.NoL, _Roughness);
            F = F_Schlick(ld.LoH, ld.f0);
        #endif
        spec = (D * V) * F;
        spec *= ld.energyCompensation;
        spec *= ld.horizon * ld.horizon;
    #endif
    #ifdef _PM_NDF_CHARLIE
        D = D_Charlie(ld.NoH, _Roughness);
        V = V_Neubelt(ld.NoV, ld.NoL);
        F = ld.f0;
        spec = (D * V) * F;
    #endif 

    // blame vrchat and bloom usage
    if (_ClampSpecular) 
    {
        spec = spec / (1.0 + spec);
    }

    return spec;
}

float3 PrepareDirectDiffuseTerm(in LightingData ld)
{
    // prepare initial diffuse term
    float3 diffuse = Fd_Oren_Nayar(ld.NoL, ld.LoV, ld.NoV, _Roughness, _Diffuse);

    // simulate subsurface scattering
    #ifdef _PM_FT_SUBSURFACE
        diffuse *= saturate((dot(_NormalWS, ld.mainLightColor) + 0.5) / 2.25);
    #endif

    // return the direct diffuse term, add the specular term and process subsurface later
    float3 Fd = diffuse * _Diffuse;
    return Fd;
}

float3 PrepareVertexSpecularTerm(in VertexLightingData vld, in LightingData ld, in AnisotropyData ad, in int index)
{
    float D = 0;
    float V = 0;
    float3 vR = 0;
    float F = 0;

    #ifdef _PM_NDF_GGX
        #ifdef _PM_FT_ANISOTROPICS
            // Kulla 2017, "Revisiting Physically Based Shading at Imageworks"
            float at = max(_Roughness * (1.0 + _AnisotropicsStrength), 0.04);
            float ab = max(_Roughness * (1.0 - _AnisotropicsStrength), 0.04);

            float ToH = dot(ad.t, vld.h[index]);
            float BoH = dot(ad.b, vld.h[index]);
            float ToV = dot(ad.t, ld.viewDir);
            float BoV = dot(ad.b, ld.viewDir);
            float ToL = dot(ad.t, vld.lightDir[index]);
            float BoL = dot(ad.b, vld.lightDir[index]);

            D = D_GGX_Anisotropic(at, ab, ToH, BoH, vld.NoH[index]);
            V = V_SmithGGXCorrelated_Anisotropic(at, ab, ToV, BoV, ToL, BoL, ld.NoV, vld.NoL[index]);
            F = F_Schlick(vld.LoH[index], ld.f0);
        #else
            D = D_GGX(vld.NoH[index], _Roughness);
            V = V_SmithGGXCorrelated(ld.NoV, vld.attNoL[index], _Roughness);
            F = F_Schlick(vld.LoH[index], ld.f0);
        #endif
        vR = (D * V) * F;
        vR *= ld.energyCompensation;
        vR *= ld.horizon * ld.horizon;
    #endif
    #ifdef _PM_NDF_CHARLIE
        D = D_Charlie(vld.NoH[index], _Roughness);
        V = V_Neubelt(ld.NoV, vld.NoL[index]);
        F = ld.f0;
        vR = (D * V) * F;
    #endif

    if (_ClampSpecular) 
    {
        vR = vR / (1.0 + vR);
    }

    return vR;
}

float3 PrepareVertexDiffuseTerm(in VertexLightingData vld, in LightingData ld, in int index)
{
    float LoV = clamp(dot(vld.lightDir[index], ld.viewDir), 0.0, 1.0);
    float3 vDiffuse = Fd_Oren_Nayar(vld.NoL[index], LoV, ld.NoV, _Roughness, _Diffuse);

    #ifdef _PM_FT_SUBSURFACE
        vDiffuse *= saturate((dot(_NormalWS, vld.color[index]) + 0.5) / 2.25);
    #endif

    float3 vD = vDiffuse * _Diffuse;
    return vD;
}

void EvalSubsurfaceIBL(inout float3 Fd, in LightingData ld) 
{
    #if defined(_PM_NDF_CHARLIE) && defined(_PM_FT_SUBSURFACE)
        Fd *= saturate(_Subsurface + ld.NoV);
    #endif
}

float3 PrepareIndirectSpecularTerm(in LightingData ld)
{
    // evaluate initial IBL
    float4 dfgSample = PrepareDFG(ld);
    float3 E;
    #ifdef _PM_NDF_CHARLIE
        E = ld.f0 * dfgSample.z;
    #else
        E = lerp(dfgSample.x, dfgSample.y, ld.f0);
    #endif

    float3 Fr = E * ld.indirectSpecular;

    Fr *= ComputeSpecularAO(ld.NoV, _Occlusion, _Roughness);

    Fr *= ld.horizon * ld.horizon;
    
    return Fr;
}

float3 PrepareIndirectDiffuseTerm(in LightingData ld)
{
    // evaluate initial IBL
    float4 dfgSample = PrepareDFG(ld);
    float3 E;
    #ifdef _PM_NDF_CHARLIE
        E = ld.f0 * dfgSample.z;
    #else
        E = lerp(dfgSample.x, dfgSample.y, ld.f0);
    #endif

    float3 Fd = _Diffuse * ld.indirectDiffuse * (1.0 - E) * (Fd_Lambert() * _Occlusion);

    // apply subsurface (not a full subsurface shading model)
    EvalSubsurfaceIBL(Fd, ld);

    return Fd; 
}

void ApplyLighting(inout LightingData ld, in VertexLightingData vld, in AnisotropyData ad, in v2f i)
{
    PrepareEnergyCompensation(ld);
    float3 Fd = 0;
    float3 Fr = 0;
    float3 IFd = PrepareIndirectDiffuseTerm(ld);
    float3 IFr = PrepareIndirectSpecularTerm(ld);
    float3 direct = 0;
    float3 indirect = IFd + IFr;

    // calculate direct lighting, only if there is direct lighting to calculate
    if (ld.NoL > 0) 
    {
        Fd = PrepareDirectDiffuseTerm(ld);
        Fr = PrepareDirectSpecularTerm(ld, ad);

        #ifdef _PM_FT_SUBSURFACE
            // TODO: don't do this
            // this isn't technically correct, "simulated" subsurface doesn't ingest a thickness map
            // but it's here for the extra perceptual accuracy, it works well
            Fd *= saturate((_Subsurface + ld.NoL) * _Thickness);
            direct = Fd + Fr * ld.NoL;
            direct *= ld.illuminance;
        #else
            direct = Fd + Fr;
            direct *= ld.illuminance * ld.NoL;
        #endif

        ld.surfaceColor += direct;
    }

    #if defined(PASS_BASE)
        if (i.useVertexLights) {
            float3 vertLighting = 0;
            for (int index = 0; index < 4; index++)
            {
                if (vld.NoL[index] > 0) {
                float3 vL = 0;
                float3 vD = PrepareVertexDiffuseTerm(vld, ld, index);
                float3 vR = PrepareVertexSpecularTerm(vld, ld, ad, index);
                #ifdef _PM_FT_SUBSURFACE
                    vD *= saturate((_Subsurface + vld.NoL[index]) * _Thickness);
                    vL = vD + vR * vld.NoL[index];
                    vL *= vld.color[index];
                    vL *= vld.attenuation[index];
                #else
                    vL = vD + vR;
                    vL *= vld.color[index];
                    vL *= vld.attenuation[index] * vld.NoL[index];
                #endif
                vertLighting += vL;
                }
            }
            ld.surfaceColor += vertLighting;
        }
    #endif

    ld.surfaceColor += indirect;
}