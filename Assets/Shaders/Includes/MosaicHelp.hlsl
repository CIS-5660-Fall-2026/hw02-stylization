float2 random2(float2 p)
{
    return frac(
        sin(float2(
            dot(p, float2(127.1, 311.7)),
            dot(p, float2(269.5, 183.3))))
            * 43758.5453);
}

void MosaicCell_float(float2 uv, float CellDensity,
                      out float2 CellUV, out float Border)
{
    // Correct for aspect ratio so tiles aren't stretched on a wide screen.
    float2 aspect = float2(_ScreenParams.x / _ScreenParams.y, 1.0);
    float2 p = uv * aspect * CellDensity;
    float2 pInt = floor(p);
    float2 pFract = frac(p);

    float minDist = 8.0;
    float secondDist = 8.0;
    CellUV = uv;

    for (int y = -1; y <= 1; y++)
    {
        for (int x = -1; x <= 1; x++)
        {
            // Direction in which neighbor cell lies
            float2 neighbor = float2(x, y);

            // Voronoi centerpoint for the neighboring cell
            float2 cellPoint = random2(pInt + neighbor);

            // Distance between fragment coord and neighbor's Voronoi point
            float2 diff = neighbor + cellPoint - pFract;
            float dist = length(diff);

            if (dist < minDist)
            {
                secondDist = minDist;
                minDist = dist;

                // Convert the winning point back to screen uv.
                CellUV = (pInt + neighbor + cellPoint) / CellDensity / aspect;
            }
            else if (dist < secondDist)
            {
                secondDist = dist;
            }
        }
    }

    // Near 0 at the boundary between two tiles--used for grout lines.
    Border = secondDist - minDist;
}
