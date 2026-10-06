using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FullScreenFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class FullScreenPassSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        public Material material;
    }

    [SerializeField] private FullScreenPassSettings settings = new FullScreenPassSettings();
    class FullScreenPass : ScriptableRenderPass
    {
        const string ProfilerTag = "Full Screen Pass";
        public FullScreenFeature.FullScreenPassSettings settings;
        RenderTargetIdentifier colorBuffer, temporaryBuffer;
        private readonly int temporaryBufferID;

        public FullScreenPass(FullScreenFeature.FullScreenPassSettings passSettings, int featureInstanceId)
        {
            this.settings = passSettings ?? new FullScreenPassSettings();
            this.renderPassEvent = this.settings.renderPassEvent;
            temporaryBufferID = Shader.PropertyToID($"_FullScreenTemporaryBuffer_{featureInstanceId}");
            ConfigureInput(ScriptableRenderPassInput.Depth);
            if (this.settings.material == null) this.settings.material = CoreUtils.CreateEngineMaterial("Shader Graphs/Invert");
        }

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.depthBufferBits = 0;
            colorBuffer = renderingData.cameraData.renderer.cameraColorTarget;

            cmd.GetTemporaryRT(temporaryBufferID, descriptor, FilterMode.Point);
            temporaryBuffer = new RenderTargetIdentifier(temporaryBufferID);
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, new ProfilingSampler(ProfilerTag)))
            {
                // HW 4 Hint: Blit from the color buffer to a temporary buffer and *back*.
                Blit(cmd, colorBuffer, temporaryBuffer, settings.material);
                Blit(cmd, temporaryBuffer, colorBuffer);
            }

            // Execute the command buffer and release it.
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            if (cmd == null) throw new ArgumentNullException("cmd");
            cmd.ReleaseTemporaryRT(temporaryBufferID);
        }
    }

    FullScreenPass m_FullScreenPass;

    public Material CurrentMaterial => settings != null ? settings.material : null;

    public void SetMaterial(Material material)
    {
        if (material == null)
            return;

        if (settings == null)
            settings = new FullScreenPassSettings();

        settings.material = material;

        if (m_FullScreenPass != null)
            m_FullScreenPass.settings = settings;
    }

    /// <inheritdoc/>
    public override void Create()
    {
        m_FullScreenPass = new FullScreenPass(settings, GetInstanceID());
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
