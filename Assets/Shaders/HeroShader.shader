Shader "Custom/HeroShader"
{
    Properties
    {
        [MainColor] _BaseColor ("Base Color", Color) = (1,1,1,1)
        [MainTexture] _BaseMap ("Base Map", 2D) = "white" {}
        _ShadowTex ("Shadow Texture", 2D) = "white" {}
        _ShadowScale ("Shadow Scale", Float) = 1.0

        // wobbly effect
        _WobbleAmount ("Wobble Amount", Float) = 0.02
        _WobbleFrequency ("Wobble Frequency", Float) = 5.0
        _WobbleFPS ("Wobble FPS", Float) = 0.05
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

            // necessary for material to be able to have shadows casted on it
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Shaders/Includes/LightingHelp.hlsl"

			float4 _BaseColor;
            float _ShadowScale;

            float _WobbleAmount;
            float _WobbleSpeed;
            float _WobbleFrequency;
            float _WobbleFPS;

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_ShadowTex);
            SAMPLER(sampler_ShadowTex);

            struct appdata
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct vout
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            vout vert(appdata v)
            {
                vout o = (vout)0;

                float t = floor(_Time.y * _WobbleFPS) / _WobbleFPS; // snaps to multiples of fps

                float phase = dot(v.positionOS.xyz, float3(1, 1, 1)) * _WobbleFrequency;
                float offset = sin(t + phase) * _WobbleAmount;
                float3 positionOS = v.positionOS.xyz + v.normalOS * offset;

                o.positionCS = TransformObjectToHClip(positionOS.xyz);
                o.positionWS = TransformObjectToWorld(positionOS.xyz);
                o.normalWS   = TransformObjectToWorldNormal(v.normalOS);
                o.uv = v.uv;

                return o;
            }

            // returns 1 where toon highlihgt should be and 0 everywhere else
            float ToonSpecular(float3 N, float3 V, float3 L, float attenuation)
            {
                float3 R = reflect(-L, N);
                float spec = pow(max(dot(V, R), 0.0), 32.0) * 0.015 * attenuation;
                return step(0.01, spec) * step(0.0, dot(N, L)); // spec > 0.01 && NdotL > 0
            }

			float4 frag(vout i) : SV_TARGET
			{
                // diffuse color
                float3 N = normalize(i.normalWS);
                float2 thresholds = float2(0.33, 0.66);
                float3 ramped = float3(0.2, 0.4, 1.0);

                // directional light
                float3 mainColor;
                float3 mainDir;
                float distAttenuation;
                float shadowAttenuation;
                GetMainLight_float(i.positionWS, mainColor, mainDir, distAttenuation, shadowAttenuation);
                float mainDiffuse = saturate(dot(N, mainDir)) * distAttenuation * shadowAttenuation;

                // additional lights
                float3 addColor;
                float addDiffuse;
                ComputeAdditionalLighting_float(i.positionWS.xyz, N, thresholds, ramped, addColor, addDiffuse);
                
                float diffuse = mainDiffuse + addDiffuse;

                float3 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv).rgb * _BaseColor.rgb;

                float3 shadow    = albedo * 0.2;
                float3 midtone   = albedo * 0.55;
                float3 highlight = albedo;

                float shadowTex = SAMPLE_TEXTURE2D(_ShadowTex, sampler_ShadowTex, i.uv * _ShadowScale).r;

                float3 texturedShadow = lerp(shadow, midtone, shadowTex);

                float3 output;
                ChooseColor_float(highlight, midtone, texturedShadow, diffuse, thresholds, output);

                // specular highlihgting
                float3 V = normalize(_WorldSpaceCameraPos - i.positionWS);
                
                // directional light
                float spec = ToonSpecular(N, V, mainDir, distAttenuation * shadowAttenuation);

                // additional lights
                int lightCount = GetAdditionalLightsCount();
                for (int li = 0; li < lightCount; ++li)
                {
                    Light light =  GetAdditionalLight(li, i.positionWS.xyz);
                    spec = max(spec, ToonSpecular(N, V, light.direction, light.distanceAttenuation * light.shadowAttenuation));
                }

                float3 col = lerp(output, float3(1, 1, 1), spec); // interpolate between diffuse and white specular highlight

                return float4(col, 1.0);
			}
			ENDHLSL
		}

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}
