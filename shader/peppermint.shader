Shader "mintea/peppermint"
{
	Properties
	{
        [HideInInspector] _dfg("GXX DFG", 2D) = "white" {}
        [HideInInspector] _dfg_cloth("Cloth DFG", 2D) = "white" {}
        [HideInInspector] _samplerDefault("", 2D) = "white" {}
        [HideInInspector] _ditherPattern("Dither", 2D) = "white" {}
        [HideInInspector] _pm_nk_hasalpha("_hasalpha", Range(0, 1)) = 0

		[SingleLineTexture] _ORMTexture("Main/Textures/ORM", 2D) = "white" {}
        [SingleLineTexture][Normal] _NormalMap("Main/Textures/Normal Map", 2D) = "bump" {}
        [hdr] _DiffuseHDR ("Main/Textures/Diffuse Color", color) = (1,1,1,1)
        [SingleLineTexture] _DiffuseAlpha("Main/Textures/Diffuse", 2D) = "white" {}
        [SingleLineTexture] _AlphaTex("Main/Textures/Alpha", 2D) = "white" {}

        [Enum(GGX, 0, Charlie, 1)] _DiffuseNDF("Main/BRDF/NDF/Diffuse NDF", Float) = 0
        [hdr] _SheenColor ("Main/BRDF/NDF/Sheen Color", color) = (1,1,1,1)

        [Toggle] _SubsurfaceEnable("Main/BRDF/Subsurface Scattering/Enable", Float) = 0
        [SingleLineTexture] _ThicknessTexture("Main/BRDF/Subsurface Scattering/Thickness", 2D) = "white" {}
        [hdr] _SubsurfaceColor ("Main/BRDF/Subsurface Scattering/Color", color) = (1,1,1,1)

		_AOStrength("Main/AO Strength", Range(0, 1)) = 1
        _RoughnessStrength("Main/Roughness", Range(0, 1)) = 1
        _MetallicStrength("Main/Metallic", Range(0, 1)) = 1
		_NormalStrength("Main/Normal Strength", Range(0, 5)) = 1
        [Toggle] _ClampSpecular("Main/Clamp Specular", Float) = 0

        [Toggle] _EmissionsEnable("Emission/Enable", Float) = 0
        [hdr] _EmissionColor ("Emission/Color", color) = (1,1,1,1)
        [SingleLineTexture] _EmissionMask("Emission/Mask", 2D) = "white" {}
        _EmissionStrength("Emission/Strength", Range(0, 1)) = 0

        _LightVolumesBias("Extra/Light Volumes Bias", Float) = 0
        [Toggle(_DOMINANTDIRSPECULARS_ON)] _DominantDirSpeculars("Extra/Dominant Dir Speculars", Float) = 0

        [Toggle] _FlipBackfaceNormals("Rendering/Flip Backface Normals", Float) = 1
        [Enum(Opaque, 0, Cutout, 1, Transparent, 2)] _AlphaMode ("Main/Alpha/Mode", Float) = 0
        _AlphaCutoff("Main/Alpha/Cutoff", Range(0, 1)) = 0.5
        [Toggle] _EnableAlphaDither("Main/Alpha/Dither", Float) = 0
        _DitherAmount("Main/Alpha/Dither Amount", Range(0, 1)) = 0.5
        _DitherBias("Main/Alpha/Dither Bias", Range(0, 1)) = 0.5
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
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase
			#pragma multi_compile_instancing
            #pragma shader_feature_local _ _PM_NDF_GGX _PM_NDF_CHARLIE
            #pragma shader_feature_local _PM_FT_SUBSURFACE
            #define PASS_BASE
            #include "UnityCG.cginc"
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
            #pragma multi_compile_fog
			#pragma multi_compile_fwdadd_fullshadows
            #pragma shader_feature_local _ _PM_NDF_GGX _PM_NDF_CHARLIE
            #pragma shader_feature_local _PM_FT_SUBSURFACE
            #define PASS_ADD
            #include "UnityCG.cginc"
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
            #define PASS_SHDW
            #include "UnityCG.cginc"
            #include "defines.cginc"
            ENDCG
        }
    }
    FallBack "Diffuse"
}
