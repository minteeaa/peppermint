// derived from filament/shaders/src/common_math.glsl
#define PREVENT_DIV0(n, d, magic)   ((n) / max(d, magic))

void InitializeDefaultSampler(out float4 defaultSampler) 
{
    defaultSampler = TEX2D_SAMPLE_SAMPLER(_samplerDefault, sampler_samplerDefault, 0) * EPSILON;
}

void FlipNormals(inout v2f i, in bool isFrontFace)
{
    i.normal = normalize(i.normal);
    if (!isFrontFace && _FlipBackfaceNormals == 1) 
    {
        i.normal = -i.normal;
    }
}

float3 TangentToWorld(inout v2f i, in float3 input)
{
    // this function assumes vertex normals and tangents are provided *in worldspace already*
    // which they should be, from the vertex shader; this is at its core a mini, inline TBN
    float3 worldNormal = 
        normalize(
                ((input.x * i.tangent.xyz) + 
                (input.z * i.normal.xyz)) + 
                (i.tangent.w * cross(i.normal.xyz, i.tangent.xyz) * input.y)
                );
    return worldNormal;
}

void InitAnisotropyData(inout AnisotropyData ad, in LightingData ld, in v2f i) {
    #ifdef _PM_FT_ANISOTROPICS
        float3 direction = float3(1, 0, 0);
        ad.strength = _AnisotropicsStrength;
        ad.t = TangentToWorld(i, direction);
        ad.b = normalize(cross(i.normal, ad.t));
        float3 anisotropyDirection = lerp(ad.t, ad.b, ad.strength);
        float3 anisotropicTangent = cross(anisotropyDirection, ld.viewDir);
        float3 anisotropicNormal = cross(anisotropicTangent, anisotropyDirection);
        float bendFactor = abs(ad.strength) * saturate(5.0 * _RoughnessPerceptual);
        float3 bentNormal = normalize(lerp(_NormalWS, anisotropicNormal, bendFactor));
        ad.r = reflect(-ld.viewDir, bentNormal);
    #endif
}

void ApplyEmission(inout LightingData ld) 
{
    float3 emissive = _EmissionColor * _Emission * _EmissionStrength;
    ld.surfaceColor += emissive * _EmissionsEnable;
}

float3 ReconstructNormal(in float4 i, in float scale)
{
    /* 
       preferred method is to use Unity's unpack
       this uses RG to calculate B, should work 
       if Unity doesn't

        float3 normal;
        normal.xy = (i.xy * 2 - 1) * scale;
        normal.z = sqrt(1.0 - saturate(dot(i.xy, i.xy)));
        return normalize(normal);
    */

    return UnpackNormalWithScale(i, scale);
}

float3 GetMainLightColor()
{
    return _LightColor0.rgb;
}

// does the same thing as Unity and LightVolumes' eval functions
half3 EvaluateSH1(in float3 nm, in float3 L0, in float3 L1r, in float3 L1g, in float3 L1b)
{
    float r = L0.r + dot(L1r, nm);
    float g = L0.g + dot(L1g, nm);
    float b = L0.b + dot(L1b, nm);

    return float3(r, g, b);
}

void ApplyIndirectDiffuse(inout v2f i, inout LightingData ld) 
{
    // half3 sh = ShadeSH9(half4(_NormalWS.x, _NormalWS.y, _NormalWS.z, 1));
    // return (sh * _Albedo / PI) * _Occlusion;
    float3 L0 = float3(0, 0, 0);
    float3 L1r = float3(0, 0, 0);
    float3 L1g = float3(0, 0, 0);
    float3 L1b = float3(0, 0, 0);

    LightVolumeSH(i.worldPos, L0, L1r, L1g, L1b);
    float3 eval = EvaluateSH1(_NormalWS, L0, L1r, L1g, L1b);

    ld.indirectDiffuse += eval;
}

void ApplyIndirectSpecular(inout v2f i, inout LightingData ld, in AnisotropyData ad)
{
    half mip = _RoughnessPerceptual * 6;
    float3 spA = float3(0, 0, 0);
    half4 encoded = 0;
    #ifdef _PM_FT_ANISOTROPICS
        float3 r = lerp(ld.r, ad.r, _AnisotropicsStrength);
        encoded = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, r, mip);
    #else
        encoded = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, ld.r, mip);
    #endif

    float3 L0 = float3(0, 0, 0);
    float3 L1r = float3(0, 0, 0);
    float3 L1g = float3(0, 0, 0);
    float3 L1b = float3(0, 0, 0);

    LightVolumeSH(i.worldPos, L0, L1r, L1g, L1b);

    if (_UdonLightVolumeEnabled != 0) {
        spA = LightVolumeSpecular(_Albedo, 1.0 - _RoughnessPerceptual, _Metallic, _NormalWS, ld.viewDir, L0, L1r, L1g, L1b);
    } else {
        spA = DecodeHDR(encoded, unity_SpecCube0_HDR);
    }

    ld.indirectSpecular += spA;
}

float3 GetCameraPos() {
    float3 worldCam;
    worldCam.x = unity_CameraToWorld[0][3];
    worldCam.y = unity_CameraToWorld[1][3];
    worldCam.z = unity_CameraToWorld[2][3];
    return worldCam;
}

// UnityCG.cginc
void GetVertexLightData (
    inout VertexLightingData vld, in float3 viewDir,
    float4 lightPosX, float4 lightPosY, float4 lightPosZ,
    float3 lightColor0, float3 lightColor1, float3 lightColor2, float3 lightColor3,
    float4 lightAttenSq,
    inout v2f i, float3 normal)
{
    float4 toLightX = lightPosX - i.worldPos.x;
    float4 toLightY = lightPosY - i.worldPos.y;
    float4 toLightZ = lightPosZ - i.worldPos.z;

    float4 lengthSq = 0;
    lengthSq += toLightX * toLightX;
    lengthSq += toLightY * toLightY;
    lengthSq += toLightZ * toLightZ;

    lengthSq = max(lengthSq, 0.000001);

    vld.attNoL = 0;
    vld.attNoL += toLightX * normal.x;
    vld.attNoL += toLightY * normal.y;
    vld.attNoL += toLightZ * normal.z;

    float4 corr = rsqrt(lengthSq);
    vld.attNoL = max(float4(0,0,0,0), vld.attNoL * corr);

    vld.attenuation = 1.0 / (1.0 + lengthSq * lightAttenSq);
    float4 diff = vld.attNoL * vld.attenuation;

    vld.color[0] = lightColor0;
    vld.color[1] = lightColor1;
    vld.color[2] = lightColor2;
    vld.color[3] = lightColor3;

    [unroll]
    for (int index = 0; index < 4; index++)
    {
        vld.lightPos[index] = float3(unity_4LightPosX0[index], unity_4LightPosY0[index], unity_4LightPosZ0[index]);
        float3 vertToLight = vld.lightPos[index] - i.worldPos;
        vld.lightDir[index] = normalize(vertToLight);

        vld.h[index] = normalize(vld.lightDir[index] + viewDir);
        vld.NoL[index] = clamp(dot(normal, vld.lightDir[index]), 0.0, 1.0);
        vld.LoH[index] = clamp(dot(vld.lightDir[index], vld.h[index]), 0.0, 1.0);
        vld.NoH[index] = clamp(dot(normal, vld.h[index]), 0.0, 1.0);
    }
}

void InitVertexLightsData(inout v2f i, in LightingData ld, inout VertexLightingData vld) 
{
    #if defined(PASS_BASE)
        if (i.useVertexLights) {
            GetVertexLightData(vld, ld.viewDir, 
                unity_4LightPosX0, unity_4LightPosY0, 
                unity_4LightPosZ0, unity_LightColor[0].rgb, 
                unity_LightColor[1].rgb, unity_LightColor[2].rgb, 
                unity_LightColor[3].rgb, unity_4LightAtten0, 
                i, _NormalWS);
        }
    #endif
}


void ApplyLTCGI(inout v2f i, inout LightingData ld)
{
    GetLTCGI(i, ld);
    ld.indirectDiffuse += ld.ltcgiDiffuse;
    ld.indirectSpecular += ld.ltcgiSpecular;
}

void InitLightingData(inout v2f i, inout LightingData ld, inout VertexLightingData vld, inout AnisotropyData ad)
{
    float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
    float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
    float3 mainLightColor = GetMainLightColor();
    float3 diffuseColor = float3(1, 1, 1);
    float3 surfaceColor = float3(0, 0, 0);
    float f0 = lerp(0.04, _Albedo.xyz, _Metallic);

    ld.lightDir = lightDir;
    ld.viewDir = viewDir;
    ld.mainLightColor = mainLightColor;
    ld.diffuseColor = diffuseColor;
    ld.surfaceColor = surfaceColor;
    ld.f0 = f0;

    float3 h = normalize(lightDir + viewDir);
    float3 r = reflect(-viewDir, _NormalWS);
    float NoV = abs(dot(_NormalWS, viewDir)) + 1e-5;
    float NoL = clamp(dot(_NormalWS, lightDir), 0.0, 1.0);
    float LoV = clamp(dot(lightDir, viewDir), 0.0, 1.0);

    ld.h = h;
    ld.r = r;
    ld.NoV = NoV;
    ld.NoL = NoL;
    ld.LoV = LoV;

    float NoH = clamp(dot(_NormalWS, h), 0.0, 1.0);
    float LoH = clamp(dot(lightDir, h), 0.0, 1.0);
    float3 illuminance = mainLightColor * NoL;
    float horizon = min(dot(r, _NormalWS) + 1, 1);

    ld.NoH = NoH;
    ld.LoH = LoH;
    ld.illuminance = illuminance;
    ld.horizon = horizon;

    #ifdef _PM_FT_ANISOTROPICS
        InitAnisotropyData(ad, ld, i);
    #endif

    ApplyIndirectSpecular(i, ld, ad);
    ApplyIndirectDiffuse(i, ld);
    InitVertexLightsData(i, ld, vld);
}

void InitMiscData(inout v2f i)
{
    float2 screenPos = i.screenPos.xy / i.screenPos.w;
}