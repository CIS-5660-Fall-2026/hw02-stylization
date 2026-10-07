//Imported noise functions
float2 Hash22(float2 p)
{
    p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
    return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
}

float2 Noise22(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    float2 u = f * f * (3.0 - 2.0 * f);

    float2 a = Hash22(i);
    float2 b = Hash22(i + float2(1.0, 0.0));
    float2 c = Hash22(i + float2(0.0, 1.0));
    float2 d = Hash22(i + float2(1.0, 1.0));

    return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
}

float2 WarpUV(float2 uv, float2 resolution, float frequency, float amplitudePixels, float seed)
{
    float aspect = resolution.x / resolution.y;
    float2 p = uv * float2(frequency * aspect, frequency) + seed;

    float2 n = Noise22(p) + 0.5 * Noise22(p * 2.3 + 17.0);

    return clamp(uv + n * (amplitudePixels / resolution), 0.0, 1.0);
}

float2 GradientHash(float2 p)
{
    p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
    float2 g = -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
    return normalize(g + 1e-5);
}

float GradientNoise(float2 p)
{
    p = 13.31*p;
    float2 i = floor(p);
    float2 f = frac(p);
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    float a = dot(GradientHash(i), f);
    float b = dot(GradientHash(i + float2(1.0, 0.0)), f - float2(1.0, 0.0));
    float c = dot(GradientHash(i + float2(0.0, 1.0)), f - float2(0.0, 1.0));
    float d = dot(GradientHash(i + float2(1.0, 1.0)), f - float2(1.0, 1.0));

    return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y) * 1.4142;
}