using UnityEngine;

public class ChilletMaterialHold : MonoBehaviour
{
    public Material specialMaterial;
    public int bodyMaterialSlot;

    private Renderer targetRenderer;
    private Material originalMaterial;
    private bool isActive;

    void Start()
    {
        targetRenderer = GetComponent<Renderer>();

        if (targetRenderer == null || specialMaterial == null)
        {
            enabled = false;
            return;
        }

        Material[] slots = targetRenderer.sharedMaterials;

        if (bodyMaterialSlot < 0 || bodyMaterialSlot >= slots.Length)
        {
            enabled = false;
            return;
        }

        originalMaterial = slots[bodyMaterialSlot];
    }

    void Update()
    {
        bool holdingSpace = Input.GetKey(KeyCode.Space);

        if (holdingSpace == isActive)
            return;

        SetMaterial(holdingSpace ? specialMaterial : originalMaterial);
        isActive = holdingSpace;
    }

    void OnDisable()
    {
        if (isActive && targetRenderer != null)
        {
            SetMaterial(originalMaterial);
            isActive = false;
        }
    }

    private void SetMaterial(Material material)
    {
        Material[] slots = targetRenderer.sharedMaterials;
        slots[bodyMaterialSlot] = material;
        targetRenderer.sharedMaterials = slots;
    }
}