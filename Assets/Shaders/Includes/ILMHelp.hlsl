#ifndef ILM_HELP_INCLUDED
#define ILM_HELP_INCLUDED

void ToonILMRamp_float(
    float3 BaseColor,
    float4 ILM,
    UnityTexture2D Ramp,
    float NdotL,
    float ShadowAtten,
    out float3 ToonColor,
    out float ShadowMask)
{
    float row = 2.0;
    if (ILM.a <= 0.85) row = 5.0;
    if (ILM.a <= 0.60) row = 1.0;
    if (ILM.a <= 0.40) row = 4.0;
    if (ILM.a <= 0.15) row = 3.0;

    float rampV = 1.0 - (row * 0.1 - 0.05);

    float halfLambert = saturate(NdotL) * 0.5 + 0.5;
    halfLambert *= halfLambert;

    float lit = smoothstep(0.42, 0.46, halfLambert);
    float rampU = clamp(
        smoothstep(0.0, 0.35, halfLambert),
        0.003,
        0.997
    );

    float3 midRamp = SAMPLE_TEXTURE2D_LOD(
        Ramp.tex,
        Ramp.samplerstate,
        float2(rampU, rampV),
        0
    ).rgb;

    float3 darkRamp = SAMPLE_TEXTURE2D_LOD(
        Ramp.tex,
        Ramp.samplerstate,
        float2(0.003, rampV),
        0
    ).rgb;

    float3 midColor = BaseColor * midRamp;
    float3 darkColor = BaseColor * darkRamp;

    float keepLighting = saturate(ILM.g * 2.0);
    float forceBright = saturate((ILM.g - 0.5) * 2.0);

    float3 diffuse = lerp(midColor, BaseColor, lit);
    diffuse = lerp(darkColor, diffuse, keepLighting);
    diffuse = lerp(diffuse, BaseColor, forceBright);

    float visibility = saturate(ShadowAtten);
    ToonColor = lerp(darkColor, diffuse, visibility);

    float effectiveLit = lerp(
        lit * keepLighting,
        1.0,
        forceBright
    );

    ShadowMask = 1.0 - effectiveLit * visibility;
}

#endif