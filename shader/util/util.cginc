// derived from filament/shaders/src/common_math.glsl
#define PREVENT_DIV0(n, d, magic)   ((n) / max(d, magic))

// todo: normalize name capitalization scheme

inline half3 uSafeNormalize(half3 inVec)
{
    half dp3 = max(0.001f, dot(inVec, inVec));
    return inVec * rsqrt(dp3);
}

void initDefaultSampler(out float4 defaultSampler)
{
    defaultSampler = TEX2D_SAMPLE_SAMPLER(_samplerDefault, sampler_samplerDefault, 0) * EPSILON;
}

// derived from Poiyomi's implementation
float SetDiscard(float2 udim, float4 UDIMDiscardRows[4])
{
	float toDiscard = 0;
	float4 xMask = float4(
        (udim.x >= 0 && udim.x < 1),
        (udim.x >= 1 && udim.x < 2),
        (udim.x >= 2 && udim.x < 3),
        (udim.x >= 3 && udim.x < 4)
    );
	
	toDiscard += (udim.y >= 0 && udim.y < 1) * dot(UDIMDiscardRows[0], xMask);
	toDiscard += (udim.y >= 1 && udim.y < 2) * dot(UDIMDiscardRows[1], xMask);
	toDiscard += (udim.y >= 2 && udim.y < 3) * dot(UDIMDiscardRows[2], xMask);
	toDiscard += (udim.y >= 3 && udim.y < 4) * dot(UDIMDiscardRows[3], xMask);
	
	toDiscard *= any(float4(udim.y >= 0, udim.y < 4, udim.x >= 0, udim.x < 4)); 
    
	const float threshold = 0.001;
	return threshold - toDiscard;
}

void flipNormals(inout pmInput i, in bool isFrontFace)
{
    i.normal = normalize(i.normal);
    if (!isFrontFace)
        i.normal = -i.normal;
}

void prepareSurface(inout pmInput i, in bool isFrontFace) 
{
    if (_FlipBackfaceNormals > 0.1) 
        flipNormals(i, isFrontFace);
}

float3 tangentToWorld(in pmInput i, in float3 input)
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

half3 sampleDFG(half NoV)
{
    float2 dfgUV = float2(NoV, _Roughness);
    #ifdef _PM_NDF_CHARLIE
        half4 dfgCloth = TEX2D_SAMPLE_SAMPLER(_dfg_cloth, sampler_dfg_cloth_bilinear_clamp, dfgUV);
        half4 dfgGGX = TEX2D_SAMPLE_SAMPLER(_dfg, sampler_dfg_bilinear_clamp, dfgUV);
        half4 dfgSample = lerp(dfgCloth, dfgGGX, _Metallic);
    #else
        half4 dfgSample = TEX2D_SAMPLE_SAMPLER(_dfg, sampler_dfg_bilinear_clamp, dfgUV);
    #endif
    return dfgSample.rgb;
}

half3 computeEnergyCompensation(half3 dfg, half3 f0)
{
    half3 energyCompensation = 1.0 + f0 * (1.0 / max(dfg.y, 0.005) - 1.0);
    return energyCompensation;
}

half3 ReconstructNormal(in half4 i, in half scale)
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

    #if defined(PIPE_BIRP)
        return UnpackNormalWithScale(i, scale);
    #elif defined(PIPE_URP)
        return UnpackNormalScale(i, scale);
    #endif
}

half3 computeF0(in half3 albedo, in half3 metallic, in half reflectance)
{
    half dielectricF0 = 0.16 * reflectance * reflectance;
    return albedo.rgb * metallic + (dielectricF0 * (1.0 - metallic));
}

float3 GetMainLightColor()
{
    #if defined(PIPE_BIRP)
        return _LightColor0.rgb;
    #elif defined(PIPE_URP)
        return GetMainLight().color;
    #endif
}

float GetMainLightAttenuation() 
{
    #if defined(PIPE_BIRP)
        return _LightColor0.a;
    #elif defined(PIPE_URP)
        return GetMainLight().shadowAttenuation;
    #endif
}

// does the same thing as Unity and LightVolumes' eval functions
half3 EvaluateSH1(in float3 nm, in float3 L0, in float3 L1r, in float3 L1g, in float3 L1b)
{
    float r = L0.r + dot(L1r, nm);
    float g = L0.g + dot(L1g, nm);
    float b = L0.b + dot(L1b, nm);

    return float3(r, g, b);
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
    inout pmVertexLightData vld, in float3 viewDir,
    float4 lightPosX, float4 lightPosY, float4 lightPosZ,
    float3 lightColor0, float3 lightColor1, float3 lightColor2, float3 lightColor3,
    float4 lightAttenSq,
    inout pmInput i, float3 normal)
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
        #if defined(PIPE_BIRP)
            vld.lightPos[index] = float3(unity_4LightPosX0[index], unity_4LightPosY0[index], unity_4LightPosZ0[index]);
            float3 vertToLight = vld.lightPos[index] - i.worldPos;
            vld.lightDir[index] = normalize(vertToLight);

            vld.h[index] = normalize(vld.lightDir[index] + viewDir);
            vld.NoL[index] = clamp(dot(normal, vld.lightDir[index]), 0.0, 1.0);
            vld.LoH[index] = clamp(dot(vld.lightDir[index], vld.h[index]), 0.0, 1.0);
            vld.NoH[index] = clamp(dot(normal, vld.h[index]), 0.0, 1.0);
        #endif
    }
}

pmVertexLightData prepareVertexLightData(inout pmInput i, in pmLightData ld) 
{
    pmVertexLightData vld = (pmVertexLightData)0;
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
    return vld;
}

pmAnisotropyData prepareAnisotropyData(in pmLightData ld, in pmInput i)
{
    pmAnisotropyData ad;

    float3 direction = float3(1, 0, 0);
    ad.strength = _AnisotropicsStrength;
    ad.t = tangentToWorld(i, direction);
    ad.b = normalize(cross(i.normal, ad.t));
    float3 anisotropyDirection = lerp(ad.t, ad.b, ad.strength);
    float3 anisotropicTangent = cross(anisotropyDirection, ld.viewDir);
    float3 anisotropicNormal = cross(anisotropicTangent, anisotropyDirection);
    float bendFactor = abs(ad.strength) * saturate(5.0 * _Roughness);
    float3 bentNormal = normalize(lerp(_NormalWS, anisotropicNormal, bendFactor));
    ad.r = reflect(-ld.viewDir, bentNormal);

    return ad;
}

pmLightData prepareLightData(in pmInput i)
{
    pmLightData ld = (pmLightData)0;

    float3 lightDir = 0;
    float3 viewDir = 0;

    #if defined(PIPE_BIRP)
        lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
        viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
    #elif defined(PIPE_URP)
        lightDir = normalize(GetMainLight().direction);
        viewDir = GetWorldSpaceNormalizeViewDir(i.worldPos);
    #endif

    ld.lightDir = lightDir;
    ld.viewDir = viewDir;
    ld.mainLightColor = GetMainLightColor();
    ld.mainLightAttenuation = GetMainLightAttenuation();

    ld.h = uSafeNormalize(ld.lightDir + ld.viewDir);
    ld.r = reflect(-ld.viewDir, _NormalWS);
    ld.NoV = abs(dot(_NormalWS, ld.viewDir)) + 1e-5;
    ld.NoL = clamp(dot(_NormalWS, ld.lightDir), 0.0, 1.0);
    ld.LoV = clamp(dot(ld.lightDir, ld.viewDir), 0.0, 1.0);

    ld.NoH = clamp(dot(_NormalWS, ld.h), 0.0, 1.0);
    ld.LoH = clamp(dot(ld.lightDir, ld.h), 0.0, 1.0);
    ld.illuminance = ld.mainLightColor * ld.NoL;
    ld.horizon = min(dot(ld.r, _NormalWS) + 1, 1);
    ld.f0 = computeF0(_Albedo, _Metallic, REFL_DI);
    ld.dfg = sampleDFG(ld.NoV);
    ld.energyCompensation = computeEnergyCompensation(ld.dfg, ld.f0);

    return ld;
}