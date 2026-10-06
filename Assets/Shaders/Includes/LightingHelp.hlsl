void GetMainLight_float(float3 WorldPos, out float3 Color, out float3 Direction, out float DistanceAtten, out float ShadowAtten)
{
#ifdef SHADERGRAPH_PREVIEW
    Direction = normalize(float3(0.5, 0.5, 0));
    Color = 1;
    DistanceAtten = 1;
    ShadowAtten = 1;
#else
#if SHADOWS_SCREEN
        float4 clipPos = TransformWorldToClip(WorldPos);
        float4 shadowCoord = ComputeScreenPos(clipPos);
#else
    float4 shadowCoord = TransformWorldToShadowCoord(WorldPos);
#endif

    Light mainLight = GetMainLight(shadowCoord);
    Direction = mainLight.direction;
    Color = mainLight.color;
    DistanceAtten = mainLight.distanceAttenuation;
    ShadowAtten = mainLight.shadowAttenuation;
#endif
}

void ComputeAdditionalLighting_float(float3 WorldPosition, float3 WorldNormal,
    float2 Thresholds, float3 RampedDiffuseValues,
    out float3 Color, out float Diffuse)
{
    Color = float3(0, 0, 0);
    Diffuse = 0;

#ifndef SHADERGRAPH_PREVIEW

    int pixelLightCount = GetAdditionalLightsCount();
    
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, WorldPosition);
        float4 tmp = unity_LightIndices[i / 4];
        uint light_i = tmp[i % 4];

        half shadowAtten = light.shadowAttenuation * AdditionalLightRealtimeShadow(light_i, WorldPosition, light.direction);
        
        half NdotL = saturate(dot(WorldNormal, light.direction));
        half distanceAtten = light.distanceAttenuation;

        half thisDiffuse = distanceAtten * shadowAtten * NdotL;
        
        half rampedDiffuse = 0;
        
        if (thisDiffuse < Thresholds.x)
        {
            rampedDiffuse = RampedDiffuseValues.x;
        }
        else if (thisDiffuse < Thresholds.y)
        {
            rampedDiffuse = RampedDiffuseValues.y;
        }
        else
        {
            rampedDiffuse = RampedDiffuseValues.z;
        }

        
        if (light.distanceAttenuation <= 0)
        {
            rampedDiffuse = 0.0;
        }

        Color += max(rampedDiffuse, 0) * light.color.rgb;
        Diffuse += rampedDiffuse;
    }
    
    if (Diffuse <= 0.3)
    {
        Color = float3(0, 0, 0);
        Diffuse = 0;
    }
    
#endif
}

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

void ChooseColorWMidtone_float(float3 Highlight, float3 Shadow, float Diffuse, float HighlightThreshold, float3 Midtone, float MidtoneThreshold, out float3 OUT)
{
    if (Diffuse > HighlightThreshold)
    {
        OUT = Highlight;
    }
    else if (Diffuse > MidtoneThreshold)
    {
        OUT = Midtone;
    }
    else
    {
        OUT = Shadow;
    }
}


void RimHighlight_float(float3 WorldNormal, float3 ViewDir, float Diffuse, float RimThreshold, out float Rim)
{
    float3 N = normalize(WorldNormal);
    float3 V = normalize(ViewDir);

    float fresnel = 1 - saturate(dot(N, V));

    fresnel = step(RimThreshold, fresnel);

    Rim = fresnel * step(0.01, Diffuse);
}

void ToonSpecular_float(float3 WorldNormal, float3 ViewDir, float3 LightDir, float Diffuse, float SpecSize, out float Spec)
{
    float3 N = normalize(WorldNormal);
    float3 V = normalize(ViewDir);
    float3 L = normalize(LightDir);

    float3 H = normalize(L + V);
    float NdotH = saturate(dot(N, H));

    Spec = step(1 - SpecSize, NdotH) * step(0.01, Diffuse);
}

// Hand drawn style glint: a crescent that runs parallel to the silhouette, a bit inside it,
// on the side facing GlintDir.
// GlintOffset: where the crescent sits, 1 = on the silhouette, smaller = further inside
// GlintWidth:  how thick it is
// GlintLength: how far it reaches around the side, 0..1
void EdgeGlint_float(float3 WorldNormal, float3 ViewDir, float3 GlintDir,
    float GlintOffset, float GlintWidth, float GlintLength, out float Glint)
{
    float3 N = normalize(WorldNormal);
    float3 V = normalize(ViewDir);
    float3 G = normalize(GlintDir);

    float edge = 1 - saturate(dot(N, V));   // 1 at the silhouette, 0 facing the camera
    float facing = saturate(dot(N, G));     // 1 where the surface faces GlintDir

    // 1 in the middle of the band, falling to 0 at its borders
    float band = saturate(1 - abs(edge - GlintOffset) / GlintWidth);
    // 1 where the surface fully faces GlintDir, 0 at the ends of the crescent
    float reach = saturate((facing - (1 - GlintLength)) / GlintLength);

    // Multiplying the two makes the band thin out towards its ends
    Glint = step(0.5, band * reach);
}
