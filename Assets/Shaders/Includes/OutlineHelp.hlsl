SAMPLER(sampler_point_clamp);

void GetDepth_float(float2 uv, out float Depth) {
    Depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(uv);
}


void GetNormal_float(float2 uv, out float3 Normal) {
    Normal = SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, uv).rgb;
}

// UV = screen position
// Texel size = 1/width, 1/height
void GetEdge_float(float4 UV, float DepthOffsetScale, float DepthEdgeScale, float NormalOffsetScale, float NormalEdgeScale,  out float DepthEdge, out float NormalEdge) {
    float2 texelSize = 1.f / _ScreenParams.xy;
    float2 uvTR = UV.xy + float2( texelSize.x,  texelSize.y) * DepthOffsetScale;
    float2 uvTL = UV.xy + float2(-texelSize.x,  texelSize.y) * DepthOffsetScale;    
    float2 uvBL = UV.xy + float2(-texelSize.x, -texelSize.y) * DepthOffsetScale;
    float2 uvBR = UV.xy + float2( texelSize.x, -texelSize.y) * DepthOffsetScale;

    // Depth Cross
    float depthTR = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(uvTR), _ZBufferParams);
    float depthTL = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(uvTL), _ZBufferParams);
    float depthBL = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(uvBL), _ZBufferParams);
    float depthBR = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(uvBR), _ZBufferParams);
    
    DepthEdge = length(float2(depthTR - depthBL, depthTL - depthBR)) * DepthEdgeScale;

    // Normal Cross
    uvTR = UV.xy + float2( texelSize.x,  texelSize.y) * NormalOffsetScale;
    uvTL = UV.xy + float2(-texelSize.x,  texelSize.y) * NormalOffsetScale;
    uvBL = UV.xy + float2(-texelSize.x, -texelSize.y) * NormalOffsetScale;
    uvBR = UV.xy + float2( texelSize.x, -texelSize.y) * NormalOffsetScale;
    
    float3 normalTR = SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, uvTR).rgb;
    float3 normalTL = SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, uvTL).rgb;
    float3 normalBL = SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, uvBL).rgb;
    float3 normalBR = SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, uvBR).rgb;

    NormalEdge = length(float2(length(normalTR - normalBL), length(normalTL - normalBR))) * NormalEdgeScale;
}