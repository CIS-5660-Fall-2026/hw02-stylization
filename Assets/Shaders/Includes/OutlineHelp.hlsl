SAMPLER(sampler_point_clamp);

void GetDepth_float(float2 uv, out float Depth)
{
    Depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(uv);
}


void GetNormal_float(float2 uv, out float3 Normal)
{
    Normal = SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, uv).rgb;
}

float OutlineHash21(float2 p)
{
    p = frac(p * float2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return frac(p.x * p.y);
}

float OutlineDepthSample(float2 uv)
{
    return SHADERGRAPH_SAMPLE_SCENE_DEPTH(saturate(uv));
}

float3 OutlineNormalSample(UnityTexture2D normalsBuffer, float2 uv)
{
    return SAMPLE_TEXTURE2D(normalsBuffer.tex, sampler_point_clamp, saturate(uv)).rgb * 2.0 - 1.0;
}

void SobelOutline_float(
    UnityTexture2D SourceTexture,
    UnityTexture2D NormalsBuffer,
    float2 UV,
    float4 OutlineColor,
    float OutlineWidth,
    float DepthThreshold,
    float NormalThreshold,
    float WobbleAmount,
    float WobbleStepsPerSecond,
    float WobbleSpatialFrequency,
    out float3 Color)
{
    float2 screenSize = max(_ScreenParams.xy, float2(1.0, 1.0));
    float2 texel = max(OutlineWidth, 0.0) / screenSize;

    float frame = floor(_TimeParameters.x * max(WobbleStepsPerSecond, 0.0));
    float bands = max(WobbleSpatialFrequency, 1.0);
    float row = floor(UV.y * bands);
    float column = floor(UV.x * bands);
    float2 jitter = float2(
        OutlineHash21(float2(row, frame + 11.0)),
        OutlineHash21(float2(column + 47.0, frame + 29.0))) * 2.0 - 1.0;
    jitter *= max(WobbleAmount, 0.0) / screenSize;

    float2 depthUV = UV + jitter;

    float d00 = OutlineDepthSample(depthUV + texel * float2(-1.0,  1.0));
    float d10 = OutlineDepthSample(depthUV + texel * float2( 0.0,  1.0));
    float d20 = OutlineDepthSample(depthUV + texel * float2( 1.0,  1.0));
    float d01 = OutlineDepthSample(depthUV + texel * float2(-1.0,  0.0));
    float d21 = OutlineDepthSample(depthUV + texel * float2( 1.0,  0.0));
    float d02 = OutlineDepthSample(depthUV + texel * float2(-1.0, -1.0));
    float d12 = OutlineDepthSample(depthUV + texel * float2( 0.0, -1.0));
    float d22 = OutlineDepthSample(depthUV + texel * float2( 1.0, -1.0));

    float depthGX = (d20 + 2.0 * d21 + d22) - (d00 + 2.0 * d01 + d02);
    float depthGY = (d02 + 2.0 * d12 + d22) - (d00 + 2.0 * d10 + d20);
    float depthEdge = sqrt(depthGX * depthGX + depthGY * depthGY);

    float3 n00 = OutlineNormalSample(NormalsBuffer, UV + texel * float2(-1.0,  1.0));
    float3 n10 = OutlineNormalSample(NormalsBuffer, UV + texel * float2( 0.0,  1.0));
    float3 n20 = OutlineNormalSample(NormalsBuffer, UV + texel * float2( 1.0,  1.0));
    float3 n01 = OutlineNormalSample(NormalsBuffer, UV + texel * float2(-1.0,  0.0));
    float3 n21 = OutlineNormalSample(NormalsBuffer, UV + texel * float2( 1.0,  0.0));
    float3 n02 = OutlineNormalSample(NormalsBuffer, UV + texel * float2(-1.0, -1.0));
    float3 n12 = OutlineNormalSample(NormalsBuffer, UV + texel * float2( 0.0, -1.0));
    float3 n22 = OutlineNormalSample(NormalsBuffer, UV + texel * float2( 1.0, -1.0));

    float3 normalGX = (n20 + 2.0 * n21 + n22) - (n00 + 2.0 * n01 + n02);
    float3 normalGY = (n02 + 2.0 * n12 + n22) - (n00 + 2.0 * n10 + n20);
    float normalEdge = sqrt(dot(normalGX, normalGX) + dot(normalGY, normalGY));

    float depthMask = step(max(DepthThreshold, 0.000001), depthEdge);
    float normalMask = step(max(NormalThreshold, 0.000001), normalEdge);
    float outlineMask = max(depthMask, normalMask);

    float3 sceneColor = SAMPLE_TEXTURE2D(SourceTexture.tex, SourceTexture.samplerstate, saturate(UV)).rgb;
    Color = lerp(sceneColor, OutlineColor.rgb, saturate(outlineMask * OutlineColor.a));
}
