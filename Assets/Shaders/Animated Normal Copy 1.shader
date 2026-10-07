Shader "Hidden/Animated Normal Copy"
{
    Properties
    {
        _Animation_Speed ("Animation Speed", Float) = 10
        _Squish_Amount ("Squish Amount", Float) = 0.1
        _Bob_Height ("Bob Height", Float) = 0.05
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float _Animation_Speed;
            float _Squish_Amount;
            float _Bob_Height;

            #include "UnityCG.cginc"

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

            v2f vert(appdata v)
            {
                v2f o;

                float wave = sin(_Time.y * _Animation_Speed);

                float3 scale = float3(1.0 + wave * _Bob_Height, 1.0 + wave * _Squish_Amount, 1.0);
                
                v.vertex.xyz *= scale;
                v.normal = normalize(v.normal / scale);

                o.vertex = UnityObjectToClipPos(v.vertex);
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