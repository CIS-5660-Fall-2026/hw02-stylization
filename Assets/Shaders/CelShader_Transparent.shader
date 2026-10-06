Shader "CustomShaders/CelShader"
{
    Properties
    {
        _MainColor("Surface Color", Color) = (1, 1, 1, 1)
        _ShadowTex("Shadow Texture", 2D) = "white" {}
        // _Smoothness("Smoothness Coefficient", Range(0.0, 1.0)) = 1.0

        _SmoothFactor("Smooth Factor",  Range(0.0, 0.5)) = 0.0
        _DiffuseThreshold("Diffuse Threshold",  Range(0.0, 1.0)) = 0.5
        _DiffuseStrength("Diffuse Strength",  Range(0.0, 1.0)) = 0.5
        _SpecularThreshold("Specular Threshold",  Range(0.0, 1.0)) = 0.5
        // _RimThreshold("Rim Threshold",  Range(0.0, 1.0)) = 0.5
        _ShadowThreshold("Shadow Threshold",  Range(0.0, 1.0)) = 0.5
        _AmbientStrength("Ambient Strength",  Range(0.0, 10.0)) = 1

        _Alpha("Alpha",  Range(0.0, 1.0)) = 1.0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        // Cel shader
        Pass
        {
            Cull Back ZWrite Off

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS

            #pragma multi_compile _ _FORWARD_PLUS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct a2v
            {
                float4 vertexOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertexCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexSS : TEXCOORD1;
                float4 vertexWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
            };

            float3 _MainColor;
            sampler2D _ShadowTex;
            float4 _ShadowTex_ST;
            // float4 _SurfaceColor;
            // float _Smoothness;
            float _RimCoe;

            float _DiffuseThreshold;
            float _DiffuseStrength;
            float _SpecularThreshold;
            // float _RimThreshold;
            float _ShadowThreshold;
            float _AmbientStrength;

            float _Alpha;

            float4 CalculateCelLighting(
                Light l,
                float3 normalWS,
                float3 viewDirWS,
                float shadowMask
            ) {
                float shadow = step(_ShadowThreshold, l.shadowAttenuation * l.distanceAttenuation);
                shadowMask = saturate((1 - shadow) * (1 - shadowMask));

                // Diffuse
                float diffuse = step(_DiffuseThreshold, dot(normalWS, l.direction));
                diffuse *= shadow;
                
                return float4(l.color * diffuse * _DiffuseStrength, shadowMask);
            }

            v2f vert(a2v v)
            {
                v2f o;
                o.uv = v.uv;
                o.vertexWS = mul(UNITY_MATRIX_M, v.vertexOS);
                o.vertexCS = mul(UNITY_MATRIX_VP, o.vertexWS);
                o.vertexSS = ComputeScreenPos(o.vertexCS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                
                // TRANSFER_SHADOW(o)

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 lighting = 0;

                float3 normalWS = normalize(i.normalWS);
                float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - i.vertexWS.xyz);
                float shadowMask = tex2D(
                    _ShadowTex,
                    //i.vertexCS.xy / i.vertexCS.w * _ShadowTex_ST.xy + _ShadowTex_ST.zw
                    i.uv * _ShadowTex_ST.xy + _ShadowTex_ST.zw
                ).r;

                // Main light
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(i.vertexWS.xyz));
                lighting += CalculateCelLighting(
                    mainLight,
                    normalWS,
                    viewDirWS,
                    shadowMask
                );

                // Specular
                float specular = frac(dot(mainLight.direction, viewDirWS));
                specular = step(_SpecularThreshold, specular);

                // Extra light
                InputData inputData = (InputData)0;
                inputData.positionWS = i.vertexWS.xyz;
                inputData.normalWS = normalWS;
                inputData.viewDirectionWS = viewDirWS;
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(i.vertexCS);

                #if defined(_ADDITIONAL_LIGHTS)
                    uint lightCount = GetAdditionalLightsCount();

                    LIGHT_LOOP_BEGIN(lightCount)
                        Light l = GetAdditionalLight(
                            lightIndex,
                            i.vertexWS.xyz,
                            half4(1, 1, 1, 1)
                        );

                        lighting += CalculateCelLighting(
                            l,
                            normalWS,
                            viewDirWS,
                            shadowMask
                        );
                    LIGHT_LOOP_END

                    lighting.w /= (1 + lightCount);
                #endif

                // Get ambient
                float3 ambient = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);

                float3 celShadeCol = (lighting.rgb + ambient * (_AmbientStrength + lighting.w)) * _MainColor;
                return lerp(float4(1, 1, 1, 1), float4(celShadeCol, _Alpha), specular);
            }

            ENDHLSL
        }

        // // Outline
        // Pass
        // {
        //     Name "OutlinePass"

        //     Cull Front

        //     HLSLPROGRAM
        //     #pragma vertex vert_outline
        //     #pragma fragment frag_outline

        //     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        //     struct a2v
        //     {
        //         float4 vertexOS : POSITION;
        //         float3 normalOS : NORMAL;
        //     };

        //     struct v2f
        //     {
        //         float4 vertexCS : SV_POSITION;
        //     };

        //     float _OutlineWidth;

        //     v2f vert_outline(a2v v)
        //     {
        //         v2f o;
        //         o.vertexCS = mul(UNITY_MATRIX_MVP, v.vertexOS);

        //         float3 normal = TransformWorldToViewDir(TransformObjectToWorldNormal(normalize(v.normalOS)));
        //         o.vertexCS += float4(normal * _OutlineWidth * o.vertexCS.w, 0);

        //         return o;
        //     }

        //     float4 frag_outline(v2f i) : SV_Target
        //     {
        //         return float4(0, 0, 0, 1);
        //     }
        //     ENDHLSL

        // }

        // //// Shadow
        // //UsePass "VertexLit/SHADOWCASTER"
        // Pass
        // {
        //     Name "ShadowCaster"
        //     Tags{ "LightMode" = "ShadowCaster" }

        //     HLSLPROGRAM

        //     #pragma vertex vert_shadow
        //     #pragma fragment frag_shadow

        //     #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

        //     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        //     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
        //     float3 _LightDirection;
        //     float3 _LightPosition;

        //     struct a2v
        //     {
        //         float4 positionOS : POSITION;
        //         float3 normalOS   : NORMAL;
        //     };

        //     struct v2f
        //     {
        //         float4 positionCS : SV_POSITION;
        //     };

        //     v2f vert_shadow(a2v v)
        //     {
        //         v2f o;

        //         float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);

        //         float3 normalWS = TransformObjectToWorldNormal(v.normalOS);

        //         float3 lightDirWS;

        //         #if _CASTING_PUNCTUAL_LIGHT_SHADOW
        //             lightDirWS = normalize(_LightPosition - positionWS);
        //         #else
        //             lightDirWS = _LightDirection;
        //         #endif

        //         positionWS = ApplyShadowBias(
        //             positionWS,
        //             normalWS,
        //             lightDirWS
        //         );

        //         o.positionCS = TransformWorldToHClip(positionWS);
        //         o.positionCS = ApplyShadowClamping(o.positionCS);

        //         return o;
        //     }

        //     float4 frag_shadow(v2f i) : SV_Target
        //     {
        //         return 0;
        //     }
        //     ENDHLSL
        // }
    }
}
