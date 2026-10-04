using UnityEngine;

public class KirbsRotate : MonoBehaviour
{
    public Material[] materials;
    private Renderer meshRenderer;
    int index = 0;

    void Start()
    {
        meshRenderer = GetComponent<Renderer>();
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
        meshRenderer.material = materials[index];
    }
}