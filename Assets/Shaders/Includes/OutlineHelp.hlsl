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


void DepthSobel_float(float2 UV, float Thickness, out float Out)
{
    float2 sobel = 0;

    float2 texelSize = 1.0 / _ScreenParams.xy;

    for (int i = 0; i < 9; i++)
    {
        float2 offset = sobelSamplePoints[i] * Thickness * texelSize;

        float depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV + offset);
        sobel += depth * float2(sobelXMatrix[i], sobelYMatrix[i]);
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

float3 SampleColorBlurred(float2 uv, float2 texelSize, float radius)
{
    float2 o = radius * texelSize;
    float3 c = 0;
    c += SAMPLE_TEXTURE2D(_MainTex, sampler_point_clamp, uv + float2(-o.x, -o.y)).rgb;
    c += SAMPLE_TEXTURE2D(_MainTex, sampler_point_clamp, uv + float2( o.x, -o.y)).rgb;
    c += SAMPLE_TEXTURE2D(_MainTex, sampler_point_clamp, uv + float2(-o.x,  o.y)).rgb;
    c += SAMPLE_TEXTURE2D(_MainTex, sampler_point_clamp, uv + float2( o.x,  o.y)).rgb;
    return c * 0.25;
}

void ColorSobel_float(float2 UV, float Thickness, float BlurRadius,
                      float EdgeMin, float EdgeMax, out float Out) {
    float2 sobelR = 0;
    float2 sobelG = 0;
    float2 sobelB = 0;

    float2 texelSize = 1.0 / _ScreenParams.xy;

    for (int i = 0; i < 9; i++) {
        float2 uv = UV + sobelSamplePoints[i] * Thickness * texelSize;
        float3 rgb = SampleColorBlurred(uv, texelSize, BlurRadius);

        float2 kernel = float2(sobelXMatrix[i], sobelYMatrix[i]);

        sobelR += rgb.r * kernel;
        sobelG += rgb.g * kernel;
        sobelB += rgb.b * kernel;
    }

    float edge = max(length(sobelR), max(length(sobelG), length(sobelB)));
    Out = smoothstep(EdgeMin, EdgeMax, edge);
}

void WobbleLine_float(float2 UV, float Time, float Amplitude, float Scale, float Speed, float Fps, out float2 Out)
{
    float2 texelSize = 1.0 / _ScreenParams.xy;

    float2 p = UV * _ScreenParams.xy * (6.2831853 / max(Scale, 1.0));
    float t = ((Fps > 0.0) ? floor(Time * Fps) / Fps : Time) * Speed;

    float x = sin(p.y + p.x * 0.7 + t) + 0.5 * sin(p.y * 2.3 - p.x * 1.1 - t * 1.3 + 1.7);
    float y = cos(p.x - p.y * 0.6 + t * 0.9) + 0.5 * cos(p.x * 2.1 + p.y * 1.7 - t * 1.1 + 4.2);
    float2 offset = float2(x, y) / 1.5; 

    Out = UV + offset * Amplitude * texelSize;
}

void GetDepth_float(float2 uv, out float Depth)
{
    Depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(uv);
}


void GetNormal_float(float2 uv, out float3 Normal)
{
    Normal = SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, uv).rgb;
}

#endif