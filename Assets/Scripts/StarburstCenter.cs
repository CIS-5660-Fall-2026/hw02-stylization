using UnityEngine;

// Keeps the fullscreen starburst centered on the target (shader property _BurstCenter)
[ExecuteAlways]
public class StarburstCenter : MonoBehaviour
{
    public Material material;
    public Transform target;
    public Camera cam;

    [Tooltip("0 = locked to target")]
    [Range(0f, 20f)] public float follow = 0f;

    static readonly int CenterID = Shader.PropertyToID("_BurstCenter");
    Vector2 current = new Vector2(0.5f, 0.5f);

    void LateUpdate()
    {
        if (material == null) return;

        Camera c = cam != null ? cam : Camera.main;
        Transform t = target != null ? target : transform;
        if (c == null) return;

        Vector3 vp = c.WorldToViewportPoint(t.position);
        if (vp.z <= 0f) return; // behind camera

        Vector2 goal = new Vector2(vp.x, vp.y);
        if (follow <= 0f || !Application.isPlaying)
            current = goal;
        else
            current = Vector2.Lerp(current, goal, 1f - Mathf.Exp(-follow * Time.deltaTime));

        material.SetVector(CenterID, current);
    }
}
