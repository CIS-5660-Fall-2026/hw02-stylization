using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Experimental.Rendering;

public class NormalFeature : ScriptableRendererFeature
{
    public LayerMask normalsLayerMask;
    public RenderTexture NormalsTexture;

    public RenderPassEvent _NormalsEvent = RenderPassEvent.AfterRenderingOpaques;

    NormalsPass m_NormalsPass;
    public Material normalsMaterial;


    /// <inheritdoc/>
    public override void Create()
    {
        m_NormalsPass = new NormalsPass(NormalsTexture, normalsLayerMask, normalsMaterial);
        m_NormalsPass.renderPassEvent = _NormalsEvent;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
            renderer.EnqueuePass(m_NormalsPass);
    }

    protected override void Dispose(bool disposing)
    {
        m_NormalsPass?.Dispose();
    }
}

class NormalsPass : ScriptableRenderPass
{
    private ProfilingSampler m_ProfilingSampler;
    private FilteringSettings m_FilteringSettings;
    private List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId>();
    private RenderTexture target;
    private Material normalsMaterial;
    private RTHandle m_TargetHandle;

    public NormalsPass(RenderTexture targetTexture, LayerMask layerMask, Material mat)
    {
        m_ProfilingSampler = new ProfilingSampler("RenderNormals");
        m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque, layerMask);

        target = targetTexture;

        m_ShaderTagIdList.Add(new ShaderTagId("DepthOnly")); // Only render DepthOnly pass
        normalsMaterial = mat;
    }

    class PassData
    {
        public RendererListHandle rendererList;
    }

    // Unity 6 uses the Render Graph API: record passes here instead of Execute().
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();
        if (target == null || cameraData.cameraType != CameraType.Game)
            return;
        UniversalRenderingData renderingData = frameData.Get<UniversalRenderingData>();
        UniversalLightData lightData = frameData.Get<UniversalLightData>();

        if (m_TargetHandle == null || m_TargetHandle.rt != target)
        {
            m_TargetHandle?.Release();
            m_TargetHandle = RTHandles.Alloc(target);
        }
        TextureHandle color = renderGraph.ImportTexture(m_TargetHandle);
        TextureHandle depth = renderGraph.CreateTexture(new TextureDesc(target.width, target.height)
        {
            name = "NormalsDepth",
            format = GraphicsFormat.D32_SFloat,
        });

        SortingCriteria sortingCriteria = cameraData.defaultOpaqueSortFlags;
        DrawingSettings drawingSettings = RenderingUtils.CreateDrawingSettings(m_ShaderTagIdList, renderingData, cameraData, lightData, sortingCriteria);
        drawingSettings.overrideMaterial = normalsMaterial;
        RendererListParams listParams = new RendererListParams(renderingData.cullResults, drawingSettings, m_FilteringSettings);

        using (var builder = renderGraph.AddRasterRenderPass<PassData>("RenderNormals", out var passData, m_ProfilingSampler))
        {
            passData.rendererList = renderGraph.CreateRendererList(listParams);
            builder.UseRendererList(passData.rendererList);
            builder.SetRenderAttachment(color, 0);
            builder.SetRenderAttachmentDepth(depth);
            builder.AllowPassCulling(false);
            builder.SetRenderFunc((PassData data, RasterGraphContext ctx) =>
            {
                ctx.cmd.ClearRenderTarget(true, true, Color.black);
                ctx.cmd.DrawRendererList(data.rendererList);
            });
        }
    }

    public void Dispose()
    {
        m_TargetHandle?.Release();
        m_TargetHandle = null;
    }
}