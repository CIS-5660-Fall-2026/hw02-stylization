SAMPLER(sampler_point_clamp);

void GetDepth_float(float2 uv, out float Depth)
{
    Depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(uv);
}


void GetNormal_float(float2 uv, out float3 Normal)
{
    Normal = SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, uv).rgb;
}

// Robert's Cross edge detection on the depth and normal buffers.
// Thickness is the outline width in pixels. DepthEdge and NormalEdge are 0 or 1.
void DetectEdges_float(float2 UV, float Thickness, float DepthThreshold, float NormalThreshold,
    out float DepthEdge, out float NormalEdge)
{
    DepthEdge = 0;
    NormalEdge = 0;

#ifndef SHADERGRAPH_PREVIEW
    float2 texel = Thickness * 0.5 / _ScreenParams.xy;

    // Robert's Cross compares the two diagonals of a small square
    float2 offsets[4] =
    {
        float2(-texel.x, texel.y),   // top left
        float2(texel.x, -texel.y),   // bottom right
        float2(texel.x, texel.y),    // top right
        float2(-texel.x, -texel.y)   // bottom left
    };

    float depths[4];
    float3 normals[4];
    for (int i = 0; i < 4; ++i)
    {
        float rawDepth;
        GetDepth_float(UV + offsets[i], rawDepth);
        depths[i] = LinearEyeDepth(rawDepth, _ZBufferParams);

        GetNormal_float(UV + offsets[i], normals[i]);
    }

    // Divide by the closest depth so far away surfaces are not all flagged as edges
    float depthDiff = length(float2(depths[0] - depths[1], depths[2] - depths[3]));
    float closest = min(min(depths[0], depths[1]), min(depths[2], depths[3]));
    DepthEdge = step(DepthThreshold, depthDiff / closest);

    float3 normalDiff0 = normals[0] - normals[1];
    float3 normalDiff1 = normals[2] - normals[3];
    NormalEdge = step(NormalThreshold, sqrt(dot(normalDiff0, normalDiff0) + dot(normalDiff1, normalDiff1)));
#endif
}