#if defined(PIPE_BIRP)
    half4 frag (v2f i, bool isFrontFace : SV_IsFrontFace) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
        initDefaultSampler(samplerDefault);

        half3 color = 0;
        pmInput input = inputAdapt(i);
        prepareSurface(input, isFrontFace);
        sampleProperties(input);

        pmLightData ld = prepareLightData(input);
        pmAnisotropyData ad = prepareAnisotropyData(ld, input);
        pmVertexLightData vld = prepareVertexLightData(input, ld);
        
        prepareIndirect(input, ld, ad);
        prepareDirect(ld, ad);

        color += shadeDirectDiffuse(ld);
        color += shadeDirectSpecular(ld);
        color += shadeIndirectSpecular(ld);
        color += shadeIndirectDiffuse(ld);
        color += shadeVertexDiffuse(vld, ld, input);
        color += shadeVertexSpecular(vld, ld, ad, input);
            
        #if defined(_PM_FT_LTCGI)
            color += addLTCGI(input, ld);
        #endif

        #if defined(_PM_FT_EMISSIONS)
            color += addEmission(ld);
        #endif

        half4 col = half4(0, 0, 0, 0);

        #if defined(_PM_DEBUG)
            [branch]
            if (_DebugMode == 0) col = half4(shadeDirectDiffuse(ld), _Alpha);
            else if (_DebugMode == 1) col = half4(shadeDirectSpecular(ld), _Alpha);
            else if (_DebugMode == 2) col = half4(ld.indirectDiffuse, _Alpha);
            else if (_DebugMode == 3) col = half4(ld.indirectSpecular, _Alpha);
            else if (_DebugMode == 4) col = half4(ld.lvSpecular, _Alpha);
        #else
            col = half4(color, _Alpha);
        #endif
        col.r += samplerDefault.r;

        UNITY_APPLY_FOG(i.fogCoord, col);
        return col;
    }
#elif defined(PIPE_URP)
    half4 frag(Varyings i, bool isFrontFace: SV_IsFrontFace) : SV_Target
    {
        half3 color = 0;
        pmInput input = inputAdapt(i);
        prepareSurface(input, isFrontFace);
        sampleProperties(input);

        pmLightData ld = prepareLightData(input);
        pmAnisotropyData ad = prepareAnisotropyData(ld, input);

        prepareIndirect(input, ld, ad);
        prepareDirect(ld, ad);

        color += shadeDirectDiffuse(ld);
        color += shadeDirectSpecular(ld);
        color += shadeIndirectSpecular(ld);
        color += shadeIndirectDiffuse(ld);

        #if defined(_PM_FT_EMISSIONS)
            color += addEmission(ld);
        #endif

        return half4(color, _Alpha);
    }
#endif