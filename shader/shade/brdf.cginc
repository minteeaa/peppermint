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

/* 
    diffuse brdf impls
 */

float pm_D_GGX2(float NoH, float roughness) {
    float oneMinusNoHSquared = 1.0 - NoH * NoH;

    float a = NoH * roughness;
    float k = min(roughness / (oneMinusNoHSquared + a * a), 453.5);
    float d = k * (k * (1.0 / PI));
    return d;
}

float pm_D_GGX(float NoH, float a) 
{
    float f = (NoH * a - NoH) * NoH + 1.0;
    return a / (PI * f * f);
}

float pm_D_GGX_Anisotropic(float at, float ab, float ToH, float BoH, float NoH) {
    // Burley 2012, "Physically-Based Shading at Disney"

    float a2 = at * ab;
    float3 d = float3(ab * ToH, at * BoH, a2 * NoH);
    float d2 = dot(d, d);
    float b2 = PREVENT_DIV0(a2, d2, 0.0000009);
    return a2 * b2 * b2 * (1.0 / PI);
}

float pm_D_Charlie(float NoH, float roughness) {
    // Estevez and Kulla 2017, "Production Friendly Microfacet Sheen BRDF"
    float invAlpha  = 1.0 / roughness;
    float cos2h = NoH * NoH;
    float sin2h = max(1.0 - cos2h, 0.0078125);
    return (2.0 + invAlpha) * pow(sin2h, invAlpha * 0.5) / (2.0 * PI);
}


/* 
    fresnel term impls
 */

float3 pm_F_Schlick(float VoH, float3 f0) {
    float f = pow(1.0 - VoH, 5.0);
    return f + f0 * (1.0 - f);
}

/* 
    visibility term impls
 */

float pm_V_SmithGGXCorrelated(float NoV, float NoL, float a) 
{
    float GGXL = NoV * sqrt((-NoL * a + NoL) * NoL + a);
    float GGXV = NoL * sqrt((-NoV * a + NoV) * NoV + a);
    return 0.5 / (GGXV + GGXL);
}

float pm_V_SmithGGXCorrelated_Anisotropic(float at, float ab, float ToV, float BoV,
        float ToL, float BoL, float NoV, float NoL) {
    // Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
    // TODO: lambdaV can be pre-computed for all the lights, it should be moved out of this function
    float lambdaV = NoL * length(float3(at * ToV, ab * BoV, NoV));
    float lambdaL = NoV * length(float3(at * ToL, ab * BoL, NoL));
    // 0.0000077 = nextafter(0.5 / MEDIUMP_FLT_MAX, 1.0) in fp16, so we don't overflow
    float v = PREVENT_DIV0(0.5, lambdaV + lambdaL, 0.0000077);
    return v;
}

float pm_V_Neubelt(float NoV, float NoL) {
    // Neubelt and Pettineo 2013, "Crafting a Next-gen Material Pipeline for The Order: 1886"
    return PREVENT_DIV0(1.0, 4.0 * (NoL + NoV - NoL * NoV), 0.00001532);
}

/* 
    diffuse brdf impls
 */

float pm_Fd_Lambert() {
    return 1.0 / PI;
}

float pm_Fd_Wrap(float NoL, float w) {
    return saturate((NoL + w) / pow(1.0 + w, 2.0));
}

float pm_Fd_Oren_Nayar(in float NoL, in float LoV, in float NoV, in float Rough, in float3 Albedo)
{
    // Improved Oren-Nayar reflectance-diffuse model
    // https://www.cs.cornell.edu/~srm/publications/EGSR07-btdf.pdf
    // https://dl.acm.org/doi/10.1145/192161.192213
    // https://mimosa-pudica.net/improved-oren-nayar.html
    // conversion of Albedo to approximated luminance via Rec709 https://en.wikipedia.org/wiki/Rec._709
    
    float lumApprox = dot(Albedo, float3(0.2126, 0.7152, 0.0722));
    float s = LoV - NoL * NoV;
    float t = lerp(1.0, max(NoL, NoV), step(0.0, s));

    float A2 = (1.0 / PI) * (1.0 - 0.5 * (Rough / (Rough + 0.33)) + 0.17 * lumApprox * (Rough / (Rough + 0.13)));
    float B2 = (1.0 / PI) * (0.45 * (Rough / (Rough + 0.09)));

    return NoL * (A2 + B2 * s / t);
}

float ComputeSpecularAO(in float NoV, in float ao, in float roughness)
{
    return clamp(pow(abs(NoV + ao), exp2(-16.0 * roughness - 1.0)) - 1.0 + ao, 0.0, 1.0);
}

float3 EvalSubsurfaceIBL(float3 Fd, in pmLightData ld) 
{
    #if defined(_PM_NDF_CHARLIE) && defined(_PM_FT_SUBSURFACE)
        return saturate(_Subsurface + ld.NoV);
    #else
        return 1;
    #endif
}