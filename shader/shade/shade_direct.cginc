float3 specularLobe(LightingData ld, AnisotropyData ad) {
    float3 Fr = 0;
    #ifdef _PM_NDF_GGX
        #ifdef _PM_FT_ANISOTROPICS
            Fr = anisotropic(ld.h, ld.viewDir, ld.lightDir, ad.t, ad.b, ld.NoV, ld.NoH, ld.NoL, ld.LoH, ld.f0, _Roughness);
        #else
            Fr = isotropic(ld.NoH, ld.NoV, ld.LoH, ld.NoL, ld.f0, _Roughness);
        #endif
    #endif
    #ifdef _PM_NDF_CHARLIE
        float3 isoCloth = isotropicCloth(ld.NoH, ld.NoV, ld.NoL, _Roughness, ld.f0);
        float3 iso = isotropic(ld.NoH, ld.NoV, ld.LoH, ld.NoL, ld.f0, _Roughness);
        Fr = lerp(isoCloth, iso, _Metallic);
    #endif

    if (_ClampSpecular) 
    {
        Fr = Fr / (1.0 + Fr);
    }

    return Fr;
}

float3 vertexSpecularLobe(VertexLightingData vld, LightingData ld, AnisotropyData ad, int index) {
    float3 vFr = 0;
    #ifdef _PM_NDF_GGX
        #ifdef _PM_FT_ANISOTROPICS
            vFr = anisotropic(vld.h[index], ld.viewDir, vld.lightDir[index], ad.t, ad.b, ld.NoV, vld.NoH[index], vld.NoL[index], vld.LoH[index], ld.f0, _Roughness);
        #else
            vFr = isotropic(vld.NoH[index], ld.NoV, vld.LoH[index], vld.NoL[index], ld.f0, _Roughness);
        #endif
    #endif
    #ifdef _PM_NDF_CHARLIE
        float3 vIsoCloth = isotropicCloth(vld.NoH[index], ld.NoV, vld.NoL[index], _Roughness, ld.f0);
        float3 vIso = isotropic(vld.NoH[index], ld.NoV, vld.LoH[index], vld.NoL[index], ld.f0, _Roughness);
        vFr = lerp(vIsoCloth, vIso, _Metallic);
    #endif

    if (_ClampSpecular) 
    {
        vFr = vFr / (1.0 + vFr);
    }

    return vFr;
}

float3 diffuseLobe(LightingData ld) {
    float Fd = diffuse(ld.NoL, ld.LoV, ld.NoV, _Roughness, _Diffuse);
    #if defined(_PM_NDF_CHARLIE) && defined(_PM_FT_SUBSURFACE)
        Fd *= Fd_Wrap(dot(_NormalWS, ld.lightDir), 0.5);
    #endif
    return _Diffuse * Fd;
}

float3 vertexDiffuseLobe(VertexLightingData vld, LightingData ld, int index)
{
    float LoV = clamp(dot(vld.lightDir[index], ld.viewDir), 0.0, 1.0);
    float3 vFd = diffuse(vld.NoL[index], LoV, ld.NoV, _Roughness, _Diffuse);

    #if defined(_PM_NDF_CHARLIE) && defined(_PM_FT_SUBSURFACE)
        vFd *= Fd_Wrap(dot(_NormalWS, vld.lightDir[index]), 0.5);
    #endif

    return _Diffuse * vFd;
}

void shadeDirect(inout LightingData ld, inout AnisotropyData ad) {
    PrepareEnergyCompensation(ld);

    if (ld.NoL > 0) 
    {
        float3 Fr = specularLobe(ld, ad);
        float3 Fd = diffuseLobe(ld);
        float3 color = 0;

        #ifdef _PM_NDF_CHARLIE
            #ifdef _PM_FT_SUBSURFACE
                // simulated non-physically based subsurface scattering for cloth materials
                Fd *= saturate(_Subsurface + ld.NoL);
                color = Fd + Fr * ld.NoL;
                color *= ld.mainLightColor * ld.mainLightAttenuation;
            #else 
                color = Fd + Fr;
                color *= ld.mainLightColor * ld.mainLightAttenuation * ld.NoL;
            #endif
        #else 
            color = Fd + Fr * ld.energyCompensation;
            color *= ld.mainLightColor * ld.mainLightAttenuation * ld.NoL;
        #endif

        ld.surfaceColor += color;
    }
}

void shadeVertex(inout VertexLightingData vld, inout LightingData ld, inout AnisotropyData ad, in v2f i) {
    #if defined(PASS_BASE)
        if (i.useVertexLights) {
            float3 vertLighting = 0;
            for (int index = 0; index < 4; index++) {
                if (vld.NoL[index] > 0) {
                float3 vFl = 0;
                float3 vFd = vertexDiffuseLobe(vld, ld, index);
                float3 vFr = vertexSpecularLobe(vld, ld, ad, index);
                #ifdef _PM_NDF_CHARLIE
                    #ifdef _PM_FT_SUBSURFACE
                        vFd *= saturate(_Subsurface + vld.NoL[index]);
                        vFl = vFd + vFr * vld.NoL[index];
                        vFl *= vld.color[index] * vld.attenuation[index];
                    #else
                        vFl = vFd + vFr;
                        vFl *= vld.color[index] * vld.attenuation[index] * vld.NoL[index];
                    #endif
                #else
                    vFl = vFd + vFr;
                    vFl *= vld.color[index] * vld.attenuation[index] * vld.NoL[index];
                #endif
                vertLighting += vFl;
                }
            }
            ld.surfaceColor += vertLighting;
        }
    #endif
}