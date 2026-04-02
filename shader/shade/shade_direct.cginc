half3 sampleDirectSpecular(pmLightData ld, pmAnisotropyData ad)
{
    half3 Fr = 0;
    #ifdef _PM_NDF_GGX
        #ifdef _PM_FT_ANISOTROPICS
            Fr = anisotropic(ld.h, ld.viewDir, ld.lightDir, ad.t, ad.b, ld.NoV, ld.NoH, ld.NoL, ld.LoH, ld.f0, _Roughness) * ld.energyCompensation;
        #else
            Fr = isotropic(ld.NoH, ld.NoV, ld.LoH, ld.NoL, ld.f0, _Roughness) * ld.energyCompensation;
        #endif
    #endif
    #ifdef _PM_NDF_CHARLIE
        half3 isoCloth = isotropicCloth(ld.NoH, ld.NoV, ld.NoL, _Roughness, ld.f0);
        half3 iso = isotropic(ld.NoH, ld.NoV, ld.LoH, ld.NoL, ld.f0, _Roughness) * ld.energyCompensation;
        Fr = lerp(isoCloth, iso, _Metallic);
    #endif

    if (_ClampSpecular) 
        Fr = Fr / (1.0 + Fr);

    return Fr;
}

half3 sampleVertexSpecular(pmVertexLightData vld, pmLightData ld, pmAnisotropyData ad, int index) {
    half3 vFr = 0;
    #ifdef _PM_NDF_GGX
        #ifdef _PM_FT_ANISOTROPICS
            vFr = anisotropic(vld.h[index], ld.viewDir, vld.lightDir[index], ad.t, ad.b, ld.NoV, vld.NoH[index], vld.NoL[index], vld.LoH[index], ld.f0, _Roughness) * ld.energyCompensation;
        #else
            vFr = isotropic(vld.NoH[index], ld.NoV, vld.LoH[index], vld.NoL[index], ld.f0, _Roughness) * ld.energyCompensation;
        #endif
    #endif
    #ifdef _PM_NDF_CHARLIE
        half3 vIsoCloth = isotropicCloth(vld.NoH[index], ld.NoV, vld.NoL[index], _Roughness, ld.f0);
        half3 vIso = isotropic(vld.NoH[index], ld.NoV, vld.LoH[index], vld.NoL[index], ld.f0, _Roughness) * ld.energyCompensation;
        vFr = lerp(vIsoCloth, vIso, _Metallic);
    #endif

    if (_ClampSpecular) 
        vFr = vFr / (1.0 + vFr);

    return vFr;
}

half3 sampleDirectDiffuse(in pmLightData ld) {
    half Fd = diffuse(ld.NoL, ld.LoV, ld.NoV, _Roughness, _Diffuse);
    #if defined(_PM_NDF_CHARLIE) && defined(_PM_FT_SUBSURFACE)
        Fd *= pm_Fd_Wrap(dot(_NormalWS, ld.lightDir), 0.5);
    #endif
    return _Diffuse * Fd;
}

float3 sampleVertexDiffuse(pmVertexLightData vld, pmLightData ld, int index)
{
    half LoV = clamp(dot(vld.lightDir[index], ld.viewDir), 0.0, 1.0);
    half3 vFd = diffuse(vld.NoL[index], LoV, ld.NoV, _Roughness, _Diffuse);

    #if defined(_PM_NDF_CHARLIE) && defined(_PM_FT_SUBSURFACE)
        vFd *=pm_Fd_Wrap(dot(_NormalWS, vld.lightDir[index]), 0.5);
    #endif

    return _Diffuse * vFd;
}

void prepareDirect(inout pmLightData ld, in pmAnisotropyData ad)
{
    ld.directDiffuse += sampleDirectDiffuse(ld);
    ld.directSpecular += sampleDirectSpecular(ld, ad);
}

half3 shadeDirectDiffuse(in pmLightData ld)
{
    if (ld.NoL <= 0) return 0;

    half3 color = ld.directDiffuse;
    #if defined(_PM_NDF_CHARLIE) && defined(_PM_FT_SUBSURFACE)
        color *= saturate(_Subsurface + ld.NoL);
        color *= ld.mainLightColor * ld.mainLightAttenuation;
    #else
        color *= ld.mainLightColor * ld.mainLightAttenuation * ld.NoL;
    #endif
    return color;
}

half3 shadeVertexDiffuse(in pmVertexLightData vld, in pmLightData ld, in pmInput i)
{
    #if defined(PASS_BASE)
        if (!i.useVertexLights) return 0;

        half3 vertexDiffuse = 0;
        for (int index = 0; index < 4; index++) {
            if (vld.NoL[index] > 0) {
                half3 color = sampleVertexDiffuse(vld, ld, index);
                #if defined(_PM_NDF_CHARLIE) && defined(_PM_FT_SUBSURFACE)
                    color *= saturate(_Subsurface + vld.NoL[index]);
                    color *= vld.color[index] * vld.attenuation[index];
                #else
                    color *= vld.color[index] * vld.attenuation[index] * vld.NoL[index];
                #endif
                vertexDiffuse += color;
            }
        }
        return vertexDiffuse;
    #else
        return 0;
    #endif
}

half3 shadeDirectSpecular(in pmLightData ld)
{
    if (ld.NoL <= 0) return 0;

    half3 color = ld.directSpecular;
    color *= ld.mainLightColor * ld.mainLightAttenuation * ld.NoL;
    return color;
}

half3 shadeVertexSpecular(in pmVertexLightData vld, in pmLightData ld, in pmAnisotropyData ad, in pmInput i)
{
    #if defined(PASS_BASE)
        if (!i.useVertexLights) return 0;

        half3 vertexSpecular = 0;
        for (int index = 0; index < 4; index++) {
            if (vld.NoL[index] > 0) {
                half3 color = sampleVertexSpecular(vld, ld, ad, index);
                color *= vld.color[index] * vld.attenuation[index] * vld.NoL[index];
                vertexSpecular += color;
            }
        }
        return vertexSpecular;
    #else
        return 0;
    #endif
}