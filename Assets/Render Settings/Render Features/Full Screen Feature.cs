using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FullScreenFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class FullScreenPassSettings {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        public Material material;
    }

    [SerializeField] private FullScreenPassSettings settings;

    class FullScreenPass : ScriptableRenderPass {
        const string ProfilerTag = "Mark's Full Screen Pass";
        public FullScreenFeature.FullScreenPassSettings settings;

        // RTHandles replace RenderTargetIdentifier + GetTemporaryRT in URP 13+.
        RTHandle colorBuffer;
        RTHandle temporaryBuffer;
        readonly ProfilingSampler profilingSampler = new ProfilingSampler(ProfilerTag);

        public FullScreenPass(FullScreenFeature.FullScreenPassSettings passSettings)
        {
            this.settings = passSettings;
            this.renderPassEvent = settings.renderPassEvent;
            if (settings.material == null) settings.material = CoreUtils.CreateEngineMaterial("Shader Graphs/Invert");
            //Packages/com.unity.render-pipelines.universal/Shaders/FullscreenInvertColors.shadergraph
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            colorBuffer = renderingData.cameraData.renderer.cameraColorTargetHandle;

            // Temp target matches the camera, minus depth (we only need color).
            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.depthBufferBits = 0;
            descriptor.msaaSamples = 1;
            // Allocates once, and only reallocates when the camera size/format changes.
            RenderingUtils.ReAllocateIfNeeded(ref temporaryBuffer, descriptor, FilterMode.Point,
                                              TextureWrapMode.Clamp, name: "_TemporaryBuffer");
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (settings.material == null) return;

            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, profilingSampler)) {
                // Blitter binds the source as _BlitTexture, which the Fullscreen Shader Graph's
                // URP Sample Buffer (Blit Source) node reads. Pass 0 = DrawProcedural.
                Blitter.BlitCameraTexture(cmd, colorBuffer, temporaryBuffer, settings.material, 0);
                // Plain copy back to the camera (no material).
                Blitter.BlitCameraTexture(cmd, temporaryBuffer, colorBuffer);
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        // RTHandles persist across frames, so they're released when the feature is disposed instead.
        public void Dispose()
        {
            temporaryBuffer?.Release();
            temporaryBuffer = null;
        }
    }

    FullScreenPass m_FullScreenPass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_FullScreenPass = new FullScreenPass(settings);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType != CameraType.Game)
            return;
        renderer.EnqueuePass(m_FullScreenPass);
    }

    protected override void Dispose(bool disposing)
    {
        m_FullScreenPass?.Dispose();
    }
}
