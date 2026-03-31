#define EPSILON 1.192092896e-07
#define P_NAN (asfloat(-1));
#define REFL_DI 0.5
#define REFL_EL 0.9

#include "./util/sample.cginc"

Texture2D _samplerDefault;
SamplerState sampler_samplerDefault;
float4 samplerDefault;

// todo: clean this up a lot 

INIT_TEX2D_BCSAMPLER(_dfg);
INIT_TEX2D_BCSAMPLER(_dfg_cloth);
INIT_TEX2D_PWSAMPLER(_ditherPattern);
INIT_TEX2D_NOSAMPLER(_MainTex);
INIT_TEX2D_NOSAMPLER(_AlphaTex);
INIT_TEX2D_NOSAMPLER(_ORMTexture);
INIT_TEX2D_NOSAMPLER(_BumpMap);
INIT_TEX2D_NOSAMPLER(_EmissionMap);
float3 _Diffuse;
float3 _Albedo;
float _Alpha;
float _Roughness;
float _RoughnessPerceptual;
float _Occlusion;
float _Metallic;
float3 _Normal;
float3 _NormalWS;
float3 _Subsurface;
float3 _Emission;
float _UDIMDiscardUV;

#if defined(PIPE_URP)
    CBUFFER_START(UnityPerMaterial);
#endif

float4 _ditherPattern_TexelSize;
float _pm_nk_hasalpha;

float4 _MainTex_ST;
float4 _MainTex_TexelSize;
float4 _DiffuseHDR;

float4 _AlphaTex_ST;
float4 _AlphaTex_TexelSize;
float _AlphaMode;
float _AlphaCutoff;
float _EnableAlphaDither;
float _DitherAmount;
float _DitherBias;

float4 _ORMTexture_ST;
float4 _ORMTexure_TexelSize;
float _RoughnessStrength;
float _MetallicStrength;
float _AOStrength;

float4 _BumpMap_ST;
float4 _BumpMap_TexelSize;
float _NormalStrength;

float _FlipBackfaceNormals;
float _ClampSpecular;

float4 _SubsurfaceColor;

float _EmissionsEnable;
float4 _EmissionMap_ST;
float4 _EmissionMap_TexelSize;
float _EmissionStrength;
float3 _EmissionColor;

float _AnisotropicEnable;
float _AnisotropicsStrength;

float _UDIMDiscardRow3_0;
float _UDIMDiscardRow3_1;
float _UDIMDiscardRow3_2;
float _UDIMDiscardRow3_3;
float _UDIMDiscardRow2_0;
float _UDIMDiscardRow2_1;
float _UDIMDiscardRow2_2;
float _UDIMDiscardRow2_3;
float _UDIMDiscardRow1_0;
float _UDIMDiscardRow1_1;
float _UDIMDiscardRow1_2;
float _UDIMDiscardRow1_3;
float _UDIMDiscardRow0_0;
float _UDIMDiscardRow0_1;
float _UDIMDiscardRow0_2;
float _UDIMDiscardRow0_3;

#if defined(PIPE_URP)
    CBUFFER_END;
#endif

struct pmInput
{
    float4 screenPos;
    float4 tangent;
    float4 vertex;
    float3 worldPos;
    float3 normal;
    float3 viewDir;
    float2 uv0;
    float2 uv1;
    float2 uv2;
    float2 uv3;
    float2 screenPosUV;
    bool useVertexLights;
};

struct pmAnisotropyData
{
    float strength;
    float3 t;
    float3 b;
    float3 r;
};

struct pmLightData
{
    half3 debugColor;

    half3 mainLightColor;
    half mainLightAttenuation;
    half3 illuminance;
    float3 energyCompensation;

    float3 lightDir;
    float3 viewDir;
    float3 h;
    float3 r;
    half3 f0;
    half NoV;
    half NoL;
    half NoH;
    half LoH;
    half LoV;
    half horizon;

    half3 indirectSpecular;
    half3 indirectDiffuse;
    half3 directSpecular;
    half3 directDiffuse;
};

// todo: update vertexlighting for birp

struct VertexLightingData
{
    float3 color[4];
    float NoL[4];
    float3 lightPos[4];
    float3 lightDir[4];
    float3 h[4];
    float LoH[4];
    float NoH[4];
    float4 attenuation;
    float4 attNoL;
    float3 energyCompensation;
};

#if defined(PIPE_BIRP)
    #define PI 3.1415926538
    struct appdata
    {
        float4 vertex : POSITION;
        float3 normal : NORMAL;
        float4 tangent : TANGENT;
        float4 color : COLOR;
        float2 uv0 : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
        float2 uv2 : TEXCOORD2;
        float2 uv3 : TEXCOORD3;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct v2f
    {
        float4 vertex : SV_POSITION;
        float3 normal : NORMAL;
        float4 tangent : TANGENT;
        float4 color : COLOR;
        float2 uv0 : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
        float2 uv2 : TEXCOORD2;
        float2 uv3 : TEXCOORD3;
        float4 screenPos : TEXCOORD4;
        float3 worldPos : TEXCOORD5;
        float3 localPos : TEXCOORD6;
        bool useVertexLights : TEXCOORD7;
        //UNITY_FOG_COORDS(8)
        UNITY_VERTEX_OUTPUT_STEREO
    };
    #include "./pipe/birp.cginc"
#elif defined(PIPE_URP)
    struct Attributes
    {
        float4 positionOS : POSITION;
        float3 normal : NORMAL;
        float4 tangent : TANGENT;
        float2 uv0 : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
        float2 uv2 : TEXCOORD2;
        float2 uv3 : TEXCOORD3;
    };

    struct Varyings
    {
        float4 positionHCS : SV_POSITION;
        float4 tangent : TANGENT;
        float3 normal : NORMAL;
        float2 uv0 : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
        float2 uv2 : TEXCOORD2;
        float2 uv3 : TEXCOORD3;
        float4 screenPos : TEXCOORD4;
        float3 worldPos : TEXCOORD5;
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };
    #include "./pipe/urp.cginc"
#endif

#include "./third_party/VRCLightVolumes/LightVolumes.cginc"
#if defined(LTCGI_INCLUDED)
    #include "./third_party/LTCGI.cginc"
#endif
#include "./util/util.cginc"
#include "input.cginc"
#include "./shade/brdf.cginc"
#include "./shade/shade_common.cginc"
#include "./shade/shade_direct.cginc"
#include "./shade/shade_indirect.cginc"
#include "vert.cginc"
#if defined(PASS_SHDW)
    #include "shadowcaster.cginc"
#else
    #include "frag.cginc"
#endif