Shader "Hidden/Edge Detection"
{
    Properties
    {
        _OutlineThickness ("Outline Thickness", Float) = 1
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque"
        }

        ZWrite Off
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass 
        {
            Name "EDGE DETECTION OUTLINE"
            
            HLSLPROGRAM
            #include "Assets/Shaders/Includes/Noise.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl" // needed to sample scene depth
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl" // needed to sample scene normals
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl" // needed to sample scene color/luminance

            CBUFFER_START(UnityPerMaterial)
                float _OutlineThickness;
                float4 _OutlineColor;
            CBUFFER_END

            #pragma vertex Vert 
            #pragma fragment frag

            float Sobel(float3 s[9])
            {
                // Horizontal gradient: kernel [-1 0 1; -2 0 2; -1 0 1]
                const float3 gx = (s[2] + 2.0 * s[5] + s[8]) - (s[0] + 2.0 * s[3] + s[6]);
                // Vertical gradient: kernel [-1 -2 -1; 0 0 0; 1 2 1]
                const float3 gy = (s[0] + 2.0 * s[1] + s[2]) - (s[6] + 2.0 * s[7] + s[8]);
                return sqrt(dot(gx, gx) + dot(gy, gy));
            }

            float Sobel(float s[9])
            {
                const float gx = (s[2] + 2.0 * s[5] + s[8]) - (s[0] + 2.0 * s[3] + s[6]);
                const float gy = (s[0] + 2.0 * s[1] + s[2]) - (s[6] + 2.0 * s[7] + s[8]);
                return sqrt(gx * gx + gy * gy);
            }
            
            
            float3 SampleSceneNormalsRemapped(float2 uv)
            {
                return SampleSceneNormals(uv) * 0.5 + 0.5;
            }

            float SampleSceneLuminance(float2 uv)
            {
                float3 color = SampleSceneColor(uv);
                return color.r * 0.3 + color.g * 0.59 + color.b * 0.11;
            }
            
            float edgeCalc(float2 uv, float offset)
            {
                float2 uvs[9];
                for (int y = 0; y < 3; y++)
                {
                    for (int x = 0; x < 3; x++)
                    {
                        uvs[y * 3 + x] = uv + offset * float2(x - 1, 1 - y);
                    }
                }
                
                float3 normal_samples[9];
                float depth_samples[9], luminance_samples[9];
                
                for (int i = 0; i < 9; i++) {
                    depth_samples[i] = SampleSceneDepth(uvs[i]);
                    normal_samples[i] = SampleSceneNormalsRemapped(uvs[i]);
                }
                
                float diffuse = 0.;
                float3 lightDirWS = normalize(_MainLightPosition.xyz);
                for (int i = 0; i < 9; i++)
                {
                    //Technically should sample normal_samples but idrk
                    float3 normalWS = SampleSceneNormals(uvs[i]); 
                    diffuse = max(diffuse,saturate(dot(normalWS, lightDirWS)));
                }
                
                float edge_depth = Sobel(depth_samples);
                float edge_normal = Sobel(normal_samples);
                
                float depth_threshold = 1 / 100.0f;
                edge_depth = edge_depth > depth_threshold ? 1 : 0;
                
                float normal_threshold = 1 / 2.0f;
                edge_normal = edge_normal > normal_threshold ? 1 : 0;
                
                
                float edge = max(edge_depth, edge_normal) * step(diffuse, 0.5);
                
                return edge;
            }
            
            half4 frag(Varyings IN) : SV_TARGET
            {
                float2 uv1 = WarpUV(IN.texcoord, _ScreenParams.xy, 10., 8., 0.);
                float2 uv2 = IN.texcoord;
                
                float2 texel_size = float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
                
                float2 offset = texel_size * _OutlineThickness;
                float noise = GradientNoise(IN.texcoord);
                float offset1 = offset * smoothstep(-0.2,-0.15,GradientNoise(uv1 + float2(1.5,3.5) * floor(_Time.y)));
                float offset2 =  (offset - offset1) * smoothstep(-0.05,-0.00,GradientNoise(uv2+float2(132.1,1.00413)* floor(_Time.y)));
                return (edgeCalc(uv2,offset2) + edgeCalc(uv1, offset1))* _OutlineColor;
            }
            ENDHLSL
        }
    }
}
