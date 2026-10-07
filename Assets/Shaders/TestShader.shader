Shader "Basics/TestShader"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (1, 1, 1, 1)
	}
	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalPipeline"
			"RenderType" = "Opaque"
			"Queue" = "Geometry"
		}

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			float4 _BaseColor;

			struct appdata
			{
				float4 position : POSITION;
			};

			struct vout
			{
				float4 positionCS : SV_POSITION;
			};

			vout vert(appdata v)
			{
				vout o = (vout)0;

				o.positionCS = TransformObjectToHClip(v.position.xyz);

				return o;
			}

			float4 frag(vout i) : SV_TARGET
			{
				return _BaseColor;
			}

			ENDHLSL
		}
	}
}