#ifndef STARBURST_HELP_INCLUDED
#define STARBURST_HELP_INCLUDED

// Comic-ink starburst background + speed-line vignette.
// Used from a Fullscreen Shader Graph via a Custom Function node (File mode,
// function name "StarburstVignette").
//
//  - Background pixels (scene depth at the far plane) are replaced with a
//    radial burst of zigzag ink spikes, some solid and some hatched.
//  - The whole frame gets a jagged comic-panel vignette made of radial
//    speed lines that thicken into solid ink toward the edges.
//  - Everything "boils" (re-randomizes slightly) at BoilFps for a hand-drawn feel.

#define SB_TAU 6.28318530718

float SB_Hash11(float n) { return frac(sin(n * 127.1 + 0.123) * 43758.5453); }

// Triangle wave: 0 at integers, 1 at half-integers.
float SB_Tri(float x) { return abs(frac(x + 0.5) - 0.5) * 2.0; }

// Antialiased step. 0 below edge, 1 above; w = half the blur width in x's units.
float SB_AAStep(float edge, float x, float w)
{
    w = max(w, 1e-5);
    return smoothstep(edge - w, edge + w, x);
}

void StarburstVignette_float(
    float2 UV,            // Screen Position (Default), 0..1
    float3 SceneColor,    // URP Sample Buffer (Blit Source)
    float  RawDepth,      // Scene Depth (Raw)
    float2 Center,        // burst center in screen UV
    float  Time,
    float3 InkColor,
    float3 PaperColor,
    // --- burst ---
    float  RayCount,      // number of spikes around the circle
    float  ClearRadius,   // empty paper radius around the center (screen heights)
    float  ZigFreq,       // zigzags per screen height along each spike
    float  ZigAmp,        // zigzag sideways amount, in spike widths
    float  HatchDensity,  // hatch lines per screen height inside hatched spikes
    float  BoilFps,       // hand-drawn jitter rate (0 = static)
    // --- vignette ---
    float  VigInner,      // where speed lines start (1 = screen edge midpoints)
    float  VigOuter,      // where it becomes solid ink
    float  VigSpikes,     // number of jagged teeth on the inner edge
    float  VigSpikeAmp,   // how far the teeth poke inward
    float  VigLineCount,  // number of speed lines around the frame
    out float3 Color,
    out float  BackgroundMask)
{
    float aspect = _ScreenParams.x / _ScreenParams.y;

    // ---------- boil ----------
    float frame  = (BoilFps > 0.0) ? floor(Time * BoilFps) : 0.0;
    float boilA  = SB_Hash11(frame);
    float boilB  = SB_Hash11(frame + 31.7);

    // ---------- background mask ----------
    // Linear01Depth handles reversed-Z through _ZBufferParams.
    float lin01 = Linear01Depth(RawDepth, _ZBufferParams);
    BackgroundMask = step(0.9999, lin01);

    // ---------- starburst ----------
    float2 p   = (UV - Center) * float2(aspect, 1.0);   // aspect-correct, in screen heights
    float  r   = length(p);
    float  a   = atan2(p.y, p.x) / SB_TAU + 0.5;        // angle in turns, 0..1
    float  px  = length(fwidth(p));                      // ~1 pixel in p units (no atan seam)
    float  pxA = px / max(SB_TAU * r, 1e-4);             // ~1 pixel in turns at this radius

    float rays = max(round(RayCount), 1.0);

    // Zigzag the angle along the radius -> lightning-bolt edged spikes.
    float zig      = (SB_Tri(r * ZigFreq + boilA * 0.2) - 0.5) * ZigAmp;
    float rayCoord = a * rays + zig + (boilB - 0.5) * 0.08;
    float id       = fmod(floor(rayCoord) + rays * 4.0, rays);   // wrap so the seam matches
    float f        = frac(rayCoord);                              // 0..1 across this ray

    float h1 = SB_Hash11(id + 17.0);
    float h2 = SB_Hash11(id + 59.0);
    float h3 = SB_Hash11(id + 101.0 + frame * 0.37);              // boils

    // Spike width tapers to a point toward the center, each starting at its own radius.
    float tipR   = ClearRadius * lerp(1.0, 1.8, h1);
    float taper  = saturate((r - tipR) / max(ClearRadius * 1.5, 1e-3));
    float halfW  = lerp(0.18, 0.36, h3) * taper;

    float aaRay  = pxA * rays + px * ZigFreq * abs(ZigAmp) * 2.0;
    float inSpike = 1.0 - SB_AAStep(halfW, abs(f - 0.5), aaRay);

    // Half the spikes are solid ink, the rest are filled with concentric hatching.
    float hatchT  = SB_Tri(r * HatchDensity);
    float hatch   = 1.0 - SB_AAStep(0.45, hatchT, px * HatchDensity * 2.0);
    float fill    = (h2 < 0.5) ? 1.0 : hatch;

    float  burstInk   = inSpike * fill;
    float3 burstColor = lerp(PaperColor, InkColor, burstInk);

    Color = lerp(SceneColor, burstColor, BackgroundMask);

    // ---------- vignette ----------
    float2 q  = (UV - 0.5) * 2.0;                                   // -1..1 box
    float  vr = pow(pow(abs(q.x), 4.0) + pow(abs(q.y), 4.0), 0.25); // superellipse: hugs a panel
    float2 p0 = (UV - 0.5) * float2(aspect, 1.0);
    float  r0 = length(p0);
    float  va = atan2(p0.y, p0.x) / SB_TAU + 0.5;
    float  pxV = length(fwidth(p0)) / max(SB_TAU * r0, 1e-4);

    // Jagged inner edge: each tooth gets its own length.
    float spikes   = max(round(VigSpikes), 1.0);
    float sid      = fmod(floor(va * spikes) + spikes * 4.0, spikes);
    float toothLen = lerp(0.4, 1.0, SB_Hash11(sid + 7.0 + frame * 0.21));
    float inner    = VigInner - (1.0 - SB_Tri(va * spikes)) * VigSpikeAmp * toothLen;

    float t = saturate((vr - inner) / max(VigOuter - inner, 1e-3));

    // Radial speed lines that fatten with t until they merge into solid ink.
    float lines = max(round(VigLineCount), 1.0);
    float lc    = va * lines;
    float lid   = fmod(floor(lc) + lines * 4.0, lines);
    float tl    = t * lerp(0.6, 1.4, SB_Hash11(lid + 3.0 + frame * 0.13));
    float vigInk = 1.0 - SB_AAStep(tl, SB_Tri(lc), pxV * lines * 2.0);
    vigInk *= step(1e-4, t);                         // nothing inside the inner edge

    Color = lerp(Color, InkColor, vigInk);
}

#endif
