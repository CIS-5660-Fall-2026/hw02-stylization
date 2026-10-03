SAMPLER(sampler_point_clamp);

void GetDepth_float(float2 uv, out float Depth)
{
    Depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(uv);
}

void GetNormal_float(float2 uv, out float3 Normal)
{
    Normal = SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, uv).rgb;

}

float GetDepth(float2 uv)
{
    return SHADERGRAPH_SAMPLE_SCENE_DEPTH(uv);
}


float4 GetNormal(float2 uv)
{
    return SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, uv);
}

void GetCrossSampleUVs_float(float4 UV, float2 TexelSize, float OffsetMultiplier, 
    out float2 UVOriginal, out float2 UVTopRight, out float2 UVBottomLeft, 
    out float2 UVTopLeft, out float2 UVBottomRight)
{
    UVOriginal = UV;

    UVTopRight = UV.xy + float2(TexelSize.x, TexelSize.y) * OffsetMultiplier;

    UVBottomLeft = UV.xy - float2(TexelSize.x, TexelSize.y) * OffsetMultiplier;

    UVTopLeft = UV.xy + float2(-TexelSize.x * OffsetMultiplier,
        TexelSize.y * OffsetMultiplier);

    UVBottomRight = UV.xy + float2(TexelSize.x * OffsetMultiplier,
        -TexelSize.y * OffsetMultiplier);
}

void RobertsCrossDepth_float(float2 UVTopRight, float2 UVBottomLeft, 
    float2 UVTopLeft, float2 UVBottomRight, 
    out float Out)
{
#if defined(SHADERGRAPH_PREVIEW)
    Out = 0.0;
#else
    float difference0 = GetDepth(UVTopRight) - GetDepth(UVBottomLeft);
    float difference1 = GetDepth(UVTopLeft) - GetDepth(UVBottomRight);

    float robertsCross = sqrt(difference0 * difference0 + difference1 * difference1);

    Out = robertsCross * _RobertsCrossMultiplier;
#endif
}

void RobertsCrossNormals_float(float2 UVTopRight, float2 UVBottomLeft,
    float2 UVTopLeft, float2 UVBottomRight, 
    out float Out)
{
#if defined(SHADERGRAPH_PREVIEW)
    Out = 0.0;
#else
    float4 normalTopRight = GetNormal(UVTopRight);
    float4 normalBottomLeft = GetNormal(UVBottomLeft);
    float4 normalTopLeft = GetNormal(UVTopLeft);
    float4 normalBottomRight = GetNormal(UVBottomRight);

    float3 difference0 = normalTopRight.rgb - normalBottomLeft.rgb;
    float3 difference1 = normalTopLeft.rgb - normalBottomRight.rgb;

    float gradient0 = dot(difference0, difference0);
    float gradient1 = dot(difference1, difference1);

    Out = sqrt(gradient0 + gradient1);
#endif
}