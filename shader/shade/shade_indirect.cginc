float3 sampleAPV(in pmInput i, in pmLightData ld)
{
    #if defined(PIPE_URP)
        float3 apvColor = 0;
        APVSample apv = SampleAPV(i.worldPos, _NormalWS, 0xFFFFFFFF, i.viewDir);
        EvaluateAdaptiveProbeVolume(apv, _NormalWS, apvColor);
        return apvColor;
    #endif
}

void prepareSH(in pmInput i, inout pmLightData ld, out float3 L0, out float3 L1r, out float3 L1g, out float3 L1b) {
    L0 = 0; L1r = 0; L1g = 0; L1b = 0;
    float3 specular = 0;
    [branch] 
    if (!LightVolumesEnabled()) {
        LV_SampleLightProbe(L0, L1r, L1g, L1b);
    } else {
        LV_LightVolumeRegularSH(i.worldPos + 0, L0, L1r, L1g, L1b);
        LV_LightVolumeAdditiveSH(i.worldPos + 0, L0, L1r, L1g, L1b);
        LV_PointLightVolumeSHSpecular(i.worldPos, _NormalWS, i.viewDir, 1 - _perceptualRoughness, ld.f0, 3, L0, L1r, L1g, L1b, specular);
    }
    ld.lvSpecular = specular;
}

half3 sampleIndirectDiffuse(in pmInput i, in pmLightData ld,
    float3 L0, float3 L1r, float3 L1g, float3 L1b) 
{
    // half3 sh = ShadeSH9(half4(_NormalWS.x, _NormalWS.y, _NormalWS.z, 1));
    // return (sh * _Albedo / PI) * _Occlusion;
    half3 diffuseAdd = half3(0, 0, 0);
    #if defined(PIPE_BIRP)
        diffuseAdd = EvaluateSH1(_NormalWS, L0, L1r, L1g, L1b);
    #elif defined(PIPE_URP)
        diffuseAdd = SampleSH(_NormalWS);
    #endif

    return diffuseAdd;
}

float computeSpecularAO(in float NoV, in float ao, in float roughness)
{
    return clamp(pow(abs(NoV + ao), exp2(-16.0 * roughness - 1.0)) - 1.0 + ao, 0.0, 1.0);
}

half3 sampleEnvironmentIBL(in pmInput i, in pmLightData ld, in pmAnisotropyData ad, half roughness)
{
    // Filament spec, 5.3.4.4: lod = roughness^(1/2) = perceptualRoughness
    // most or all IBL / indirect specular samples should use `perceptualRoughness` over
    // squared `roughness` to make full use of the mip/lod levels

    half3 specularAdd = half3(0, 0, 0);
    half3 r = ld.r;
    #if defined(PIPE_BIRP)
        half4 envReflection = 0;
        half mip = roughness * UNITY_SPECCUBE_LOD_STEPS;

        #ifdef _PM_FT_ANISOTROPICS
            r = lerp(ld.r, ad.r, _AnisotropicsStrength);
        #endif
        envReflection = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, r, mip);
        specularAdd += DecodeHDR(envReflection, unity_SpecCube0_HDR);
    #elif defined(PIPE_URP)
        #ifdef _PM_FT_ANISOTROPICS
            r = lerp(ld.r, ad.r, _AnisotropicsStrength);
        #endif 
        specularAdd = GlossyEnvironmentReflection(normalize(r), i.worldPos, roughness, 1, i.screenPosUV);
    #endif

    return specularAdd;
}

void evaluateSubsurfaceIBL(inout float3 Fd, in pmLightData ld) 
{
    #if defined(_PM_NDF_CHARLIE) && defined(_PM_FT_SUBSURFACE)
        Fd *= saturate(_Subsurface + ld.NoV);
    #endif
}

void evaluateSheenIBL(inout half3 Fr, inout half3 Fd, in pmInput i, in pmLightData ld, in pmAnisotropyData ad) 
{
    #if !defined(_PM_NDF_CHARLIE) && !defined(_PM_FT_SUBSURFACE)
        #if defined(_PM_FT_SHEEN)
            Fr *= ld.sheenScaling;
            Fd *= ld.sheenScaling;

            half3 reflectance = ld.sheenDFG * _SheenColor;
            reflectance *= computeSpecularAO(ld.NoV, _Occlusion, ld.sheenRoughness);
            Fr += reflectance * sampleEnvironmentIBL(i, ld, ad, ld.sheenPerceptualRoughness);
        #endif
    #endif
}

void prepareIndirect(in pmInput i, inout pmLightData ld, in pmAnisotropyData ad)
{
    float3 L0, L1r, L1g, L1b = float3(0, 0, 0);
    prepareSH(i, ld, L0, L1r, L1g, L1b);

    #if defined(PROBE_VOLUMES_L1) || defined(PROBE_VOLUMES_L2)
        ld.indirectDiffuse += sampleAPV(i, ld);
    #else
        ld.indirectDiffuse += sampleIndirectDiffuse(i, ld, L0, L1r, L1g, L1b);
    #endif
}

half3 shadeIndirect(in pmInput i, in pmLightData ld, in pmAnisotropyData ad) {
    half3 Fr, Fd = half3(0, 0, 0);
    half3 ggx = lerp(ld.dfg.x, ld.dfg.y, ld.f0);
    #ifdef _PM_NDF_CHARLIE
        half3 cloth = ld.f0 * ld.dfg.z;
        half3 E = lerp(cloth, ggx, _Metallic);
    #else 
        half3 E = ggx;
    #endif

    half3 diffuseAO = computeSpecularAO(ld.NoV, _Occlusion, _Roughness);

    Fr = E * sampleEnvironmentIBL(i, ld, ad, _perceptualRoughness);
    Fd = _Diffuse * ld.indirectDiffuse * (1.0 - E) * (pm_Fd_Lambert() * diffuseAO);

    evaluateSubsurfaceIBL(Fd, ld);
    evaluateSheenIBL(Fr, Fd, i, ld, ad);

    Fr += ld.lvSpecular;

    return Fr + Fd;
}

half3 addLTCGI(in pmInput i, in pmLightData ld)
{
    #ifdef _PM_FT_LTCGI
        accumulator_struct acc = GetLTCGI(i, ld);
        half3 color = 0;
        color += acc.diffuse * _Diffuse;
        color += acc.specular * ld.f0;
        return color;
    #endif
}