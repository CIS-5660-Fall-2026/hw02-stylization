using System;
using UnityEngine;

public class Interactivity : MonoBehaviour 
{
    [Serializable]
    public class MaterialSet
    {
        public string label; // this is for readability in the inspector
        public Material[] variants;
    }

    public MaterialSet[] materials; 
    private Renderer[] renderers;
    private int currentSet;
    private int setCount;

    void Start () 
    {
        renderers = GetComponentsInChildren<Renderer>();

        foreach (MaterialSet mat in materials)
        {
            setCount = Mathf.Max(setCount, mat.variants.Length);
        }
    }

    void Update () 
    {
        if (Input.GetKeyDown(KeyCode.Space)){
            int next = (currentSet + 1) % setCount;

            foreach (Renderer r in renderers)
            {
                Material[] mats = r.sharedMaterials;

                for (int i = 0; i < mats.Length; i++)
                {
                    foreach (MaterialSet m in materials)
                    {
                        if (Array.IndexOf(m.variants, mats[i]) >= 0 && next < m.variants.Length)
                        {
                            mats[i] = m.variants[next];
                            break;
                        }
                    }
                }
                r.sharedMaterials = mats;
            }
            
            currentSet = next;
        }
    }
}
