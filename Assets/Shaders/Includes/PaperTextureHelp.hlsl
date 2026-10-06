#ifndef PAPER_TEXTURE_HELP_INCLUDED
#define PAPER_TEXTURE_HELP_INCLUDED

void PaperTexture_float(
    UnityTexture2D SourceTexture,
    UnityTexture2D PaperTexture,
    float2 UV,
    float PaperScale,
    float PaperStrength,
    float4 PaperTint,
    float Desaturation,
    UnityTexture2D VignetteTexture,
    float VignetteStrength,
    float PhotoContrast,
    out float3 Color)
{
    float2 screenSize = max(_ScreenParams.xy, float2(1.0, 1.0));
    float2 paperUV = UV;
    paperUV.x *= screenSize.x / screenSize.y;
    paperUV *= max(PaperScale, 0.001);
    paperUV = 1.0 - abs(frac(paperUV * 0.5) * 2.0 - 1.0);

    float3 sceneColor = SAMPLE_TEXTURE2D(SourceTexture.tex, SourceTexture.samplerstate, saturate(UV)).rgb;
    float3 paperSample = SAMPLE_TEXTURE2D(PaperTexture.tex, PaperTexture.samplerstate, paperUV).rgb;
    float paperLuminance = dot(paperSample, float3(0.2126, 0.7152, 0.0722));

    float paperVariation = (paperLuminance - 0.5) * 2.0;
    float modulation = 1.0 + paperVariation * saturate(PaperStrength);
    float3 result = max(sceneColor * modulation, 0.0);

    float luminance = dot(result, float3(0.2126, 0.7152, 0.0722));
    result = lerp(result, luminance.xxx, saturate(Desaturation));

    result = lerp(result, result * PaperTint.rgb, saturate(PaperTint.a));

    result = saturate((result - 0.5) * max(PhotoContrast, 0.0) + 0.5);

    float3 vignetteSample = SAMPLE_TEXTURE2D(
        VignetteTexture.tex,
        VignetteTexture.samplerstate,
        saturate(UV)).rgb;
    float vignetteMask = dot(vignetteSample, float3(0.2126, 0.7152, 0.0722));
    result *= lerp(1.0, vignetteMask, saturate(VignetteStrength));

    Color = saturate(result);
}

#endif
