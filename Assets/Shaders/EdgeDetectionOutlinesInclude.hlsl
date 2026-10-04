SAMPLER(sampler_point_clamp);

#ifndef SOBELOUTLINES_INCLUDED
#define SOBELOUTLINES_INCLUDED

static float2 sobelSamplePoints[9] = {
    float2(-1, 1), float2(0, 1), float2(1, 1),
    float2(-1, 0), float2(0, 0), float2(1, 0),
    float2(-1, -1), float2(0, -1), float2(1, -1),
};

static float sobelXMatrix[9] = {
    1, 0, -1,
    2, 0, -2,
    1, 0, -1
};

static float sobelYMatrix[9] = {
    1, 2, 1,
    0, 0, 0,
    -1, -2, -1
};

void DepthSobel_float(float2 UV, float Thickness, out float Out) {
    float2 sobel = 0;
    
    float2 texelSize = 1.0 / _ScreenParams.xy;
    
    for (int i = 0; i < 9; i++) {
        float2 offset = sobelSamplePoints[i] * Thickness * texelSize;
        
        float rawDepth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV + offset);
        float linearDepth = Linear01Depth(rawDepth, _ZBufferParams);
        
        sobel += linearDepth * float2(sobelXMatrix[i], sobelYMatrix[i]);
    }

    Out = length(sobel);
}

void NormalSobel_float(float2 UV, float Thickness, out float Out) {
    float3 sobelX = 0;
    float3 sobelY = 0;

    float2 texelSize = 1.0 / _ScreenParams.xy;

    for (int i = 0; i < 9; i++) {
        float2 offset = sobelSamplePoints[i] * Thickness * texelSize;
        float3 normal = SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, UV + offset).rgb;
        
        sobelX += normal * sobelXMatrix[i];
        sobelY += normal * sobelYMatrix[i];
    }

    float3 sobel = sqrt(sobelX * sobelX + sobelY * sobelY);
    Out = length(sobel);
}

#endif