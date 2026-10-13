using UnityEngine;

public class Turntable : MonoBehaviour
{
    [Tooltip("Off = continuous spin")]
    public bool oscillate = true;

    [Header("Oscillate")]
    [Tooltip("Offset from the starting Y rotation")]
    public float startAngle = 0f;
    [Tooltip("Local Y rotation to swing to")]
    public float endAngle = 90f;
    public float cycleSeconds = 4f;

    [Header("Spin")]
    public float rotationSpeed = 1.0f;

    Vector3 startEuler;
    float startTime;

    void Start()
    {
        startEuler = transform.localEulerAngles;
        startTime = Time.time;
    }

    void Update()
    {
        if (!oscillate)
        {
            transform.Rotate(0, rotationSpeed * Time.deltaTime, 0);
            return;
        }

        float phase = (Time.time - startTime) * 2f * Mathf.PI / Mathf.Max(cycleSeconds, 0.01f);
        float t = 0.5f - 0.5f * Mathf.Cos(phase);
        float yaw = Mathf.Lerp(startEuler.y + startAngle, startEuler.y + endAngle, t);

        transform.localEulerAngles = new Vector3(startEuler.x, yaw, startEuler.z);
    }
}
