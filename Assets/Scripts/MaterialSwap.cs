using UnityEngine;

public class MaterialSwap : MonoBehaviour
{
    public Material materialA;
    public Material materialB;

    private Renderer objectRenderer;
    private bool usingMaterialB = false;

    void Start()
    {
        objectRenderer = GetComponent<Renderer>();

        if (objectRenderer != null && materialA != null)
        {
            objectRenderer.material = materialA;
        }
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            usingMaterialB = !usingMaterialB;

            if (usingMaterialB)
            {
                objectRenderer.material = materialB;
            }
            else
            {
                objectRenderer.material = materialA;
            }
        }
    }
}