float3 sampleAPV(in pmInput i, in pmLightData ld)
{
    #if defined(PIPE_URP)
        float3 apvColor = 0;
        APVSample apv = SampleAPV(i.worldPos, _NormalWS, 0xFFFFFFFF, i.viewDir);
        EvaluateAdaptiveProbeVolume(apv, _NormalWS, apvColor);
        return apvColor;
    #endif
}

half3 sampleIndirectDiffuse(in pmInput i, in pmLightData ld) 
{
    // half3 sh = ShadeSH9(half4(_NormalWS.x, _NormalWS.y, _NormalWS.z, 1));
    // return (sh * _Albedo / PI) * _Occlusion;
    half3 diffuseAdd = half3(0, 0, 0);
    #if defined(PIPE_BIRP)
        float3 L0 = float3(0, 0, 0);
        float3 L1r = float3(0, 0, 0);
        float3 L1g = float3(0, 0, 0);
        float3 L1b = float3(0, 0, 0);

        // don't use LightVolumeSHSpecular because we don't need specular here
        LightVolumeSH(i.worldPos, L0, L1r, L1g, L1b, 0, _NormalWS, 3);
        diffuseAdd = EvaluateSH1(_NormalWS, L0, L1r, L1g, L1b);
    #elif defined(PIPE_URP)
        diffuseAdd = SampleSH(_NormalWS);
    #endif

    return diffuseAdd;
}

half3 sampleIndirectSpecular(in pmInput i, in pmLightData ld, in pmAnisotropyData ad)
{
    half3 specularAdd = half3(0, 0, 0);
    half3 r = ld.r;
    #if defined(PIPE_BIRP)
        half4 envReflection = 0;
        float3 lvSpecular = float3(0, 0, 0);
        float3 L0 = float3(0, 0, 0);
        float3 L1r = float3(0, 0, 0);
        float3 L1g = float3(0, 0, 0);
        float3 L1b = float3(0, 0, 0);

        half mip = _Roughness * UNITY_SPECCUBE_LOD_STEPS;
        #ifdef _PM_FT_ANISOTROPICS
            r = lerp(ld.r, ad.r, _AnisotropicsStrength);
        #endif
        envReflection = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, r, mip);
        specularAdd += DecodeHDR(envReflection, unity_SpecCube0_HDR);
        
        LightVolumeSHSpecular(i.worldPos, L0, L1r, L1g, L1b, lvSpecular, ld.f0, 1 - _Roughness, _NormalWS, ld.viewDir, 0, 3);
        specularAdd += lvSpecular;
    #elif defined(PIPE_URP)
        #ifdef _PM_FT_ANISOTROPICS
            r = lerp(ld.r, ad.r, _AnisotropicsStrength);
        #endif 
        specularAdd = GlossyEnvironmentReflection(normalize(r), i.worldPos, _Roughness, 1, i.screenPosUV);
    #endif

    return specularAdd;
}

void prepareIndirect(in pmInput i, inout pmLightData ld, in pmAnisotropyData ad)
{
    #if defined(PROBE_VOLUMES_L1) || defined(PROBE_VOLUMES_L2)
        ld.indirectDiffuse += sampleAPV(i, ld);
    #else
        ld.indirectDiffuse += sampleIndirectDiffuse(i, ld);
    #endif
    ld.indirectSpecular += sampleIndirectSpecular(i, ld, ad);
}

half3 shadeIndirectSpecular(in pmLightData ld) {
    half3 h = uSafeNormalize(ld.r + ld.viewDir);
    half LoH = saturate(dot(ld.r, h));
    half3 F = fresnel(LoH, ld.f0);
    
    half3 E = half3(0, 0, 0);
    half3 EGGX = lerp(ld.dfg.x, ld.dfg.y, ld.f0);
    #ifdef _PM_NDF_CHARLIE
        half3 ECharlie = ld.f0 * ld.dfg.z;
        E = lerp(ECharlie, EGGX, _Metallic);
    #else 
        E = EGGX;
    #endif

    half3 Fr = ld.indirectSpecular * E;
    return F * Fr * ComputeSpecularAO(ld.NoV, _Occlusion, _Roughness);
}

half3 shadeIndirectDiffuse(in pmLightData ld) {
    half3 E = half3(0, 0, 0);
    half3 EGGX = lerp(ld.dfg.x, ld.dfg.y, ld.f0);
    #ifdef _PM_NDF_CHARLIE
        half3 ECharlie = ld.f0 * ld.dfg.z;
        E = lerp(ECharlie, EGGX, _Metallic);
    #else 
        E = EGGX;
    #endif

    half3 Fd = 0;
    Fd += _Diffuse * ld.indirectDiffuse * (1.0 - E) * (pm_Fd_Lambert() * _Occlusion);
    return Fd *= EvalSubsurfaceIBL(Fd, ld);
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