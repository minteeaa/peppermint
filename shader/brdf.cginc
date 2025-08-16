// base model and most of these functions from Google's Filament
// https://google.github.io/filament/Filament.md.html#materialsystem/diffusebrdf

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

float V_SmithGGXCorrelated(float NoV, float NoL, float a) 
{
    float a2 = a * a;
    float GGXL = NoV * sqrt((-NoL * a2 + NoL) * NoL + a2);
    float GGXV = NoL * sqrt((-NoV * a2 + NoV) * NoV + a2);
    return 0.5 / (GGXV + GGXL);
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
    float4 dfgSample = TEX2D_SAMPLE_SAMPLER(_dfg, dfg_bilinear_clamp_sampler, dfgUV);
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

float3 PrepareDirectSpecularTerm(in LightingData ld)
{
    float D = D_GGX(ld.NoH, _Roughness);
    float3 F = F_Schlick(ld.LoH, ld.f0);
    float V = V_SmithGGXCorrelated(ld.NoV, ld.NoL, _Roughness);
    float3 spec = (D * V) * F;
    spec *= ld.energyCompensation;
    spec *= ld.horizon * ld.horizon;

    if (_ClampSpecular) 
    {
        spec = spec / (1.0 + spec);
    }

    spec *= ld.illuminance;
    return spec;
}

float3 PrepareDirectDiffuseTerm(in LightingData ld)
{
    float3 Fd = Fd_Oren_Nayar(ld.NoL, ld.LoV, ld.NoV, _Roughness, _Diffuse);
    Fd *= _Diffuse;
    Fd *= ld.illuminance;
    return Fd;
}

float3 PrepareVertexSpecularTerm(in VertexLightingData vld, in LightingData ld)
{
    float3 vertexSpecTerm = 0;
    for (int index = 0; index < 4; index++)
    {
        float D = D_GGX(vld.NoH[index], _Roughness);
        float3 F = F_Schlick(vld.LoH[index], ld.f0);
        float V = V_SmithGGXCorrelated(ld.NoV, vld.attNoL[index], _Roughness);
        float3 interVST = (D * V) * F;
        interVST *= ld.energyCompensation;
        interVST *= ld.horizon * ld.horizon;

        if (_ClampSpecular) 
        {
            interVST = interVST / (1.0 + interVST);
        }

        interVST *= vld.color[index];
        interVST *= vld.attenuation[index];
        vertexSpecTerm += interVST;
    }
    return vertexSpecTerm;
}

float3 PrepareVertexDiffuseTerm(in VertexLightingData vld, in LightingData ld)
{
    float3 vertexDiffuseTerm = 0;
    for (int index = 0; index < 4; index++)
    {
        float LoV = clamp(dot(vld.lightDir[index], ld.viewDir), 0.0, 1.0);
        float3 interVDT = Fd_Oren_Nayar(vld.NoL[index], LoV, ld.NoV, _Roughness, _Diffuse);
        interVDT *= _Diffuse;
        interVDT *= vld.color[index];
        interVDT *= vld.attenuation[index];
        vertexDiffuseTerm += interVDT;
    }
    return vertexDiffuseTerm;
}

float3 PrepareIndirectSpecularTerm(in LightingData ld)
{
    float4 dfgSample = PrepareDFG(ld);
    float3 dfg = lerp(dfgSample.x, dfgSample.y, ld.f0);

    ld.indirectSpecular *= ComputeSpecularAO(ld.NoV, _Occlusion, _Roughness);
    ld.indirectSpecular *= ld.horizon * ld.horizon;
    return ld.indirectSpecular * dfg;
}

float3 PrepareIndirectDiffuseTerm(in LightingData ld)
{
    ld.indirectDiffuse *= Fd_Lambert();
    ld.indirectDiffuse *= _Occlusion;
    return ld.indirectDiffuse * _Diffuse;
}

void ApplyLighting(inout LightingData ld, in VertexLightingData vld, in v2f i)
{
    PrepareEnergyCompensation(ld);
    float3 specular = PrepareDirectSpecularTerm(ld) + PrepareIndirectSpecularTerm(ld);
    float3 diffuse = PrepareDirectDiffuseTerm(ld) + PrepareIndirectDiffuseTerm(ld);

    ld.surfaceColor = diffuse + specular;

    float3 vertSpecular = 0;
    float3 vertDiffuse = 0;
    #if defined(PASS_BASE)
        if (i.useVertexLights) {
            vertSpecular = PrepareVertexSpecularTerm(vld, ld);
            vertDiffuse = PrepareVertexDiffuseTerm(vld, ld);

            ld.surfaceColor += vertDiffuse + vertSpecular;
        }
    #endif
}