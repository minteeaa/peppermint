pmInput inputAdapt(v2f i)
{
    pmInput o = (pmInput)0;

    o.vertex = i.vertex;
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

    return o;
}