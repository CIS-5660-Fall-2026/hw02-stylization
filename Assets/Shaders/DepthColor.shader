Shader "Custom/DepthColor"
{
	Properties
	{		
		_DepthBase("Depth Base", Range(0, 0.1)) = 0
		_DepthColor("Depth Color", Color) = (0, 0, 0, 1)
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalPipeline"
			"RenderType" = "Opaque"
		}

		Pass
		{
			Name "Scene Outline"

			ZWrite Off
			ZTest Always
			Cull Off

			HLSLPROGRAM

			#pragma vertex Vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"

			float _DepthBase;
			float3 _DepthColor;

			float4 frag(Varyings input) : SV_Target
			{
				float depth = LinearEyeDepth(SampleSceneDepth(input.texcoord), _ZBufferParams);
				depth = 1 - pow(1 + _DepthBase, -pow(depth, 1.5));
				// return float4(depth, 0, 0, 1);

				// Scene color
				float3 sceneColor = SAMPLE_TEXTURE2D_X(
					_BlitTexture, sampler_LinearClamp, input.texcoord
				).rgb;

				return float4(lerp(sceneColor, _DepthColor, depth), 1);
			}

			ENDHLSL
		}
	}
}