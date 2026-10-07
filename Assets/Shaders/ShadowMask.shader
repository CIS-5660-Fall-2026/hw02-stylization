Shader "Custom/ShadowMask"
{
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // needed so shadowAttenuation reads the real shadow map
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
            };

            struct vout
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
            };

            vout vert(appdata v)
            {
                vout o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS   = TransformObjectToWorldNormal(v.normalOS);
                return o;
            }

            float4 frag(vout i) : SV_Target
            {
                Light light = GetMainLight(TransformWorldToShadowCoord(i.positionWS));

                float NdotL  = dot(normalize(i.normalWS), light.direction);
                float facing = smoothstep(0.0, 0.99, NdotL);
                float lit  = lerp(1.0, light.shadowAttenuation, facing); // surfaces facing away from light are 1 to avoid artifcating

                return float4(lit.xxx, 1);
            }
            ENDHLSL
        }
    }
}