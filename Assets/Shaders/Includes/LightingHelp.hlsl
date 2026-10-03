float EvaluateSpecular(float3 N, float3 L, float3 V, float Shininess, float SpecularThreshold)
{
    if (dot(N, L) <= 0)
    {
        return 0;
    }
    
    float3 LPlusV = L + V;
    float3 H = LPlusV * rsqrt(max(dot(LPlusV, LPlusV), 1e-6));
    float specular = pow(saturate(dot(N, H)), max(Shininess, 1.0));
    return step(SpecularThreshold, specular);
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

void ComputeMainLighting_float(float3 WorldPosition, float3 WorldNormal, float3 WorldViewDirection,
    float3 Highlight, float3 Midtone, float3 Shadow, float2 Thresholds, float ShadowPattern,
    float3 SpecularTint, float SpecularStrength, float Shininess, float SpecularThreshold,
    out float3 DiffuseColor, out float3 SpecularColor)
{
    float3 lightDirection;
    float3 lightColor;
    float distanceAtten;
    float shadowAtten;
    
#ifdef SHADERGRAPH_PREVIEW
    lightDirection = normalize(float3(0.5, 0.5, 0));
    lightColor = 1;
    distanceAtten = 1;
    shadowAtten = 1;
#else
#if SHADOWS_SCREEN
    float4 clipPos = TransformWorldToClip(WorldPosition);
    float4 shadowCoord = ComputeScreenPos(clipPos);
#else
    float4 shadowCoord = TransformWorldToShadowCoord(WorldPosition);
#endif
    Light light = GetMainLight(shadowCoord);
    lightDirection = light.direction;
    lightColor = light.color;
    distanceAtten = light.distanceAttenuation;
    shadowAtten = light.shadowAttenuation;
#endif

    float unshadowedDiffuse = saturate(dot(WorldNormal, lightDirection)) * distanceAtten;
    float shadowedDiffuse = unshadowedDiffuse * shadowAtten;

    float3 shadowedColor;
    float3 unshadowedColor;
    
    ChooseColor_float(Highlight, Midtone, Shadow, shadowedDiffuse, Thresholds, shadowedColor);
    ChooseColor_float(Highlight, Midtone, Shadow,unshadowedDiffuse, Thresholds, unshadowedColor);

    DiffuseColor = lerp(shadowedColor, unshadowedColor, saturate(ShadowPattern)) * lightColor;
    
    SpecularColor =
    EvaluateSpecular(WorldNormal, lightDirection, WorldViewDirection, Shininess, SpecularThreshold)
    * SpecularTint
    * SpecularStrength
    * lightColor
    * distanceAtten
    * shadowAtten;
}

float EvaluateRampedDiffuse(float diffuse, float2 thresholds, float3 values)
{
    if (diffuse < thresholds.x)
    {
        return values.x;
    }
    else if (diffuse < thresholds.y)
    {
        return values.y;
    }
    else
    {
        return values.z;
    }
}

void ComputeAdditionalLighting_float(float3 WorldPosition, float3 WorldNormal, float3 WorldViewDirection,
    float2 Thresholds, float ShadowPattern, float3 RampedDiffuseValues,
    float3 SpecularTint, float SpecularStrength, float Shininess, float SpecularThreshold,
    out float3 DiffuseColor, out float3 SpecularColor)
{
    DiffuseColor = float3(0, 0, 0);
    SpecularColor = float3(0, 0, 0);

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

        float unshadowedDiffuse = distanceAtten * NdotL;
        float shadowedDiffuse = unshadowedDiffuse * shadowAtten;

        float shadowedRamp = EvaluateRampedDiffuse(shadowedDiffuse, Thresholds, RampedDiffuseValues);
        float unshadowedRamp = EvaluateRampedDiffuse(unshadowedDiffuse, Thresholds, RampedDiffuseValues);

        float rampedDiffuse = lerp(shadowedRamp, unshadowedRamp, saturate(ShadowPattern));

        if (distanceAtten <= 0)
        {
            rampedDiffuse = 0;
        }

        DiffuseColor += max(rampedDiffuse, 0) * light.color;
        
        SpecularColor +=EvaluateSpecular(WorldNormal, light.direction, WorldViewDirection, Shininess, SpecularThreshold)
            * SpecularTint
            * SpecularStrength
            * light.color
            * distanceAtten 
            * shadowAtten;
    }
#endif
}