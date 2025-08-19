float4 frag (v2f i, bool isFrontFace : SV_IsFrontFace) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
    InitializeDefaultSampler(samplerDefault);
    ParseInputs(i, isFrontFace);
    InitMiscData(i);
    LightingData ld = (LightingData)0;
    VertexLightingData vld = (VertexLightingData)0;
    InitLightingData(i, ld, vld);
    ApplyLTCGI(i, ld);
    ApplyLighting(ld, vld, i);
    ApplyEmission(ld);

    float4 col = float4(ld.surfaceColor.x, ld.surfaceColor.y, ld.surfaceColor.z, _Alpha);

    col.r += samplerDefault.r;
    return col;
}