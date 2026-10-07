using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class NormalFeature : ScriptableRendererFeature
{
    public LayerMask normalsLayerMask;
    public RenderTexture NormalsTexture;

    public RenderPassEvent _NormalsEvent = RenderPassEvent.AfterRenderingOpaques;

    NormalsPass m_NormalsPass;
    public Material normalsMaterial;

    //so we only apply the transformation to my character and not the rest of the scene
    public LayerMask animatedLayerMask;
    public Material animatedNormalsMaterial;
    public Material animationSourceMaterial;


    /// <inheritdoc/>
    public override void Create()
    {
        m_NormalsPass = new NormalsPass(NormalsTexture, normalsLayerMask, normalsMaterial, animatedLayerMask, animatedNormalsMaterial, animationSourceMaterial);
        m_NormalsPass.renderPassEvent = _NormalsEvent;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
            renderer.EnqueuePass(m_NormalsPass);
    }
}

class NormalsPass : ScriptableRenderPass
{
    private ProfilingSampler m_ProfilingSampler;
    private FilteringSettings m_FilteringSettings;
    private List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId>();
    private RenderTexture target;
    private Material normalsMaterial;
    private FilteringSettings animatedFiltering;
    private Material animatedMaterial;
    private Material animationSource;
    private bool drawAnimated;

    public NormalsPass(RenderTexture targetTexture, LayerMask layerMask, Material mat, LayerMask animatedLayers, Material animatedMat, Material sourceMat)
    {
        m_ProfilingSampler = new ProfilingSampler("RenderNormals");
        
        target = targetTexture;

        m_ShaderTagIdList.Add(new ShaderTagId("DepthOnly")); // Only render DepthOnly pass
        normalsMaterial = mat;

        animatedMaterial = animatedMat;
        animationSource = sourceMat;

        drawAnimated = false;

        if (animatedMat != null && sourceMat != null){
            drawAnimated = true;
        }

        int animatedMask = 0;

        if(drawAnimated){
            animatedMask = layerMask.value & animatedLayers.value;
        }

        m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque, layerMask.value & ~animatedMask);

        animatedFiltering = new FilteringSettings(RenderQueueRange.opaque, animatedMask);
    }

    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
        ConfigureTarget(target);
        ConfigureClear(ClearFlag.All, Color.black);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType != CameraType.Game)
            return;
        SortingCriteria sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;
        DrawingSettings drawingSettings = CreateDrawingSettings(m_ShaderTagIdList, ref renderingData, sortingCriteria);
        drawingSettings.overrideMaterial = normalsMaterial;

        CommandBuffer cmd = CommandBufferPool.Get();
        using (new ProfilingScope(cmd, m_ProfilingSampler))
        {
            context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringSettings);
            
            if (drawAnimated){
                animatedMaterial.SetFloat("_Animation_Speed", animationSource.GetFloat("_Animation_Speed"));

                animatedMaterial.SetFloat("_Squish_Amount", animationSource.GetFloat("_Squish_Amount"));

                animatedMaterial.SetFloat("_Bob_Height", animationSource.GetFloat("_Bob_Height"));

                drawingSettings.overrideMaterial = animatedMaterial;

                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref animatedFiltering);
            }
        }

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    // Cleanup any allocated resources that were created during the execution of this render pass.
    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }
}