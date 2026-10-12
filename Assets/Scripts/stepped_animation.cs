using UnityEngine;

[RequireComponent(typeof(Animator))]
public class SteppedAnimation : MonoBehaviour
{
    public float updatesPerSecond = 12f;

    Animator animator;
    float timer = 0;

    void Awake()
    {
        animator = GetComponent<Animator>();
        animator.enabled = false;
    }

    void Update()
    {
        timer += Time.deltaTime;
        float step = 1f / updatesPerSecond;

        if (timer >= step)
        {
            int steps = Mathf.FloorToInt(timer / step);
            timer -= steps * step;
            animator.Update(steps * step);
        }
    }
}