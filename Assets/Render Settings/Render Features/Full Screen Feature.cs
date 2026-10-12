using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;

public class FullScreenFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class FullScreenPassSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        public Material material;
    }

    [SerializeField] private FullScreenPassSettings settings;
    class FullScreenPass : ScriptableRenderPass
    {
        const string ProfilerTag = "Full Screen Pass";
        public FullScreenFeature.FullScreenPassSettings settings;

        public FullScreenPass(FullScreenFeature.FullScreenPassSettings passSettings)
        {
            this.settings = passSettings;
            this.renderPassEvent = settings.renderPassEvent;
            if (settings.material == null) settings.material = CoreUtils.CreateEngineMaterial("Shader Graphs/Invert");
            requiresIntermediateTexture = true;
        }

        // Unity 6 uses the Render Graph API: record passes here instead of Execute().
        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
            if (resourceData.isActiveTargetBackBuffer) return;

            TextureHandle colorBuffer = resourceData.activeColorTexture;
            TextureDesc desc = renderGraph.GetTextureDesc(colorBuffer);
            desc.name = "_TemporaryBuffer";
            desc.clearBuffer = false;
            TextureHandle temporaryBuffer = renderGraph.CreateTexture(desc);

            // HW 4 Hint: Blit from the color buffer to a temporary buffer and *back*.
            renderGraph.AddBlitPass(new RenderGraphUtils.BlitMaterialParameters(colorBuffer, temporaryBuffer, settings.material, 0), ProfilerTag);
        }
    }

    FullScreenPass m_FullScreenPass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_FullScreenPass = new FullScreenPass(settings);
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType != CameraType.Game)
            return;
        renderer.EnqueuePass(m_FullScreenPass);
    }
}


