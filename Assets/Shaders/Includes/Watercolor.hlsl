#include "Assets/Shaders/Includes/Noise.hlsl"
void ChooseColor_float(float3 Highlight, float3 Midtone, float3 Shadow, float Diffuse, float2 Thresholds, out float3 OUT)
{
    if (Diffuse < Thresholds.x)
    {
        OUT = Shadow;
    }
    else if (Diffuse < Thresholds.y)
    {
        OUT = Midtone;
    }
    else
    {
        OUT = Highlight;
    }
}

float Gradient3D(float3 Pos)
{
    return GradientNoise(Pos.xy + cos(Pos.zz));
}
float NoiseFactory(float3 Pos, float Diffuse, float seed)
{
    float3 v2s = float3(321.41 * seed, 139.3*seed*sin(seed) + 13.1 * seed, cos(seed) + seed * 31.4);

    Diffuse += 0.1 *Gradient3D(0.4 * Pos + v2s) + 0.1 *Gradient3D(0.4 * (Pos + v2s + float3(0.2,0.0,0.)));
    return Diffuse;
}

void ChooseColorComplex_float(float3 Highlight, float3 Midtone, float3 Shadow, float Diffuse, float2 Thresholds, float3 WorldPos, out float3 OUT)
{
    float noise = Gradient3D(WorldPos);
    float DiffuseLow = max(smoothstep(0.8, 0.9, noise), NoiseFactory(WorldPos, Diffuse, 0.));
    float DiffuseHigh = max(smoothstep(0.6, 0.7, noise), NoiseFactory(WorldPos, Diffuse, 13.1));
    
    if (DiffuseLow < Thresholds.x)
    {
        OUT = Shadow * (1. - 0.07*smoothstep(0.85*Thresholds.x, Thresholds.x, DiffuseLow) * (smoothstep(0.0, .3,GradientNoise(1.5*WorldPos.xy))));
    }
    else if (DiffuseHigh < Thresholds.y)
    {
        OUT = Midtone * (1. - 0.07*smoothstep(0.85*Thresholds.x, Thresholds.x, DiffuseHigh));;
    }
    else
    {
        OUT = Highlight;
    }
}
float Bias(float t, float b)
{
    return pow(t, log(max(b, 1e-5)) / log(0.5));
}
float Gain(float t, float g)
{
    float s = step(0.5, t);
    float x = lerp(2.0 * t, 2.0 - 2.0 * t, s);
    float y = 0.5 * Bias(x, 1.0 - g);
    return lerp(y, 1.0 - y, s);
}

void ChooseColorAnimated_float(float3 Highlight, float3 Midtone, float3 Shadow, float Diffuse, float2 Thresholds, float3 WorldPos, float Time, out float3 OUT)
{
    float s = 0.9 * Time;
    Diffuse += (floor(s) + Gain(frac(s), 0.8)) / 3.0;
    Diffuse = frac(Diffuse);
    float DiffuseLow = NoiseFactory(WorldPos, Diffuse, 0.);
    float DiffuseHigh = NoiseFactory(WorldPos, Diffuse, 13.1);
    float window = smoothstep(0.0, 0.06, Diffuse) * smoothstep(1.0, 1.1*Thresholds.y, DiffuseLow);
    float lowM = smoothstep(0.8*Thresholds.x, Thresholds.x, DiffuseLow) * window;
    float highM = smoothstep(0.8*Thresholds.y, Thresholds.y, DiffuseHigh);
    float darkenEdge = (1. - 0.07*smoothstep(0.85*Thresholds.x, Thresholds.x, DiffuseLow) * (smoothstep(0.2, 7.,GradientNoise(1.5*WorldPos.xy))));
    float3 CMax = lerp(Midtone, Highlight, highM);
    OUT = lerp(Shadow * darkenEdge, CMax, lowM);
}