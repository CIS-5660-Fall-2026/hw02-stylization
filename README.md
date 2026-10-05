## HW02

A stylized Unity scene featuring Toad.

### Concept art and assets

#### Concept Art

The Toad artwork used as concept art in this project was created by [@ItosinoPIO](https://x.com/ItosinoPIO).

Original source: https://x.com/ItosinoPIO/status/1807534707758047591

#### Toad 3D Model
The Toad model used in this project was created by https://sketchfab.com/jakobhenerey2023

Original source: https://sketchfab.com/3d-models/toad-d6a9f85aecd245fcb75f7d0f7a2f9f95

### Implemented features

#### Toon surface shading

`Assets/Shaders/Toon Shader Extra.shadergraph` implements the main surface shader. Lighting helper functions are in `Assets/Shaders/Includes/LightingHelp.hlsl`.

- Highlight, midtone, and shadow colors with adjustable thresholds and smooth transitions.
- Main directional light and additional light support, including shadow attenuation.
- Fresnel-based rim lighting with adjustable color and strength.
- Shadow-pattern texture sampled using object UVs, with an exposed Shadow Scale parameter.
- Base Texture support: the diffuse texture modulates the shaded color before the rim contribution is added.

#### Special surface shader

`Assets/Shaders/Toon Shader Extra 1.shadergraph` is the special shader variant. It combines time-driven UV animation, sine-based modulation, texture-based color variation, and a special-color blend. It also supports the character's diffuse textures.

The demonstration sphere uses `SpecialToonMaterial` and `InteractiveMaterial`. Toad uses per-slot special material instances created at runtime, preserving each original texture and shading palette.

#### Depth and normal outlines

The outline pipeline uses separate scene depth and normal data:

- `NormalFeature.cs` renders opaque object normals into `Assets/Buffers/Normal Buffer.renderTexture` using `NormalMaterial`.
- `OutlineShader.shadergraph` detects differences between neighboring normal samples.
- `DepthOutline.hlsl` adds four-sample Roberts Cross depth detection, using linear eye depth and a relative depth difference threshold. Perspective and orthographic depth conversions are handled separately.
- The depth and normal masks are combined to composite outlines over the camera image.
- Time-driven wobble animates the sampling offset. Outline Width, Outline Wobble, Outline Speed, and Depth Threshold are exposed for adjustment.

`Full Screen Feature.cs` requests camera depth and applies the full-screen materials through a temporary color buffer.

#### Full-screen post-processing

The custom renderer applies:

- **Color quantization:** reduces RGB color levels with time-varying quantization steps.
- **Vignette:** blends the edges of the image toward an adjustable vignette color.

The renderer configuration is `Assets/Render Settings/URP-Custom-Renderer.asset`.

#### Scene and interaction

The scene contains Toad, a demonstration sphere, a ground plane, wall geometry, a directional light, and additional point lights. The colored lights demonstrate the shader's response to multiple light sources.

In Play Mode, press the Space key to switch both Toad and the sphere between their two material modes. Press Space again to restore their initial materials.

- `MaterialSwap.cs` switches the sphere's materials on Space.
- `CharacterMaterialSwap.cs`, attached to Toad's root, switches materials across the character's renderer hierarchy. It preserves every material slot and diffuse texture, restores the original materials on the next toggle, and cleans up runtime material instances.

### Turnaround Video

A video turnaround of the scene can be found in the `Recordings` folder:

`Recordings/hw2 video.mp4`
