SAMPLER(sampler_point_clamp);

void GetDepth_float(float2 uv, out float Depth)
{
    Depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(uv);
}


void GetNormal_float(float2 uv, out float3 Normal)
{
    Normal = SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, uv).rgb;
}

float RobertsCross(float3 samples[4])
{
    const float3 difference_1 = samples[1] - samples[2];
    const float3 difference_2 = samples[0] - samples[3];
    return sqrt(dot(difference_1, difference_1) + dot(difference_2, difference_2));
}

float RobertsCross(float samples[4])
{
    const float difference_1 = samples[1] - samples[2];
    const float difference_2 = samples[0] - samples[3];
    return sqrt(difference_1 * difference_1 + difference_2 * difference_2);
}

void DetectEdge_float(float2 uv, float Thickness, float DepthThreshold,
    float NormalThreshold, out float Edge)
{
    float2 texel = Thickness / _ScreenParams.xy;
    float2 offsets[4] = {
        float2(-1, 1),
        float2(1, 1),
        float2(-1, -1),
        float2(1, -1)
    };

    float depths[4];
    float3 normals[4];
    for (int i = 0; i < 4; i++)
    {
        float2 sampleUV = uv + offsets[i] * texel;
        depths[i] = SHADERGRAPH_SAMPLE_SCENE_DEPTH(sampleUV);
        normals[i] = SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, sampleUV).rgb;
    }

    float depthEdge = step(DepthThreshold, RobertsCross(depths));
    float normalEdge = step(NormalThreshold, RobertsCross(normals));
    Edge = max(depthEdge, normalEdge);
}