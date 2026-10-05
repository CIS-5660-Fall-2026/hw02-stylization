using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class material_swap : MonoBehaviour
{
    public Material[] materials;
    private SkinnedMeshRenderer meshRenderer;
    private Material[] originalMaterials;
    int index;
    public Material outlineMaterial;
    private float outlineWidth;

    void Start()
    {
        meshRenderer = GetComponent<SkinnedMeshRenderer>();
        originalMaterials = meshRenderer.sharedMaterials;
        outlineWidth = outlineMaterial.GetFloat("_OutlineWidth");
        // normalThreshold = outlineMaterial.GetFloat("_NormalThreshold");
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            index = (index + 1) % 2;
            SwapToNextMaterial(index);
        }
    }

    void SwapToNextMaterial(int index)
    {
        meshRenderer.sharedMaterials = index == 0 ? originalMaterials : materials;
        outlineMaterial.SetFloat("_OutlineWidth", index == 0 ? outlineWidth : 0f);
    }
    void OnDisable()
    {
        if (meshRenderer == null || outlineMaterial == null) return;

        meshRenderer.sharedMaterials = originalMaterials;
        outlineMaterial.SetFloat("_OutlineWidth", outlineWidth);
        index = 0;
    }
}
