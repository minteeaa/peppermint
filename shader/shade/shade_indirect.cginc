float3 indirectSpecular(LightingData ld, AnisotropyData ad) {
    float4 dfg = PrepareDFG(ld);
    float3 h = normalize(ld.r + ld.viewDir);
    float LoH = saturate(dot(ld.r, h));

    float3 F = fresnel(LoH, ld.f0);

    float3 E;
    float3 E_ggx = lerp(dfg.x, dfg.y, ld.f0);

    #ifdef _PM_NDF_CHARLIE
        float3 E_charlie = ld.f0 * dfg.z;
        E = lerp(E_charlie, E_ggx, _Metallic);
    #else 
        E = E_ggx;
    #endif

    float3 ind = ld.indirectSpecular * E;
    return F * ind * ComputeSpecularAO(ld.NoV, _Occlusion, _Roughness);
}

float3 indirectDiffuse(LightingData ld, AnisotropyData ad) {
    float3 Fd = float3(0, 0, 0);
    float4 dfg = PrepareDFG(ld);

    float3 E;
    float3 E_ggx = lerp(dfg.x, dfg.y, ld.f0);

    #ifdef _PM_NDF_CHARLIE
        float3 E_charlie = ld.f0 * dfg.z;
        E = lerp(E_charlie, E_ggx, _Metallic);
    #else 
        E = E_ggx;
    #endif

    Fd += _Diffuse * ld.indirectDiffuse * (1.0 - E) * (Fd_Lambert() * _Occlusion);
    return Fd *= EvalSubsurfaceIBL(Fd, ld);
}

void shadeIndirect(inout LightingData ld, AnisotropyData ad) {
    float3 IFr = indirectSpecular(ld, ad);
    float3 IFd = indirectDiffuse(ld, ad);

    float3 color = IFr + IFd;

    ld.surfaceColor += color;
}

void shadeLTCGI(inout v2f i, inout LightingData ld)
{
    GetLTCGI(i, ld);
    ld.surfaceColor += ld.ltcgiDiffuse * _Diffuse;
    ld.surfaceColor += ld.ltcgiSpecular * ld.f0;
}