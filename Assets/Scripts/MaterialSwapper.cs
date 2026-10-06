using UnityEngine;

// Holds the materials one object can switch between. StyleSwitcher tells every swapper
// in the scene which index to show, so all objects change together on one key press.
public class MaterialSwapper : MonoBehaviour
{
    public Material[] materials;

    private MeshRenderer meshRenderer;
    private int index;

    void Start()
    {
        meshRenderer = GetComponent<MeshRenderer>();
    }

    public void SwapToNext()
    {
        SetIndex(index + 1);
    }

    public void SetIndex(int newIndex)
    {
        if (materials == null || materials.Length == 0)
        {
            return;
        }
        if (meshRenderer == null)
        {
            meshRenderer = GetComponent<MeshRenderer>();
        }

        index = newIndex % materials.Length;
        meshRenderer.sharedMaterial = materials[index];
    }
}
