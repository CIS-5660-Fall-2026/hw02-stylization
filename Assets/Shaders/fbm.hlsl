#ifndef FBM_INCLUDED
#define FBM_INCLUDED

// iquilezles.org/articles/fbm/
float hash(float3 p)
{
    p = frac(p * 0.3183099 + 0.1);
    p *= 17.0;
    return frac(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(float3 x)
{
    float3 i = floor(x);
    float3 f = frac(x);
    f = f * f * (3.0 - 2.0 * f);

    return lerp(lerp(lerp(hash(i + float3(0,0,0)),
    hash(i + float3(1,0,0)), f.x),
    lerp(hash(i + float3(0,1,0)),
    hash(i + float3(1,1,0)), f.x), f.y),
    lerp(lerp(hash(i + float3(0,0,1)),
    hash(i + float3(1,0,1)), f.x),
    lerp(hash(i + float3(0,1,1)),
    hash(i + float3(1,1,1)), f.x), f.y), f.z);
}

void FBM_float(float3 x, float H, float numOctaves, out float Out)
{
    float G = exp2(-H);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    for (int i = 0; i < 8; i++)
    {
        if (i >= numOctaves) break;
        t += a * noise(f * x);
        f *= 2.0;
        a *= G;
    }
    Out = t;
}

#endif
