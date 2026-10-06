#ifndef SKETCH_JITTER_INCLUDED
#define SKETCH_JITTER_INCLUDED

float SketchHash13_float(float3 value)
{
    value = frac(value * 0.1031);
    value += dot(value, value.yzx + 33.33);
    return frac((value.x + value.y) * value.z);
}


void SketchJitter_float(float3 PositionOS, float3 NormalOS,
    float Amplitude, float StepsPerSecond, float SpatialFrequency, out float3 PositionOut)
{
    float safeSteps = max(StepsPerSecond, 0.0);
    float frame = floor(_TimeParameters.x * safeSteps);
    float safeFrequency = max(SpatialFrequency, 0.001);
    float3 spatialCell = floor(PositionOS * safeFrequency);
    float3 animatedSeed = spatialCell + frame * float3(17.17, 59.41, 15.97);
    float noise = SketchHash13_float(animatedSeed) * 2.0 - 1.0;

    float3 normalOS = normalize(NormalOS);
    PositionOut = PositionOS + normalOS * noise * max(Amplitude, 0.0);
}

#endif
