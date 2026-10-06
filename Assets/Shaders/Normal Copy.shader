Shader "Hidden/Normal Copy"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Includes/AnimationHelp.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 viewNormal : NORMAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            // Same parameters as the toonShaderFloat graph. Materials without them read 0, so they do not move.
            float _BobAmplitude;
            float _BobSpeed;
            float _SwayAmplitude;
            float _SwaySpeed;

            v2f vert(appdata v)
            {
                v2f o;

                // Apply the same world space float as the balloon's vertex shader so the normals line up
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                BalloonFloat_float(worldPos, _Time.y, _BobAmplitude, _BobSpeed, _SwayAmplitude, _SwaySpeed, worldPos);
                o.vertex = mul(UNITY_MATRIX_VP, float4(worldPos, 1));

                o.viewNormal = COMPUTE_VIEW_NORMAL;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return float4(normalize(i.viewNormal) * 0.5 + 0.5, 0);
            }
            ENDCG
        }
    }
}
