Shader "Custom/SceneOutline"
{
	Properties
	{
		_OutlineColor("Outline Color", Color) = (0,0,0,1)

		_DepthThreshold("Depth Threshold", Range(0.0, 2.0)) = 0.01
		_NormalThreshold("Normal Threshold", Range(0.0, 2.0)) = 0.2
		
		// _PixelCount("Pixel Count", Float) = 100

		_Thickness("Thickness", Float) = 1.0
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

			float3 _OutlineColor;

			float _DepthThreshold;
			float _NormalThreshold;

			// float _PixelCount;

			float _Thickness;

			float2 hash22(float2 p)
			{
				p = frac(p * float2(123.34, 456.21));
				p += dot(p, p + 13.57);

				return frac(float2(
					p.x * p.y,
					p.x + p.y
				));
			}

			float2 noise22(float2 p)
			{
				float2 i = floor(p);
				float2 f = frac(p);

				// Smooth interpolation
				float2 u = f * f * (3.0 - 2.0 * f);

				float2 a = hash22(i + float2(0, 0));
				float2 b = hash22(i + float2(1, 0));
				float2 c = hash22(i + float2(0, 1));
				float2 d = hash22(i + float2(1, 1));

				return lerp(
					lerp(a, b, u.x),
					lerp(c, d, u.x),
					u.y
				);
			}

			float DepthDifference(float d0, float d1)
			{
				return abs(d0 - d1);
			}

			float NormalDifference(float3 n0, float3 n1)
			{
				return 1.0 - saturate(dot(n0, n1));
			}

			float4 frag(Varyings input) : SV_Target
			{
				float2 uv = input.texcoord;
				
				// float2 factor = _ScreenParams.xy / _ScreenParams.x * _PixelCount;
				// float2 uv = floor(input.texcoord * factor) / factor;

				float2 texel = _Thickness / _ScreenParams.xy;

				// float2 tileUV = uv * _ScreenParams.xy / _JiggleRange;
				// float2 noise = hash22(floor(tileUV + floor(_Time.z))) * noise22(tileUV);
				// 
				// uv += noise * _JiggleStrength / _ScreenParams.xy;
				//return float4(uv, 0, 1);

				// Center
				float depthC = SampleSceneDepth(uv);
				float3 normalC = SampleSceneNormals(uv);

				// Four Neighbors
				float2 uvL = uv + float2(-texel.x, 0);
				float2 uvR = uv + float2( texel.x, 0);
				float2 uvU = uv + float2(0,  texel.y);
				float2 uvD = uv + float2(0, -texel.y);

				float depthL = SampleSceneDepth(uvL);
				float depthR = SampleSceneDepth(uvR);
				float depthU = SampleSceneDepth(uvU);
				float depthD = SampleSceneDepth(uvD);

				float3 normalL = SampleSceneNormals(uvL);
				float3 normalR = SampleSceneNormals(uvR);
				float3 normalU = SampleSceneNormals(uvU);
				float3 normalD = SampleSceneNormals(uvD);

				float depthEdge =
					DepthDifference(depthC, depthL) +
					DepthDifference(depthC, depthR) +
					DepthDifference(depthC, depthU) +
					DepthDifference(depthC, depthD);
				float normalEdge =
					NormalDifference(normalC, normalL) +
					NormalDifference(normalC, normalR) +
					NormalDifference(normalC, normalU) +
					NormalDifference(normalC, normalD);

				float edge =
					max(
						step(_DepthThreshold, depthEdge),
						step(_NormalThreshold, normalEdge)
					);
				edge *= step(1e-10, SampleSceneDepth(input.texcoord));

				// Scene color
				float4 sceneColor = SAMPLE_TEXTURE2D_X(
					_BlitTexture,
					sampler_LinearClamp,
					uv
				);

				return float4(lerp(
					sceneColor.rgb,
					_OutlineColor,
					edge
				), 1);
			}

			ENDHLSL
		}
	}
}