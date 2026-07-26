pmInput inputAdapt(v2f i)
{
    pmInput o = (pmInput)0;

    o.vertex = i.pos;
    o.normal = i.normal;
    o.tangent.xyz = i.tangent.xyz;
    o.tangent.w = i.tangent.w;
    o.worldPos = i.worldPos;
    o.screenPos = i.screenPos;
    o.uv0 = i.uv0;
    o.uv1 = i.uv1;
    o.uv2 = i.uv2;
    o.uv3 = i.uv3;
    o.useVertexLights = i.useVertexLights;

    #if !defined(PASS_SHDW)
        #if defined(PASS_BASE)
            float attenuation = SHADOW_ATTENUATION(i);
        #elif defined(PASS_ADD)
            UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
        #endif
        o.attenuation = attenuation;
    #endif 

    return o;
}