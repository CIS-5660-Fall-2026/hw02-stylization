// Balloon float: the whole object bobs up and down and sways a little from side to side.
// Works in world space so every part of the balloon gets the same offset and stays together.
void BalloonFloat_float(float3 PositionWS, float Time,
    float BobAmplitude, float BobSpeed,
    float SwayAmplitude, float SwaySpeed,
    out float3 Out)
{
    float offsetY = sin(Time * BobSpeed) * BobAmplitude;
    float offsetX = sin(Time * SwaySpeed) * SwayAmplitude;

    Out = PositionWS + float3(offsetX, offsetY, 0);
}
