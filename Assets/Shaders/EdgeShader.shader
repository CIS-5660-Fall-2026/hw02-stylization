Shader "Custom/EdgeShader"
{
	Properties
	{
        _NormalTex ("Normal Buffer", 2D) = "black" {}
        _ShadowBuffer ("Shadow Buffer", 2D) = "white" {}
        _EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
        _Thickness ("Thickness", Float) = 1.0
        _Threshold ("Threshold", Float) = 0.3

        // wiggle from hero shading
        _WiggleAmount ("Wiggle Amount", Float) = 0.002
        _WiggleFrequency ("Wiggle Frequency", Float) = 40.0
        _WiggleFPS ("Wiggle FPS", Float) = 8.0
	}
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertFullscreen // fullscreen vertex shader
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            float4 _NormalTex_TexelSize;

            TEXTURE2D(_ShadowBuffer);
            SAMPLER(sampler_ShadowBuffer);

            float4 _EdgeColor;
            float _Thickness;
            float _Threshold;

            float _WiggleAmount;
            float _WiggleFrequency;
            float _WiggleFPS;

            Varyings VertFullscreen(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
                return output;
            }

            // used to sample shadow buffer
            float S(float2 uv)
            {
                return SAMPLE_TEXTURE2D(_ShadowBuffer, sampler_ShadowBuffer, uv).r;
            }

            float3 N(float2 uv) // recieves normal from fullscreen buffer
            {
                return SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, uv).rgb;
            }

            float4 frag(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;
                float3 sceneColor = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, uv).rgb;

                // stepped random phase, fps dependent
                float frameIndex = floor(_Time.y * _WiggleFPS);
                float phase = frac(sin(frameIndex * 12.9898) * 43758.5453) * 6.2831;

                float2 wiggle = float2(sin(uv.y * _WiggleFrequency + phase),
                          cos(uv.x * _WiggleFrequency + phase)) * _WiggleAmount;
                float2 nuv = uv + wiggle;

                float2 o = _NormalTex_TexelSize.xy * _Thickness;

                // Roberts cross: compare the two diagonal pairs
                float normalEdge = length(N(nuv + float2(-o.x, -o.y)) - N(nuv + float2( o.x,  o.y)))
                           + length(N(nuv + float2( o.x, -o.y)) - N(nuv + float2(-o.x,  o.y)));

                float shadowEdge = abs(S(nuv + float2(-o.x, -o.y)) - S(nuv + float2( o.x,  o.y)))
                 + abs(S(nuv + float2( o.x, -o.y)) - S(nuv + float2(-o.x,  o.y)));

                float edge = max(step(_Threshold, normalEdge), step(0.5, shadowEdge));
                return float4(lerp(sceneColor, _EdgeColor.rgb, edge), 1.0);
            }
            ENDHLSL
        }
    }
}
