// Depth and normal outline mask for the existing full-screen outline graph.
#ifndef HW02_DEPTH_OUTLINE_INCLUDED
#define HW02_DEPTH_OUTLINE_INCLUDED

#ifndef SHADERGRAPH_PREVIEW
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#endif

void DepthAndNormalOutline_float(float2 UV, float Width, float Threshold, float NormalEdge, out float Edge)
{
#ifdef SHADERGRAPH_PREVIEW
Edge = NormalEdge;
#else
// Roberts Cross on four diagonal depth samples. Match the existing UV width,
// correcting the vertical offset for screen aspect ratio.
float2 offset = max(abs(Width), 0.000001) * 0.5 * float2(1.0, _ScreenParams.x / _ScreenParams.y);
float4 rawDepth = float4(
    SampleSceneDepth(saturate(UV + float2(-offset.x, -offset.y))),
    SampleSceneDepth(saturate(UV + float2( offset.x,  offset.y))),
    SampleSceneDepth(saturate(UV + float2(-offset.x,  offset.y))),
    SampleSceneDepth(saturate(UV + float2( offset.x, -offset.y))));
float4 eyeDepth;
if (unity_OrthoParams.w > 0.5)
{
    eyeDepth = float4(LinearDepthToEyeDepth(rawDepth.x), LinearDepthToEyeDepth(rawDepth.y),
                      LinearDepthToEyeDepth(rawDepth.z), LinearDepthToEyeDepth(rawDepth.w));
}
else
{
    eyeDepth = float4(LinearEyeDepth(rawDepth.x, _ZBufferParams), LinearEyeDepth(rawDepth.y, _ZBufferParams),
                      LinearEyeDepth(rawDepth.z, _ZBufferParams), LinearEyeDepth(rawDepth.w, _ZBufferParams));
}
float nearestDepth = max(min(min(eyeDepth.x, eyeDepth.y), min(eyeDepth.z, eyeDepth.w)), 0.0001);
float relativeDifference = length(float2(eyeDepth.x - eyeDepth.y, eyeDepth.z - eyeDepth.w)) / nearestDepth;
float depthEdge = step(max(Threshold, 0.00001), relativeDifference);
Edge = saturate(max(NormalEdge, depthEdge));
#endif
}

#endif
