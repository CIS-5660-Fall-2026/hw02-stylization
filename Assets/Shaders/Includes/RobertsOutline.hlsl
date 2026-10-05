#ifndef ROBERTS_OUTLINE_INCLUDED
#define ROBERTS_OUTLINE_INCLUDED

void RobertsOutline_float(
    float2 UV,
    UnityTexture2D NormalTex,
    float Width,
    float DepthThreshold,
    float NormalThreshold,
    out float Edge)
{
    float t = floor(_Time.y * 6.0) / 6.0;

    float2 wobble = float2(sin(UV.y * 31.0 + t * 1.8),cos(UV.x * 63.0 + t * 1.2));

    UV += wobble * NormalTex.texelSize.xy * 1.0;

    float2 offset = NormalTex.texelSize.xy * max(Width, 0.0) * 0.5;

    float2 p0 = saturate(UV + float2(-offset.x, -offset.y));
    float2 p1 = saturate(UV + float2( offset.x, -offset.y));
    float2 p2 = saturate(UV + float2(-offset.x,  offset.y));
    float2 p3 = saturate(UV + float2( offset.x,  offset.y));

    float d0 = LinearEyeDepth(
        SHADERGRAPH_SAMPLE_SCENE_DEPTH(p0), _ZBufferParams);
    float d1 = LinearEyeDepth(
        SHADERGRAPH_SAMPLE_SCENE_DEPTH(p1), _ZBufferParams);
    float d2 = LinearEyeDepth(
        SHADERGRAPH_SAMPLE_SCENE_DEPTH(p2), _ZBufferParams);
    float d3 = LinearEyeDepth(
        SHADERGRAPH_SAMPLE_SCENE_DEPTH(p3), _ZBufferParams);

    float3 n0 = SAMPLE_TEXTURE2D_LOD(
        NormalTex.tex, NormalTex.samplerstate, p0, 0).rgb;
    float3 n1 = SAMPLE_TEXTURE2D_LOD(
        NormalTex.tex, NormalTex.samplerstate, p1, 0).rgb;
    float3 n2 = SAMPLE_TEXTURE2D_LOD(
        NormalTex.tex, NormalTex.samplerstate, p2, 0).rgb;
    float3 n3 = SAMPLE_TEXTURE2D_LOD(
        NormalTex.tex, NormalTex.samplerstate, p3, 0).rgb;

    float depthDifference = length(float2(d0 - d3, d1 - d2));

    float nearestDepth = max(min(min(d0, d1), min(d2, d3)), 0.001);
    depthDifference /= nearestDepth;

    float3 normalDifference0 = n0 - n3;
    float3 normalDifference1 = n1 - n2;
    float normalDifference = sqrt(
        dot(normalDifference0, normalDifference0) +
        dot(normalDifference1, normalDifference1)
    );

    float depthEdge = step(
        max(DepthThreshold, 0.00001), depthDifference);
    float normalEdge = step(
        max(NormalThreshold, 0.00001), normalDifference);

    Edge = max(depthEdge, normalEdge);

}
#endif
