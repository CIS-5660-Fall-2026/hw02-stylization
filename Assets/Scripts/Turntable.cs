using UnityEngine;

public class Turntable : MonoBehaviour
{
    [Header("Camera Orbit")]
    [Tooltip("Orbit speed in degrees per second. Use a negative value to reverse direction.")]
    public float angularSpeed = 10.0f;

    [Min(0.01f)]
    [Tooltip("Horizontal distance between the camera and this pivot.")]
    public float radius = 5.0f;

    [Tooltip("Camera to orbit. If left empty, the first child Camera is used.")]
    public Transform orbitCamera;

    private Vector3 orbitDirection = Vector3.back;
    private float cameraHeight;

    private void Awake()
    {
        InitializeCamera();
    }

    private void LateUpdate()
    {
        transform.Rotate(Vector3.up, angularSpeed * Time.deltaTime, Space.World);

        ApplyRadius();
    }

    private void InitializeCamera()
    {
        if (orbitCamera == null)
        {
            Camera childCamera = GetComponentInChildren<Camera>();
            if (childCamera != null && childCamera.transform != transform)
                orbitCamera = childCamera.transform;
        }

        if (orbitCamera == null)
        {
            return;
        }

        Vector3 horizontalOffset = Vector3.ProjectOnPlane(orbitCamera.localPosition, Vector3.up);
        if (horizontalOffset.sqrMagnitude > 0.0001f)
            orbitDirection = horizontalOffset.normalized;

        cameraHeight = orbitCamera.localPosition.y;
        ApplyRadius();
    }

    private void ApplyRadius()
    {
        if (orbitCamera == null)
            return;

        orbitCamera.localPosition = orbitDirection * Mathf.Max(radius, 0.01f)
                                  + Vector3.up * cameraHeight;
    }
}
