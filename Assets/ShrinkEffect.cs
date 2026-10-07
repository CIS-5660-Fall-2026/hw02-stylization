using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShrinkEffect : MonoBehaviour
{
    public Material[] materials;

    public float maxDist = 11;
    private float currDist = 11;
    int propertyId;

    
    void Start()
    {
        propertyId = Shader.PropertyToID("_OriginDistance");
        setAmount(maxDist);
    }

    void setAmount(float amt)
    {
        foreach (var mat in materials)
        {
            mat.SetFloat(propertyId, amt);
        }
    }
    void Update () {
        if (Input.GetKey(KeyCode.E))
        {
            currDist = 0.98f * currDist + 0.01f;
            currDist = Mathf.Max(0.01f, currDist);
        }
        setAmount(Mathf.Max(0.001f,currDist + 0.3f*Mathf.Sin(0.8f*Time.time)));
        currDist += 1.2f*Time.deltaTime;
        currDist = Mathf.Min(currDist, maxDist);
    }
}
