# HW 4: *3D Stylization*
<video src="stylization demo video.mp4"></video>

## Implementation Details
### Improved Shader

Though it is not used in the final render, the shader has support for multiple light sources. It also has **rim lighting**, using the Fresnel effect. Also not appearing in the final render is **vertex animation**, for which the shader has some controls for (speed, frequency, distance, amount), allowing for a bobbing-like animation.

To make the shadows more visually interesting, and to match the chosen illustration, a pencil shading texture is applied to it.

<img src="stylization test demo.gif">

### Outlines
The [Sobel edge detection](https://youtu.be/RMt6DcaMxcE) method was use to create the outlines. A transparent pencil hatch texture is mixed with the depth texture to give the outlines a pencil-like texture.

### Full Screen Post-Process Effect
To give the scene an added layer of texture (as in the chosen illustration, the subjects have a general layer of texture, not just in their shadows), the texture of watercolor paper is applied to the entire scene.

### Interactivity
The idea to toggle between the Pokemon's "normal" and "[shiny](https://bulbapedia.bulbagarden.net/wiki/Shiny_Pok%C3%A9mon)" coloration is from [Yikai Li](https://github.com/sqqqqqqs/hw02-stylization/tree/main). For added interest, I also added an "[albino](https://pokefarm.wiki/Pok%C3%A9mon#Albino_Pokemon)" and "[melanistic](https://pokefarm.wiki/Pok%C3%A9mon#Melanistic_Pokemon)" variant, taken from the fangame [Pokefarm Q](https://pokefarm.com/).

## Concept Art
I chose to base my shader off of this illustration by [poqu](https://poqu.tumblr.com/post/770255292288106496/some-grassy-mons).

![](https://64.media.tumblr.com/ba51ac161a2cba2fe761f85606e16051/9c9580fc841c4511-9e/s2048x3072/605b3efeb9c8a4a9840414d500a374ed54344331.jpg)

## References / Credits
- Hatch textures are from [Adobe Stock](https://stock.adobe.com/search?k=pencil+hatching&asset_id=300715364) (shadows) and [Shutterstock](https://pngset.com/download-free-png-dhhwc) (outlines)
- Wtercolor paper texture is from [Painting Valley](https://paintingvalley.com/watercolor-paper#watercolor-paper-37.jpg)
- Model used is by [spritemare](https://skfb.ly/oPRYI)

The assignment instructions can be found [here](https://github.com/CIS-5660-Fall-2026/hw02-stylization).
