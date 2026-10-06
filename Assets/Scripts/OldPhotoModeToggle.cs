using UnityEngine;

public class OldPhotoModeToggle : MonoBehaviour
{
    [Header("Post-process Material Swap")]
    [Tooltip("The full-screen renderer feature whose material will be changed.")]
    public FullScreenFeature fullScreenFeature;

    [Tooltip("Materials to cycle through. Element 0 is the normal look; element 1 is the old-photo look.")]
    public Material[] materials;

    [Tooltip("Key used to toggle the post-process material.")]
    public KeyCode toggleKey = KeyCode.Space;

    [SerializeField, HideInInspector] private int currentMaterialIndex;
    private bool isConfigured;

    private void Start()
    {
        isConfigured = fullScreenFeature != null && materials != null && materials.Length > 0;

        if (!isConfigured)
        {
            Debug.LogWarning("OldPhotoModeToggle needs a Full Screen Feature and at least one material.", this);
            return;
        }

        currentMaterialIndex = Mathf.Clamp(currentMaterialIndex, 0, materials.Length - 1);
        ApplyCurrentMaterial();
    }

    private void Update()
    {
        if (!isConfigured || !Input.GetKeyDown(toggleKey))
            return;

        currentMaterialIndex = (currentMaterialIndex + 1) % materials.Length;
        ApplyCurrentMaterial();
    }

    private void ApplyCurrentMaterial()
    {
        Material material = materials[currentMaterialIndex];

        if (material == null)
        {
            Debug.LogWarning($"OldPhotoModeToggle material {currentMaterialIndex} is not assigned.", this);
            return;
        }

        fullScreenFeature.SetMaterial(material);
    }

    private void OnDisable()
    {
        if (Application.isPlaying && fullScreenFeature != null && materials != null && materials.Length > 0 && materials[0] != null)
            fullScreenFeature.SetMaterial(materials[0]);
    }
}
