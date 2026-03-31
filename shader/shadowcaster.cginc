#if defined(PIPE_BIRP)
    float4 frag (v2f i, bool isFrontFace : SV_IsFrontFace) : SV_Target
    {
        InitializeDefaultSampler(samplerDefault);
        pmInput input = inputAdapt(i);
        prepareSurface(input, isFrontFace);
        sampleProperties(input);

        return samplerDefault;
    }
#endif
// todo: shadowcaster for urp