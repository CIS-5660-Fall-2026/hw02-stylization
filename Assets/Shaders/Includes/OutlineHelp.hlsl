SAMPLER(sampler_point_clamp);


// Testing funcs
void GetDepth_float(float2 uv, out float Depth)
{
    Depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(uv);
}


void GetNormal_float(float2 uv, out float3 Normal)
{
    Normal = SAMPLE_TEXTURE2D(_NormalBuffer, sampler_point_clamp, uv).rgb;
}


// OUTLINE
// SOBEL STUFF


// where to sample around the current pixel
static float2 sobelSamplePoints[9] =
{
    float2(-1, 1), float2(0, 1), float2(1, 1),
    float2(-1, 0), float2(0, 0), float2(1, 0),
    float2(-1, -1), float2(0, -1), float2(1, -1)
};

// X
static float sobelMatrixX[9] =
{
    1, 0, -1,
     2, 0, -2,
     1, 0, -1
};

// Y
static float sobelMatrixY[9] =
{
    1, 2, 1,
     0, 0, 0,
    -1, -2, -1
};


// sudden depth change? its an edge
// UV = where am i on the screen
// thickness = how far away should i look
// out = how strong is this edge here
void DepthSobel_float(float2 UV, float Thickness, out float Out)
{
    float2 pixelSize = 1.0 / _ScreenParams.xy;
    // sobel.x is horizontal difference
    // sobel.y is vertical difference
    float2 sobel = 0;

    [unroll]
    for (int i = 0; i < 9; i++)
    {
        // move away from the current UV by this sample's offset, then get the depth there.
        // UV + direction × Thickness and ask Unity what is the depth at this position
        
        // 1. Calculate the UV of the neighboring pixel
        float2 neighborUV = UV + sobelSamplePoints[i] * pixelSize * Thickness;
        
        // 2. Get the depth at that neighboring UV
        float depth;
        GetDepth_float(neighborUV, depth);
        
        // 3. use depth in sobel calculation
        // takes that depth and applies its Sobel X and Y weights.
        sobel += depth * float2(sobelMatrixX[i], sobelMatrixY[i]);
    }

    Out = length(sobel);
}

void NormalSobel_float(float2 UV, float Thickness, out float Out)
{
    float2 pixelSize = 1.0 / _ScreenParams.xy;
    // sobel.x is horizontal difference
    // sobel.y is vertical difference
    
    // sobelX = horizontal changes in the normal vector
    // sobelY = vertical changes in the normal vector
    float3 sobelX = 0;
    float3 sobelY = 0;
    
    
    [unroll]
    for (int i = 0; i < 9; i++){

        // At each location, sample the Normal Buffer instead of Scene Depth like before
        // “what direction is the surface facing at this neighboring pixel?”
        
        // 1. Calculate the UV of the neighboring pixels
        float2 neighborUV = UV + sobelSamplePoints[i] * pixelSize * Thickness;
        
        // 2. Get the normal at that neighboring UV
        float3 normal;
        GetNormal_float(neighborUV, normal);
        

        // takes that normal and applies its Sobel X and Y weights (separate, because vec3)
        sobelX += normal * sobelMatrixX[i];
        sobelY += normal * sobelMatrixY[i];
        
    }
    
    // measure the magnitude of these two float3 changes and combine them into one edge-strength float
    
    float xChange = length(sobelX);
    float yChange = length(sobelY);
    
    float2 changeVec = float2(xChange, yChange);
    

    Out = length(changeVec);
    
    
}


// I'm trying to get... thicker edges
// idea: at current UV, check if one of its neighbors is an edge. if its an edge, im an edge too
void ThickerNormalEdges_float(float2 UV, float lineWidth, out float Out)
{
    float2 pixelSize = 1.0 / _ScreenParams.xy;
    
    // keep track of strongest edge
    float strongestEdge = 0;
    
    
    [unroll]
    for (int i = 0; i < 9; i++)
    {   
        // for eachh neighbor pixel around current UV
        // get neighbor uv
        float2 neighborUV = UV + sobelSamplePoints[i] * pixelSize * lineWidth;
        
        // run normal sobel
        // NormalSobel finds an edge at one location []|[]
        // ThickerNormalEdges asks whether there is an edge anywhere NEAR the current location
        // aka ask its neighbors if neighbor is an edge
        // if neighbor says: "yeah dude I'm a strong edge" --> then current becomes/leans edge too
        float edgeStrength;
        NormalSobel_float(neighborUV, 1.0, edgeStrength);
        
        // update strongest edge with the strongest edge so far
        strongestEdge = max(strongestEdge, edgeStrength);

        
    }
    
    Out = strongestEdge;
    
}
