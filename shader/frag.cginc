#if defined(PIPE_BIRP)
    half4 frag (v2f i, bool isFrontFace : SV_IsFrontFace) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
        InitializeDefaultSampler(samplerDefault);

        half3 color = 0;
        pmInput input = inputAdapt(i);
        prepareSurface(input, isFrontFace);
        sampleProperties(input);

        pmLightData ld = prepareLightData(input);
        pmAnisotropyData ad = prepareAnisotropyData(ld, input);
        VertexLightingData vld = (VertexLightingData)0;
        
        prepareIndirect(input, ld, ad);
        prepareDirect(ld, ad);

        color += shadeDirectDiffuse(ld);
        color += shadeDirectSpecular(ld);
        color += shadeIndirectSpecular(ld);
        color += shadeIndirectDiffuse(ld);
            
        #if defined(LTCGI_INCLUDED)
            shadeLTCGI(input, ld);
        #endif
        #if defined(_PM_FT_EMISSIONS)
            addEmission(ld);
        #endif

        float4 col = half4(color, _Alpha);
        col.r += samplerDefault.r;

        //UNITY_APPLY_FOG(i.fogCoord, col);
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