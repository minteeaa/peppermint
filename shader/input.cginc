half GetDither(inout pmInput i)
{
    half2 screenP = i.screenPos.xy / i.screenPos.w;
    half2 ditherCoordinate = screenP * _ScreenParams.xy * _ditherPattern_TexelSize.xy;
    half tex = TEX2D_SAMPLE_SAMPLER(_ditherPattern, sampler_ditherPattern, ditherCoordinate).r;
    return tex - _DitherBias;
}

half CutoutAlpha(half alpha) {
    return alpha - _Cutoff;
}

half AlphaDither(inout pmInput i, half alpha)
{
    half dither = GetDither(i);
    return saturate(alpha - (dither * (1 - alpha) * _DitherAmount));
}

half AlphaBlend(inout pmInput i, in half alpha, in half type)
{
    half output = alpha;
    switch (type)
    {
        case 0: output = 1; break;
        case 1: 
            if (_EnableAlphaDither) output = AlphaDither(i, alpha); 
            clip(CutoutAlpha(output));
            output = 1;
            break;
        case 2: output = alpha; break;
        default: output = 0; break;
    }
    return output;
}

void sampleProperties(in pmInput i) 
{
    half3 sampledORM = TEX2D_SAMPLE_SAMPLER(_ORMTexture, sampler_samplerDefault, i.uv0).rgb;
    half4 sampledBumpMap = TEX2D_SAMPLE_SAMPLER(_BumpMap, sampler_samplerDefault, i.uv0);
    half4 sampledMainTex = TEX2D_SAMPLE_SAMPLER(_MainTex, sampler_samplerDefault, i.uv0);

    _Occlusion = lerp(1, sampledORM.r, _AOStrength);
    _RoughnessPerceptual = saturate(max(sampledORM.g, 0.001)) * max(_RoughnessStrength, 0.001);
    _Metallic = sampledORM.b * _MetallicStrength;
    _Normal = ReconstructNormal(sampledBumpMap, _NormalStrength);

    half alpha = 1.0;
    if (_pm_nk_hasalpha)
        alpha = TEX2D_SAMPLE_SAMPLER(_AlphaTex, sampler_samplerDefault, i.uv0).r;
    else
        alpha = sampledMainTex.a;

    #ifdef _PM_FT_SUBSURFACE
        _Subsurface = _SubsurfaceColor.rgb;
    #endif

    #ifdef _PM_FT_EMISSIONS
        _Emission = TEX2D_SAMPLE_SAMPLER(_EmissionMap, sampler_samplerDefault, i.uv0).rgb;
    #endif
    
    _Albedo = (sampledMainTex.rgb * _DiffuseHDR.rgb) * _DiffuseHDR.a;
    _Roughness = _RoughnessPerceptual * _RoughnessPerceptual;
    _NormalWS = tangentToWorld(i, _Normal);
    _Diffuse = _Albedo * (1.0 - _Metallic);
    _Alpha = AlphaBlend(i, alpha, _AlphaMode) * _DiffuseHDR.a;
}