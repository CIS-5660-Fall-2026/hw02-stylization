#ifndef OUTLINE_INCLUDED
#define OUTLINE_INCLUDED

void GetCrossSampleUVs_float(float4 UV, float2 TexelSize, float OffsetMultiplier,
    out float2 UVOriginal, out float2 UVTopRight, out float2 UVBottomLeft,
    out float2 UVTopLeft, out float2 UVBottomRight)
{
    UVOriginal = UV.xy;
    UVTopRight = UV.xy + float2(TexelSize.x, TexelSize.y) * OffsetMultiplier;
    UVBottomLeft = UV.xy - float2(TexelSize.x, TexelSize.y) * OffsetMultiplier;
    UVTopLeft = UV.xy + float2(-TexelSize.x * OffsetMultiplier, TexelSize.y * OffsetMultiplier);
    UVBottomRight = UV.xy + float2(TexelSize.x * OffsetMultiplier, -TexelSize.y * OffsetMultiplier);
}

void RobertsCross_float(float3 TopRight, float3 BottomLeft, float3 TopLeft, float3 BottomRight, out float Edge)
{
    float3 a = TopRight - BottomLeft;
    float3 b = TopLeft - BottomRight;
    Edge = sqrt(dot(a, a) + dot(b, b));
}

void AspectCorrectUV_float(float4 ScreenPos, out float2 UV)
{
    UV = ScreenPos.xy * float2(_ScreenParams.x / _ScreenParams.y, 1.0);
}

#endif