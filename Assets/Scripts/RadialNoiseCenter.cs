using UnityEngine;

// Feeds this sphere's position/scale into the inverse hull's radial falloff
[ExecuteAlways]
public class RadialNoiseCenter : MonoBehaviour
{
    public Material[] materials;

    [Tooltip("Use per-axis scale as the falloff shape (ellipsoid)")]
    public bool driveShapeFromScale = true;
    public bool hideInPlayMode = true;

    static readonly int CenterID = Shader.PropertyToID("_Radial_Center");
    static readonly int RadiusID = Shader.PropertyToID("_Radial_falloff_radius");
    static readonly int ShapeID = Shader.PropertyToID("_Radial_falloff_shape");

    const float sphereRadius = 0.5f; // unity sphere at scale 1

    void OnEnable()
    {
        var r = GetComponent<Renderer>();
        if (r != null && Application.isPlaying && hideInPlayMode)
            r.enabled = false;
    }

    void LateUpdate()
    {
        if (materials == null) return;

        Vector3 pos = transform.position;
        Vector3 s = transform.lossyScale;

        foreach (var m in materials)
        {
            if (m == null) continue;
            m.SetVector(CenterID, pos);

            if (driveShapeFromScale)
            {
                m.SetFloat(RadiusID, sphereRadius);
                m.SetVector(ShapeID, new Vector3(
                    Mathf.Max(Mathf.Abs(s.x), 1e-4f),
                    Mathf.Max(Mathf.Abs(s.y), 1e-4f),
                    Mathf.Max(Mathf.Abs(s.z), 1e-4f)));
            }
            else
            {
                float maxScale = Mathf.Max(Mathf.Abs(s.x), Mathf.Abs(s.y), Mathf.Abs(s.z));
                m.SetFloat(RadiusID, sphereRadius * maxScale);
            }
        }
    }
}
