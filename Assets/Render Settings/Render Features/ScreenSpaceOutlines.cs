using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Render_Settings.Render_Features
{
    public class ScreenSpaceOutlines :  ScriptableRendererFeature{
        private class ViewSpaceNormalsTexturePass : ScriptableRenderPass
        {
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
            }
            
        }
        public override void Create()
        {
        
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            
        }
    }
    
}