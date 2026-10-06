using UnityEngine;
using UnityEngine.Rendering.Universal;

public class MatSwitcher : MonoBehaviour
{
    public UniversalRendererData rendererData;

    public Material normalMaterial;
    public Material inkMaterial;

    public MeshRenderer waterRenderer;

    private FullScreenFeature fullScreenFeature;
    private bool inkMode = false;

    void Start()
    {
        foreach (var feature in rendererData.rendererFeatures)
        {
            if (feature is FullScreenFeature)
            {
                fullScreenFeature = feature as FullScreenFeature;
                break;
            }
        }

        // Always begin with water visible
        waterRenderer.enabled = true;
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            inkMode = !inkMode;

            if (inkMode)
            {
                fullScreenFeature.SetMaterial(inkMaterial);
                waterRenderer.enabled = false;
            }
            else
            {
                fullScreenFeature.SetMaterial(normalMaterial);
                waterRenderer.enabled = true;
            }
        }
    }
}