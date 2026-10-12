using System.Collections;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using TMPro;

public class BatmanReveal : MonoBehaviour
{
    [SerializeField] Camera cam;
    [SerializeField] GameObject batman;
    [SerializeField] GameObject text;
    [SerializeField] Material silhouetteMat;
    [SerializeField] FullScreenPassRendererFeature impactFeature;
    [SerializeField] FullScreenPassRendererFeature postFeature;
    [SerializeField] private float holdFrames = 1;
    [SerializeField] TMP_Text label;
    [SerializeField] float fadeDelay = 0.2f;
    [SerializeField] float fadeSeconds = 1.5f;

    Renderer[] renderers;
    Material[][] originalMats;
    bool played;

    void Awake()
    {
        silhouetteMat = new Material(silhouetteMat);

        renderers = batman.GetComponentsInChildren<Renderer>(true);

        originalMats = new Material[renderers.Length][];
        for (int i = 0; i < renderers.Length; i++)
            originalMats[i] = renderers[i].sharedMaterials;
        
        QualitySettings.vSyncCount = 0;
        Application.targetFrameRate = 60;
    }

    void Update()
    {
        if (!played && Input.GetKeyDown(KeyCode.Space))
        {
            played = true;
            StartCoroutine(Reveal());
        }
    }

    IEnumerator Reveal()
    {
        int oldMask = cam.cullingMask;
        CameraClearFlags oldFlags = cam.clearFlags;
        Color oldBg = cam.backgroundColor;

        // white
        batman.SetActive(true);
        ApplySilhouette();
        cam.cullingMask = LayerMask.GetMask("batman");
        cam.clearFlags = CameraClearFlags.SolidColor;
        cam.backgroundColor = Color.black;
        silhouetteMat.color = Color.white;
        
        postFeature.SetActive(false);
        impactFeature.passMaterial.SetFloat("_Invert", 0f);
        impactFeature.SetActive(true);
        
        for (int i = 0; i < holdFrames; i++) yield return null;
        
        // inverted
        cam.backgroundColor = Color.white;
        silhouetteMat.color = Color.black;
        
        impactFeature.passMaterial.SetFloat("_Invert", 1f);
        
        for (int i = 0; i < holdFrames; i++) yield return null;

        // revert and fade in text
        StartCoroutine(FadeInText());
        for (int i = 0; i < renderers.Length; i++)
            renderers[i].sharedMaterials = originalMats[i];
        cam.cullingMask = oldMask;
        cam.clearFlags = oldFlags;
        cam.backgroundColor = oldBg;
        
        impactFeature.SetActive(false);
        postFeature.SetActive(true);
        
        text.SetActive(true);
    }
    
    IEnumerator FadeInText()
    {
        label.alpha = 0f;
        text.SetActive(true);

        yield return new WaitForSeconds(fadeDelay);

        float t = 0f;
        while (t < 1f)
        {
            t += Time.deltaTime / fadeSeconds;
            label.alpha = Mathf.SmoothStep(0f, 1f, t);
            yield return null;
        }
        label.alpha = 1f;
    }

    void ApplySilhouette()
    {
        foreach (var r in renderers)
        {
            var mats = new Material[r.sharedMaterials.Length];
            for (int i = 0; i < mats.Length; i++)
            {
                mats[i] = silhouetteMat;
            }
            r.sharedMaterials = mats;
        }
    }
    
    void OnDisable()
    {
        if (impactFeature != null) impactFeature.SetActive(false);
    }
}