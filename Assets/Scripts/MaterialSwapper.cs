using UnityEngine;

public class MaterialSwapper : MonoBehaviour
{
    public Material[] materials;
    public KeyCode swapKey = KeyCode.Space;

    [Tooltip("Leave empty to use the first renderer in children")]
    public Renderer targetRenderer;
    public int materialSlot = 0;

    Renderer rend;
    int index;

    void Start()
    {
        rend = targetRenderer != null ? targetRenderer : GetComponentInChildren<Renderer>();
        if (rend == null)
        {
            Debug.LogWarning("MaterialSwapper: no renderer found on " + name);
            enabled = false;
            return;
        }

        if (materials.Length > 0)
            SetMaterial(0);
    }

    void Update()
    {
        if (materials.Length == 0) return;

        if (Input.GetKeyDown(swapKey))
        {
            index = (index + 1) % materials.Length;
            SetMaterial(index);
        }
    }

    void SetMaterial(int i)
    {
        // sharedMaterials so we don't leak material instances
        Material[] mats = rend.sharedMaterials;
        int slot = Mathf.Clamp(materialSlot, 0, mats.Length - 1);
        mats[slot] = materials[i];
        rend.sharedMaterials = mats;
    }
}
