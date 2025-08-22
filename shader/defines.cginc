#define PI 3.1415926538
#define EPSILON 1.192092896e-07
#define P_NAN (asfloat(-1));

#include "./util/sample.cginc"

Texture2D _samplerDefault;
SamplerState sampler_samplerDefault;
Texture2D _dfg;
Texture2D _dfg_cloth;
SamplerState dfg_bilinear_clamp_sampler;
sampler2D _ditherPattern;
float4 _ditherPattern_TexelSize;

INIT_TEX2D_NOSAMPLER(_DiffuseAlpha);
INIT_TEX2D_NOSAMPLER(_AlphaTex);
float _pm_nk_hasalpha;
INIT_TEX2D_NOSAMPLER(_ORMTexture);
INIT_TEX2D_NOSAMPLER(_ThicknessTexture);
INIT_TEX2D_NOSAMPLER(_NormalMap);

INIT_TEX2D_NOSAMPLER(_EmissionMask);
float4 _EmissionMask_ST;
float4 _EmissionMask_TexelSize;
float _EmissionStrength;
float3 _EmissionColor;
float3 _Emission;
float _EmissionsEnable;

float4 _DiffuseAlpha_ST;
float4 _DiffuseAlpha_TexelSize;
float4 _AlphaTex_ST;
float4 _AlphaTex_TexelSize;
float4 _ORMTexture_ST;
float4 _ORMTexure_TexelSize;
float4 _ThicknessTexture_ST;
float4 _ThicknessTexture_TexelSize;
float4 _NormalMap_ST;
float4 _NormalMap_TexelSize;

float3 _Albedo;
float3 _Diffuse;
float4 _DiffuseHDR;
float _Roughness;
float _Occlusion;
float _Metallic;
float _RoughnessPerceptual;
float3 _Normal;
float3 _NormalWS;
float _NormalStrength;
float _Alpha;
float _AOStrength;
float _AlphaMode;
float _AlphaCutoff;
float _DitherAmount;
float _DitherBias;
float _FlipBackfaceNormals;
float _EnableAlphaDither;
float _ClampSpecular;
float _RoughnessStrength;
float _MetallicStrength;
float _Thickness;

float4 _SheenColor;
float4 _SubsurfaceColor;
float3 _Subsurface;

float3 _LightColor0;
float4 samplerDefault;

struct LightingData
{
    float3 mainLightColor;
    float3 lightDir;
    float3 viewDir;
    float3 h;
    float3 diffuseColor;
    float3 r;
    float3 surfaceColor;
    half3 indirectSpecular;
    half3 indirectDiffuse;
    float NoV;
    float NoL;
    float NoH;
    float LoH;
    float LoV;
    float f0;
    half3 energyCompensation;
    float3 illuminance;
    float horizon;
    float3 ltcgiDiffuse;
    float3 ltcgiSpecular;
};

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
    half3 energyCompensation;
};

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
    UNITY_VERTEX_OUTPUT_STEREO
};

#include "./third_party/VRCLightVolumes/LightVolumes.cginc"
#include "./third_party/LTCGI.cginc"
#include "./util/util.cginc"
#include "input.cginc"
#include "brdf.cginc"
#include "vert.cginc"
#if defined(PASS_SHDW)
    #include "shadowcaster.cginc"
#else
    #include "frag.cginc"
#endif