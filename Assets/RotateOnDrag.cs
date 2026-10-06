using UnityEngine;

public class RotateOnDrag : MonoBehaviour
{
    private Vector3 dragStart;

    void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            dragStart = Input.mousePosition;
        }
        if (Input.GetMouseButton(0))
        {
            Vector3 dragDelta = Input.mousePosition - dragStart;
            transform.Rotate(0, -dragDelta.x, 0);
            dragStart = Input.mousePosition;
        }
    }
}
