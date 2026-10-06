using UnityEngine;

public class PostProcessEffectSwap : MonoBehaviour
{
    public Material[] materials;
    public FullScreenFeature feature;
    int index;

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            index = (index + 1) % materials.Length;
            SwapToNextMaterial(index);
        }
    }

    void SwapToNextMaterial(int index)
    {
        feature.SetMaterial(materials[index % materials.Length]);
    }

    void OnDisable()
    {
        // The feature is an asset, so reset it or the last effect sticks after Play mode.
        if (feature != null && materials.Length > 0)
        {
            feature.SetMaterial(materials[0]);
        }
    }
}