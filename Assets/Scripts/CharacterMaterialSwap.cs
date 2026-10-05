using System.Collections.Generic;
using UnityEngine;

// Keeps every imported material slot and texture when switching a model hierarchy.
public class CharacterMaterialSwap : MonoBehaviour
{
    public Material specialMaterial;
    public KeyCode toggleKey = KeyCode.Space;

    private readonly List<Renderer> renderers = new List<Renderer>();
    private readonly List<Material[]> originalSets = new List<Material[]>();
    private readonly List<Material[]> specialSets = new List<Material[]>();
    private bool showingSpecial;

    void Start()
    {
        if (specialMaterial == null) return;
        foreach (Renderer renderer in GetComponentsInChildren<Renderer>(true))
        {
            Material[] originals = renderer.sharedMaterials;
            Material[] variants = new Material[originals.Length];
            for (int i = 0; i < originals.Length; i++)
            {
                Material source = originals[i];
                if (source == null) continue;
                Material variant = new Material(specialMaterial);
                variant.name = source.name + " (Special)";
                foreach (string property in new[] { "_Highlight", "_Midtone", "_Shadow", "_Pattern_Color", "_Rim_Color" })
                    if (source.HasProperty(property) && variant.HasProperty(property))
                        variant.SetColor(property, source.GetColor(property));
                foreach (string property in new[] { "_Highlight_Threshold", "_Shadow_Threshold", "_Shadow_Scale", "_Smoothness", "_Rim_Strength" })
                    if (source.HasProperty(property) && variant.HasProperty(property))
                        variant.SetFloat(property, source.GetFloat(property));
                foreach (string property in new[] { "_BaseTexture", "_Shadow_Pattern" })
                    if (source.HasProperty(property) && variant.HasProperty(property))
                    {
                        variant.SetTexture(property, source.GetTexture(property));
                        variant.SetTextureScale(property, source.GetTextureScale(property));
                        variant.SetTextureOffset(property, source.GetTextureOffset(property));
                    }
                variants[i] = variant;
            }
            renderers.Add(renderer);
            originalSets.Add(originals);
            specialSets.Add(variants);
        }
    }

    void Update()
    {
        if (Input.GetKeyDown(toggleKey)) ToggleMaterials();
    }

    public void ToggleMaterials()
    {
        showingSpecial = !showingSpecial;
        for (int i = 0; i < renderers.Count; i++)
            if (renderers[i] != null)
                renderers[i].sharedMaterials = showingSpecial ? specialSets[i] : originalSets[i];
    }

    void OnDestroy()
    {
        for (int i = 0; i < renderers.Count; i++)
        {
            if (renderers[i] != null) renderers[i].sharedMaterials = originalSets[i];
            foreach (Material material in specialSets[i])
                if (material != null) Destroy(material);
        }
    }
}
