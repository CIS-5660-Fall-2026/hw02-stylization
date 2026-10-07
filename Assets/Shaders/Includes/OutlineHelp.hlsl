SAMPLER(sampler_point_clamp);

void GetDepth_float(float2 uv, out float Depth)
{
    Depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(uv);
}


void GetNormal_float(float2 uv, out float3 Normal)
{
    Normal = SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, uv).rgb;
}

void Outline_float(float2 uv, float Width, float DepthThreshold, float NormalThreshold, float WobbleAmount, float WobbleSpeed, out float DepthEdge, out float NormalEdge, out float Edge)
{
    DepthEdge = 0;
    NormalEdge = 0;
    Edge = 0;

#ifndef SHADERGRAPH_PREVIEW
    if (Width <= 0)
        return;

    float2 offset = 0.5 * Width / _ScreenParams.xy;

    float2 uv0 = saturate(uv + float2(-offset.x, -offset.y));
    float2 uv1 = saturate(uv + float2( offset.x,  offset.y));
    float2 uv2 = saturate(uv + float2(-offset.x,  offset.y));
    float2 uv3 = saturate(uv + float2( offset.x, -offset.y));

    //animation
    float t = floor(_Time.y * WobbleSpeed * 8.0) / 8.0;

    float2 wobble = float2(sin(uv.y * 80.0 + t * 2.0), cos(uv.x * 80.0 + t * 2.3));

    wobble *= WobbleAmount / _ScreenParams.xy;

    float d0, d1, d2, d3;
    GetDepth_float(saturate(uv0 + wobble), d0);
    GetDepth_float(saturate(uv1 + wobble), d1);
    GetDepth_float(saturate(uv2 + wobble), d2);
    GetDepth_float(saturate(uv3 + wobble), d3);
    
    d0 = LinearEyeDepth(d0, _ZBufferParams);
    d1 = LinearEyeDepth(d1, _ZBufferParams);
    d2 = LinearEyeDepth(d2, _ZBufferParams);
    d3 = LinearEyeDepth(d3, _ZBufferParams);

    float depthDifference = length(float2(d1 - d0, d3 - d2));

    float nearestDepth = max(min(min(d0, d1), min(d2, d3)), 0.0001);
    depthDifference /= nearestDepth;

    DepthEdge = step(max(DepthThreshold, 0.00001), depthDifference);

    float3 n0, n1, n2, n3;
    GetNormal_float(saturate(uv0 + wobble), n0);
    GetNormal_float(saturate(uv1 + wobble), n1);
    GetNormal_float(saturate(uv2 + wobble), n2);
    GetNormal_float(saturate(uv3 + wobble), n3);

    n0 = n0 * 2.0 - 1.0;
    n1 = n1 * 2.0 - 1.0;
    n2 = n2 * 2.0 - 1.0;
    n3 = n3 * 2.0 - 1.0;

    float3 differenceA = n1 - n0;
    float3 differenceB = n3 - n2;

    float normalDifference = sqrt(
        dot(differenceA, differenceA) +
        dot(differenceB, differenceB)
    );

    NormalEdge = step(max(NormalThreshold, 0.00001), normalDifference);

    Edge = max(DepthEdge, NormalEdge);
#endif
}