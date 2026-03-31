pmInput inputAdapt(Varyings i)
{
    pmInput o = (pmInput)0;
    
    o.vertex = i.positionHCS;
    o.normal = TransformObjectToWorldNormal(i.normal);
    o.tangent.xyz = GetVertexNormalInputs(i.tangent.xyz).tangentWS.xyz;
    o.tangent.w = i.tangent.w;
    o.worldPos = i.worldPos;
    o.screenPos = i.screenPos;
    o.uv0 = i.uv0;
    o.uv1 = i.uv1;
    o.uv2 = i.uv2;
    o.uv3 = i.uv3;

    half2 screenPos = o.screenPos.xy / o.screenPos.w;
    #if UNITY_UV_STARTS_AT_TOP
        screenPos.y = 1.0 - screenPos.y;
    #endif
    o.screenPosUV = screenPos;

    return o;
}