#if defined(PIPE_BIRP)
    v2f vert (appdata v)
    {
        v2f o = (v2f)0;
        
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_INITIALIZE_OUTPUT(v2f, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

        o.vertex = UnityObjectToClipPos(v.vertex);
        o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
        o.normal = UnityObjectToWorldNormal(v.normal);
        o.tangent.xyz = UnityObjectToWorldDir(v.tangent.xyz);
        o.tangent.w = v.tangent.w;
        o.color = v.color;
        o.localPos = v.vertex;
        o.screenPos = ComputeScreenPos(o.vertex);
        o.uv0 = v.uv0;
        o.uv1 = v.uv1;
        o.uv2 = v.uv2;
        o.uv3 = v.uv3;

        // method from Poiyomi's udim discard

        #ifdef _PM_FT_UVTILEDISCARD
            float2 udim = 0;

            udim += (v.uv0.xy * (_UDIMDiscardUV == 0));
            udim += (v.uv1.xy * (_UDIMDiscardUV == 1));
            udim += (v.uv2.xy * (_UDIMDiscardUV == 2));
            udim += (v.uv3.xy * (_UDIMDiscardUV == 3));
        
            float4 UDIMDiscardRows[4];
            UDIMDiscardRows[0] = float4(_UDIMDiscardRow0_0, _UDIMDiscardRow0_1, _UDIMDiscardRow0_2, _UDIMDiscardRow0_3);
            UDIMDiscardRows[1] = float4(_UDIMDiscardRow1_0, _UDIMDiscardRow1_1, _UDIMDiscardRow1_2, _UDIMDiscardRow1_3);
            UDIMDiscardRows[2] = float4(_UDIMDiscardRow2_0, _UDIMDiscardRow2_1, _UDIMDiscardRow2_2, _UDIMDiscardRow2_3);
            UDIMDiscardRows[3] = float4(_UDIMDiscardRow3_0, _UDIMDiscardRow3_1, _UDIMDiscardRow3_2, _UDIMDiscardRow3_3);
        
            float shouldDiscard = SetDiscard(udim, UDIMDiscardRows);
        
            if(shouldDiscard < 0)
            {
                return (v2f)P_NAN;
            }
        #endif

        #if defined(PASS_BASE)
            o.useVertexLights = false;
            #if defined(VERTEXLIGHT_ON)
                o.useVertexLights = true;
            #endif
        #endif

        //UNITY_TRANSFER_FOG(o, o.vertex);
        return o;
    }
#elif defined(PIPE_URP)
    Varyings vert(Attributes i)
    {
        Varyings o = (Varyings)0;

        o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
        o.worldPos = GetVertexPositionInputs(i.positionOS.xyz).positionWS;
        o.normal = i.normal;
        o.tangent = i.tangent;
        o.screenPos = ComputeScreenPos(o.positionHCS);
        o.uv0 = i.uv0;
        o.uv1 = i.uv1;
        o.uv2 = i.uv2;
        o.uv3 = i.uv3;

        // todo: port udim tile toggles from birp
        
        return o;
    }
#endif