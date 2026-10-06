using System.Linq;
using UnityEngine;

public class ChangeMaterialOnKey : MonoBehaviour
{
    [SerializeField] private Material[] materials;
    private MeshRenderer meshRenderer;
    int index;

    void Awake()
    {
        meshRenderer = GetComponent<MeshRenderer>();
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
        meshRenderer.material = materials[index % materials.Length];
    }
}
