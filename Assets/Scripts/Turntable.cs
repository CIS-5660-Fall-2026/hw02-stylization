using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Turntable : MonoBehaviour
{
    [SerializeField] private MeshRenderer[] meshes;

    private bool altMode;
    
    private void Update()
    {
        float y = 180f + 20f * Mathf.Sin(Time.time * 0.1f * 2f * Mathf.PI);
        transform.localRotation = Quaternion.Euler(0f, y, 0f);

        if (Input.GetKeyDown(KeyCode.Space))
        {
            altMode = !altMode;
            foreach (var mesh in meshes)
            {
                foreach (var mat in mesh.materials)
                {
                    mat.SetFloat("_Rainbow", altMode ? 1f : 0f);
                }
            }
        }
    }
}
