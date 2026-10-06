using UnityEngine;

// Listens for a key press and switches the whole scene between styles:
// every MaterialSwapper, the outline and paper post process materials, and the sky color.
public class StyleSwitcher : MonoBehaviour
{
    [System.Serializable]
    public class Style
    {
        public string name = "Style";
        public Color skyColor = Color.blue;
        public Color outlineColor = Color.black;
        public float outlineThickness = 2f;
        public float wobbleAmount = 1.5f;
        public float paperStrength = 0.35f;
        public float glowStrength = 0f;
    }

    public KeyCode key = KeyCode.Space;
    public Material outlineMaterial;
    public Material paperMaterial;
    public Material glowMaterial;
    public Style[] styles = new Style[2];

    private int index;
    private Style original;

    void Start()
    {
        // Remember what the materials looked like so Play mode does not permanently change the assets
        original = ReadCurrentStyle();
        Apply(0);
    }

    void Update()
    {
        if (Input.GetKeyDown(key))
        {
            Apply(index + 1);
        }
    }

    void OnDisable()
    {
        if (original != null)
        {
            ApplyPostProcess(original);
        }
    }

    void Apply(int newIndex)
    {
        if (styles == null || styles.Length == 0)
        {
            return;
        }
        index = newIndex % styles.Length;

        foreach (MaterialSwapper swapper in FindObjectsOfType<MaterialSwapper>())
        {
            swapper.SetIndex(index);
        }
        ApplyPostProcess(styles[index]);
    }

    void ApplyPostProcess(Style style)
    {
        Camera camera = Camera.main;
        if (camera != null)
        {
            camera.backgroundColor = style.skyColor;
        }
        if (outlineMaterial != null)
        {
            outlineMaterial.SetColor("_OutlineColor", style.outlineColor);
            outlineMaterial.SetFloat("_Thickness", style.outlineThickness);
            outlineMaterial.SetFloat("_WobbleAmount", style.wobbleAmount);
        }
        if (paperMaterial != null)
        {
            paperMaterial.SetFloat("_PaperStrength", style.paperStrength);
        }
        if (glowMaterial != null)
        {
            glowMaterial.SetFloat("_Strength", style.glowStrength);
        }
    }

    Style ReadCurrentStyle()
    {
        Style style = new Style();
        Camera camera = Camera.main;
        if (camera != null)
        {
            style.skyColor = camera.backgroundColor;
        }
        if (outlineMaterial != null)
        {
            style.outlineColor = outlineMaterial.GetColor("_OutlineColor");
            style.outlineThickness = outlineMaterial.GetFloat("_Thickness");
            style.wobbleAmount = outlineMaterial.GetFloat("_WobbleAmount");
        }
        if (paperMaterial != null)
        {
            style.paperStrength = paperMaterial.GetFloat("_PaperStrength");
        }
        if (glowMaterial != null)
        {
            style.glowStrength = glowMaterial.GetFloat("_Strength");
        }
        return style;
    }
}
