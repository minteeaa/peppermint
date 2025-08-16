float4 frag (v2f i, bool isFrontFace : SV_IsFrontFace) : SV_Target
{
    InitializeDefaultSampler(samplerDefault);
    ParseInputs(i, isFrontFace);

    return 0;
}