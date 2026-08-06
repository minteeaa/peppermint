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
INIT_TEX2D_PWSAMPLER(_ditherPattern);
INIT_TEX2D_NOSAMPLER(_MainTex);
INIT_TEX2D_NOSAMPLER(_AlphaTex);
INIT_TEX2D_NOSAMPLER(_ORMTexture);
INIT_TEX2D_NOSAMPLER(_BumpMap);
INIT_TEX2D_NOSAMPLER(_EmissionMap);
INIT_TEX2D_NOSAMPLER(_ThicknessMap);
INIT_TEX2D_NOSAMPLER(_SubsurfaceMask);

half3 _Normal;
half3 _NormalWS;
half3 _Diffuse;
half3 _Albedo;
half3 _Subsurface;
half3 _Emission;
half _Alpha;
half _Roughness;
half _Occlusion;
half _Metallic;
half _perceptualRoughness;
int _UDIMDiscardUV;

#if defined(PIPE_URP)
    CBUFFER_START(UnityPerMaterial);
#endif

half4 _ditherPattern_TexelSize;
half _pm_nk_hasalpha;

half4 _MainTex_ST;
half4 _MainTex_TexelSize;
float4 _DiffuseHDR;

half4 _AlphaTex_ST;
half4 _AlphaTex_TexelSize;
int _AlphaMode;
half _Cutoff;
bool _EnableAlphaDither;
half _DitherAmount;
half _DitherBias;

half4 _ORMTexture_ST;
half4 _ORMTexure_TexelSize;
half _RoughnessStrength;
half _MetallicStrength;
half _AOStrength;

half4 _BumpMap_ST;
half4 _BumpMap_TexelSize;
half _NormalStrength;

bool _FlipBackfaceNormals;
bool _ClampSpecular;

float3 _SubsurfaceColor;
half _SubsurfaceScatterDistance;
half3 _SubsurfaceScatterColor;
half4 _ThicknessMap_ST;
half4 _ThicknessMap_TexelSize;
float _Thickness;
half4 _SubsurfaceMask_ST;
half4 _SubsurfaceMask_TexelSize;
float _SubsurfaceStrength;

bool _SheenEnable;
float3 _SheenColor;
float _SheenRoughness;

bool _EmissionsEnable;
half4 _EmissionMap_ST;
half4 _EmissionMap_TexelSize;
half _EmissionStrength;
float4 _EmissionColor;

bool _AnisotropicEnable;
half _AnisotropicsStrength;

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

bool _Debug;
int _DebugMode;

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
    float attenuation;
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
    float3 luminance;
    float3 illuminance;
    float3 energyCompensation;

    float3 lightDir;
    float3 viewDir;
    float3 h;
    float3 r;
    half3 f0;
    half3 dfg;
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
    half3 lvSpecular;

    float3 worldPos;

    #if defined(_PM_FT_SHEEN)
        float sheenPerceptualRoughness;
        float sheenRoughness;
        half3 sheenScaling;
        half sheenDFG;
    #endif

    #if defined(_PM_FT_SUBSURFACE)
        half3 subsurfMFP;
        half3 subsurfAbsorption;
        half3 subsurfScaling;
        half subsurfDFG;
    #endif
};

// todo: update vertexlighting for birp

struct pmVertexLightData
{
    float3 color[4];
    half4 attenuation;
    half4 attNoL;
    half3 energyCompensation;

    float3 lightPos[4];
    float3 lightDir[4];
    float3 h[4];
    half3 dfg;
    float NoL[4];
    float LoH[4];
    float NoH[4];
    
    half3 diffuse;
    half3 specular;
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
        float4 pos : SV_POSITION;
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
        #if !defined(PASS_SHDW)
            #if defined(PASS_BASE)
                SHADOW_COORDS(7)
            #elif defined(PASS_ADD)
                LIGHTING_COORDS(7, 8)
            #endif
        #endif
        UNITY_FOG_COORDS(9)
        bool useVertexLights : TEXCOORD10;
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
#if defined(_PM_FT_LTCGI)
    #include "./third_party/LTCGI/LTCGI.cginc"
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