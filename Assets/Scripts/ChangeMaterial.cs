using UnityEngine;
using UnityEngine.Rendering.Universal;

public class ChangeMaterial : MonoBehaviour
{
    public ScriptableRendererData rendererData;
    public Material[] materials;

    FullScreenFeature feature;
    int index;

    void Start()
    {
        foreach (var f in rendererData.rendererFeatures)
        {
            if (f is FullScreenFeature fs) { feature = fs; break; }
        }
        if (feature != null && materials.Length > 0)
            feature.SetMaterial(materials[0]);
    }

    void Update()
    {
        if (feature == null || materials.Length == 0) return;

        if (Input.GetKeyDown(KeyCode.Space))
        {
            index = (index + 1) % materials.Length;
            feature.SetMaterial(materials[index]);
        }
    }
}