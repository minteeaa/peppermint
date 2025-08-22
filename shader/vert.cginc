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
    #if defined(PASS_BASE)
        o.useVertexLights = false;
        #if defined(VERTEXLIGHT_ON)
            o.useVertexLights = true;
        #endif
    #endif
    return o;
}