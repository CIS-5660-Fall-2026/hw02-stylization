using UnityEngine;
using UnityEngine.Rendering.Universal;

public class Toggle : MonoBehaviour
{
    public Material[] materials;
    public ScriptableRendererData rendererData;
    int index;

    private FullScreenFeature fullScreenFeature;
    private Material originalMaterial;
    
    void Start()
    {
        foreach (var feature in rendererData.rendererFeatures)
        {
            if (feature is FullScreenFeature)
            {
                fullScreenFeature = (FullScreenFeature)feature;
                break;
            }
        }

        originalMaterial = fullScreenFeature.CurrentMaterial;
        SwapToNextMaterial(index);
    }

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
        fullScreenFeature.CurrentMaterial = materials[index % materials.Length];
    }

    void OnDestroy()
    {
        if (fullScreenFeature != null)
            fullScreenFeature.CurrentMaterial = originalMaterial;
    }
}