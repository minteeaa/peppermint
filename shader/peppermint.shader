Shader "mintea/peppermint"
{
	Properties
	{
        [HideInInspector] _dfg("GGX DFG", 2D) = "white" {}
        [HideInInspector] [SingleLineTexture] _dfg_cloth("Cloth DFG", 2D) = "white" {}
        [HideInInspector] _samplerDefault("", 2D) = "white" {}
        [HideInInspector] _ditherPattern("Dither", 2D) = "white" {}
        [HideInInspector] _pm_nk_hasalpha("_hasalpha", Range(0, 1)) = 0

		[SingleLineTexture] _ORMTexture("Main/Textures/ORM", 2D) = "white" {}
        [SingleLineTexture][Normal] _BumpMap("Main/Textures/Normal Map", 2D) = "bump" {}
        [hdr] _DiffuseHDR("Main/Textures/Diffuse Color", color) = (1,1,1,1)
        [SingleLineTexture] _MainTex("Main/Textures/Diffuse", 2D) = "white" {}
        [SingleLineTexture] _AlphaTex("Main/Textures/Alpha", 2D) = "white" {}

        [Enum(Opaque, 0, Cutout, 1, Transparent, 2)] _AlphaMode ("Main/Alpha/Mode", Float) = 0
        _Cutoff("Main/Alpha/Cutoff", Range(0, 1)) = 0.5
        [Toggle] _EnableAlphaDither("Main/Alpha/Dither", Float) = 0
        _DitherAmount("Main/Alpha/Dither Amount", Range(0, 1)) = 0.5
        _DitherBias("Main/Alpha/Dither Bias", Range(0, 1)) = 0.5

        [Enum(GGX, 0, Charlie, 1)] _DiffuseNDF("Main/BRDF/NDF/Diffuse NDF", Float) = 0
        [hdr] _SheenColor ("Main/BRDF/NDF/Sheen Color", color) = (1,1,1,1)

        [Toggle] _SubsurfaceEnable("Main/BRDF/Subsurface Scattering/Enable", Float) = 0
        [hdr] _SubsurfaceColor ("Main/BRDF/Subsurface Scattering/Color", color) = (1,1,1,1)

        [Toggle] _AnisotropicsEnable("Main/BRDF/Anisotropics/Enable", Float) = 0
        _AnisotropicsStrength("Main/BRDF/Anisotropics/Strength", Range(-1, 1)) = 1

		_AOStrength("Main/AO Strength", Range(0, 1)) = 1
        _RoughnessStrength("Main/Roughness", Range(0, 1)) = 1
        _MetallicStrength("Main/Metallic", Range(0, 1)) = 1
		_NormalStrength("Main/Normal Strength", Range(0, 5)) = 1
        [Toggle] _ClampSpecular("Main/Clamp Specular", Float) = 0

        [Toggle] _EmissionsEnable("Emission/Enable", Float) = 0
        [hdr] _EmissionColor("Emission/Color", color) = (1,1,1,1)
        [SingleLineTexture] _EmissionMap("Emission/Mask", 2D) = "white" {}
        _EmissionStrength("Emission/Strength", Range(0, 1)) = 0

        [Toggle] _UVTileDiscardEnable("UV Tile Discard/Enable", Float) = 0
        [Enum(UV0, 0, UV1, 1, UV2, 2, UV3, 3)] _UDIMDiscardUV("UV Tile Discard/UV", Float) = 0

        // wip uv tile discard (ui needs... work)
        // much inspiration from Poiyomi
        [Toggle] _UDIMDiscardRow0_0("UV Tile Discard/0_0", Float) = 0
        [Toggle] _UDIMDiscardRow0_1("UV Tile Discard/0_1", Float) = 0
        [Toggle] _UDIMDiscardRow0_2("UV Tile Discard/0_2", Float) = 0
        [Toggle] _UDIMDiscardRow0_3("UV Tile Discard/0_3", Float) = 0

        [Toggle] _UDIMDiscardRow1_0("UV Tile Discard/1_0", Float) = 0
        [Toggle] _UDIMDiscardRow1_1("UV Tile Discard/1_1", Float) = 0
        [Toggle] _UDIMDiscardRow1_2("UV Tile Discard/1_2", Float) = 0
        [Toggle] _UDIMDiscardRow1_3("UV Tile Discard/1_3", Float) = 0

        [Toggle] _UDIMDiscardRow2_0("UV Tile Discard/2_0", Float) = 0
        [Toggle] _UDIMDiscardRow2_1("UV Tile Discard/2_1", Float) = 0
        [Toggle] _UDIMDiscardRow2_2("UV Tile Discard/2_2", Float) = 0
        [Toggle] _UDIMDiscardRow2_3("UV Tile Discard/2_3", Float) = 0

        [Toggle] _UDIMDiscardRow3_0("UV Tile Discard/3_0", Float) = 0
        [Toggle] _UDIMDiscardRow3_1("UV Tile Discard/3_1", Float) = 0
        [Toggle] _UDIMDiscardRow3_2("UV Tile Discard/3_2", Float) = 0
        [Toggle] _UDIMDiscardRow3_3("UV Tile Discard/3_3", Float) = 0

        _LightVolumesBias("Extra/Light Volumes Bias", Float) = 0
        [Toggle(_DOMINANTDIRSPECULARS_ON)] _DominantDirSpeculars("Extra/Dominant Dir Speculars", Float) = 0

        [Toggle] _FlipBackfaceNormals("Rendering/Flip Backface Normals", Float) = 1
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Rendering/Cull", Float) = 2
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Rendering/ZTest", Float) = 4
		[Toggle] _ZWrite ("Rendering/ZWrite", Int) = 1
        [Toggle] _ZClip ("Rendering/ZClip", Float) = 1
        [Enum(Simple, 0, Front Face vs Back Face, 1)] _StencilType ("Rendering/Stencil Type", Float) = 0

		[Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Rendering/Blending/RGB/RGB Blend Op", Int) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Rendering/Blending/RGB/RGB Source Blend", Int) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Rendering/Blending/RGB/RGB Destination Blend", Int) = 0
		[Enum(UnityEngine.Rendering.BlendOp)] _AddBlendOp ("Rendering/Blending/RGB Add/RGB Blend Op", Int) = 4
		[Enum(UnityEngine.Rendering.BlendMode)] _AddSrcBlend ("Rendering/Blending/RGB Add/RGB Source Blend", Int) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _AddDstBlend ("Rendering/Blending/RGB Add/RGB Destination Blend", Int) = 1

		[Enum(UnityEngine.Rendering.BlendOp)] _BlendOpAlpha ("Rendering/Blending/Alpha/Alpha Blend Op", Int) = 4
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendAlpha ("Rendering/Blending/Alpha/Alpha Source Blend", Int) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlendAlpha ("Rendering/Blending/Alpha/Alpha Destination Blend", Int) = 1
		[Enum(UnityEngine.Rendering.BlendOp)] _AddBlendOpAlpha ("Rendering/Blending/Alpha Add/Alpha Blend Op", Int) = 4
		[Enum(UnityEngine.Rendering.BlendMode)] _AddSrcBlendAlpha ("Rendering/Blending/Alpha Add/Alpha Source Blend", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _AddDstBlendAlpha ("Rendering/Blending/Alpha Add/Alpha Destination Blend", Int) = 1

		_StencilRef ("Rendering/Stencil/Stencil Reference Value", Range(0, 255)) = 0
		_StencilReadMask ("Rendering/Stencil/Stencil ReadMask Value", Range(0, 255)) = 255
		_StencilWriteMask ("Rendering/Stencil/Stencil WriteMask Value", Range(0, 255)) = 255
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilPassOp ("Rendering/Stencil/Stencil Pass Op", Float) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilFailOp ("Rendering/Stencil/Stencil Fail Op", Float) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilZFailOp ("Rendering/Stencil/Stencil ZFail Op", Float) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilCompareFunction ("Rendering/Stencil/Stencil Compare Function", Float) = 8
	}
    CustomEditor "peppermint_ui" 
    SubShader
    {
        PackageRequirements { "com.unity.render-pipelines.universal" }
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "FORWARD_URP"
            Tags { "LightMode" = "UniversalForward" }
            ZWrite [_ZWrite]
            ZClip [_ZClip]

            Cull [_Cull]
            ZTest [_ZTest]
            BlendOp [_BlendOp], [_BlendOpAlpha]
            Blend [_SrcBlend] [_DstBlend], [_SrcBlendAlpha] [_DstBlendAlpha]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //#pragma multi_compile_fog
            #pragma multi_compile _ PROBE_VOLUMES_L1 PROBE_VOLUMES_L2
            #pragma shader_feature_local _ _PM_NDF_GGX _PM_NDF_CHARLIE
            #pragma shader_feature_local _PM_FT_EMISSIONS
            #pragma shader_feature_local _PM_FT_SUBSURFACE
            #pragma shader_feature_local _PM_FT_ANISOTROPICS
            #pragma shader_feature_local _PM_FT_UVTILEDISCARD
            #define PASS_BASE_URP
            #define PIPE_URP
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Lighting/ProbeVolume/ProbeVolume.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/AmbientProbe.hlsl"
            #include "defines.cginc"
            ENDHLSL
        }
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "VRCFallback" = "Standard" "LTCGI"="ALWAYS" }
        LOD 200

        Pass
        {
            Name "FORWARD"
            Tags {"LightMode" = "ForwardBase"}
            ZWrite [_ZWrite]
            ZClip [_ZClip]

            Cull [_Cull]
            ZTest [_ZTest]
            BlendOp [_BlendOp], [_BlendOpAlpha]
            Blend [_SrcBlend] [_DstBlend], [_SrcBlendAlpha] [_DstBlendAlpha]

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            //#pragma multi_compile_fog
            #pragma multi_compile_fwdbase
			#pragma multi_compile_instancing
            #pragma shader_feature_local _ _PM_NDF_GGX _PM_NDF_CHARLIE
            #pragma shader_feature_local _PM_FT_LTCGI
            #pragma shader_feature_local _PM_FT_EMISSIONS
            #pragma shader_feature_local _PM_FT_SUBSURFACE
            #pragma shader_feature_local _PM_FT_ANISOTROPICS
            #pragma shader_feature_local _PM_FT_UVTILEDISCARD
            #define PASS_BASE
            #define PIPE_BIRP
            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"
            #include "defines.cginc"
            ENDCG
        }

        Pass
        {
            Name "ADD"
            Tags {"LightMode" = "ForwardAdd"}
            ZWrite Off
            ZClip [_ZClip]
            Fog {Color (0,0,0,0)}

            Cull [_Cull]
            ZTest [_ZTest]

            BlendOp [_AddBlendOp], [_AddBlendOpAlpha]
            Blend [_AddSrcBlend] [_AddDstBlend], [_AddSrcBlendAlpha] [_AddDstBlendAlpha]

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            //#pragma multi_compile_fog
			#pragma multi_compile_fwdadd_fullshadows
            #pragma shader_feature_local _ _PM_NDF_GGX _PM_NDF_CHARLIE
            #pragma shader_feature_local _PM_FT_LTCGI
            #pragma shader_feature_local _PM_FT_EMISSIONS
            #pragma shader_feature_local _PM_FT_SUBSURFACE
            #pragma shader_feature_local _PM_FT_ANISOTROPICS
            #pragma shader_feature_local _PM_FT_UVTILEDISCARD
            #define PASS_ADD
            #define PIPE_BIRP
            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"
            #include "defines.cginc"
            ENDCG
        }

        Pass
        {
            Name "SHADOWCASTER"
            Tags {"LightMode" = "ShadowCaster"}
            ZWrite [_ZWrite]

            Cull [_Cull]
            ZTest [_ZTest]
            BlendOp [_BlendOp], [_BlendOpAlpha]
            Blend [_SrcBlend] [_DstBlend], [_SrcBlendAlpha] [_DstBlendAlpha]

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_instancing
            #pragma multi_compile_shadowcaster
            #pragma shader_feature_local _PM_FT_UVTILEDISCARD
            #define PASS_SHDW
            #define PIPE_BIRP
            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"
            #include "defines.cginc"
            ENDCG
        }
    }
    FallBack "Diffuse"
}
