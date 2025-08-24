float GetDither(inout v2f i)
{
    float2 screenP = i.screenPos.xy / i.screenPos.w;
    float2 ditherCoordinate = screenP * _ScreenParams.xy * _ditherPattern_TexelSize.xy;
    float tex = tex2D(_ditherPattern, ditherCoordinate).r;
    return tex - _DitherBias;
}

float CutoutAlpha(float alpha) {
    return alpha - _AlphaCutoff;
}

float AlphaDither(inout v2f i, float alpha)
{
    float dither = GetDither(i);
    return saturate(alpha - (dither * (1 - alpha) * _DitherAmount));
}

float AlphaBlend(inout v2f i, in float alpha, in float type)
{
    float output = alpha;
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

void ParseInputs(inout v2f i, in bool isFrontFace) 
{
    float4 orm = TEX2D_SAMPLE_SAMPLER(_ORMTexture, sampler_samplerDefault, i.uv0);
    _Occlusion = lerp(1, orm.r, _AOStrength);
    _RoughnessPerceptual = saturate(max(orm.g, 0.045)) * _RoughnessStrength;
    _Metallic = orm.b * _MetallicStrength;

    float4 nm = TEX2D_SAMPLE_SAMPLER(_NormalMap, sampler_samplerDefault, i.uv0);
    _Normal = lerp(float4(0.5, 0.5, 1, 1), ReconstructNormal(nm, _NormalStrength), _NormalStrength);

    float alpha = 1.0;
    if (_pm_nk_hasalpha)
        alpha = TEX2D_SAMPLE_SAMPLER(_AlphaTex, sampler_samplerDefault, i.uv0).r;
    else
        alpha = TEX2D_SAMPLE_SAMPLER(_DiffuseAlpha, sampler_samplerDefault, i.uv0).a;

    #ifdef _PM_FT_SUBSURFACE
        _Thickness = TEX2D_SAMPLE_SAMPLER(_ThicknessTexture, sampler_samplerDefault, i.uv0).r;
    #else
        _Thickness = 1.0;
    #endif
    
    float3 albedo = TEX2D_SAMPLE_SAMPLER(_DiffuseAlpha, sampler_samplerDefault, i.uv0).rgb;
    _Albedo = albedo * _DiffuseHDR.rgb;

    float3 emission = TEX2D_SAMPLE_SAMPLER(_EmissionMask, sampler_samplerDefault, i.uv0).rgb;
    _Emission = emission;

    _Roughness = max(_RoughnessPerceptual * _RoughnessPerceptual, 0.001);
    _NormalWS = TangentToWorld(i, _Normal);

    _Diffuse = _Albedo * (1.0 - _Metallic);
    _Alpha = AlphaBlend(i, alpha, _AlphaMode) * _DiffuseHDR.a;

    _Subsurface = _SubsurfaceColor.rgb * _Diffuse;
}