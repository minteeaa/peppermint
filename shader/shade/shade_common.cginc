float diffuse(float NoL, float LoV, float NoV, float roughness, float3 diffuse) {
    return Fd_Oren_Nayar(NoL, LoV, NoV, roughness, diffuse);
}

float distribution(float NoH, float roughness) {
    return D_GGX2(NoH, roughness);
}

float visibility(float NoV, float NoL, float roughness) {
    return V_SmithGGXCorrelated(NoV, NoL, roughness);
}

float3 fresnel(float LoH, float f0) {
    return F_Schlick(LoH, f0);
}

float distributionAnisotropic(float at, float ab, float ToH, float BoH, float NoH) {
    return D_GGX_Anisotropic(at, ab, ToH, BoH, NoH);
}

float visibilityAnisotropic(float at, float ab, float ToV, float BoV, float ToL, float BoL, float NoV, float NoL) {
    return V_SmithGGXCorrelated_Anisotropic(at, ab, ToV, BoV, ToL, BoL, NoV, NoL);
}

float distributionCloth(float NoH, float roughness) {
    return D_Charlie(NoH, roughness);
}

float visibilityCloth(float NoV, float NoL) {
    return V_Neubelt(NoV, NoL);
}

float3 isotropic(float NoH, float NoV, float LoH, float NoL, float f0, float roughness) {
    float D = distribution(NoH, roughness);
    float V = visibility(NoV, NoL, roughness);
    float3 F = fresnel(LoH, f0);

    float3 Fr = (D * V) * F;

    // blame vrchat and bloom usage
    if (_ClampSpecular) 
    {
        Fr = Fr / (1.0 + Fr);
    }

    return Fr;
}

float3 anisotropic(float3 h, float3 viewDir, float3 lightDir, float3 t, float3 b, float NoV, float NoH, float NoL, float LoH, float f0, float roughness) {
    #ifdef _PM_FT_ANISOTROPICS
        float at = max(roughness * (1.0 + _AnisotropicsStrength), 0.04);
        float ab = max(roughness * (1.0 - _AnisotropicsStrength), 0.04);

        float ToV = dot(t, viewDir);
        float BoV = dot(b, viewDir);
        float ToL = dot(t, lightDir);
        float BoL = dot(b, lightDir);
        float ToH = dot(t, h);
        float BoH = dot(b, h);

        float D = distributionAnisotropic(at, ab, ToH, BoH, NoH);
        float V = visibilityAnisotropic(at, ab, ToV, BoV, ToL, BoL, NoV, NoL);
        float F = fresnel(LoH, f0);
        return (D * V) * F;
    #endif
}

float isotropicCloth(float NoH, float NoV, float NoL, float roughness, float f0) {
    float D = distributionCloth(NoH, roughness);
    float V = visibilityCloth(NoV, NoL);
    float3 F = f0;
    return (D * V) * F;
}