

# HW 2: *3D Stylization*

https://github.com/user-attachments/assets/f4f31264-83cf-453f-8a09-f7ef4141b73b

## Project Overview:
This is my second homework for the procedural graphics course CIS5660 at UPenn.
My task was to take a reference a piece of art and to try to remake it in unity shaders.
The reference I chose are the Zelda 1 Dungeon art concepts by Philip Summers [(@heyphilsummers)](https://x.com/heyphilsummers/status/2074174558202892666?s=20)  

<img width="500" height="417" alt="PureRef-copy-2026 10 07-05 14 01" src="https://github.com/user-attachments/assets/78addd7f-2242-4bc2-b669-e36a75339e56" /> <img width="500" height="400" alt="PureRef-copy-2026 10 07-05 17 22" src="https://github.com/user-attachments/assets/04a4facf-da32-4a6c-ab5d-2ff4c951f71e" />

## Features:
First of all, The base of my shader is the Toon shader implemented in the lab.
I added the option for additional lights to affect the diffuse and tint the color.

### Shadows
I changed the shadow texture to match the pen style shadow of the sketches in the reference. I also have a tunable black band around the shadows. These are calculated by raising the shadow quality and stepping the shadow attenuation to find when it's somewhere between 0 and 1.
I baked two textures into the tileable shadow texture by painting part of the edges of the image in a lighter grayscale value.
I use this lighter variant for certain materials, with the idea being that these shadows would tile with the darker variant as well.

### Texture
In order to replicate the artstyle of the source image, I add a 3D gradient noise to the diffuse and I darken the colors at the edges of the toon shaded bands. 
The Shadow and midtone use separate noise UVs to better immitate how the color strokes overlap unevenly in the art.

I didn't end up implementing specular shading, I felt that it didn't match the reference too well since my highlights were already pure white and quite large. I do however incorporate the diffuse light in my outline which I will explain below.
## Animated Material
In the video above you can see the third character on the right has the animated material variant, I decided to interpolate between the three colors of the material, which I achieve by cycling the diffuse value. I used a gain function to have the colors pause at regular intervals:
```hlsl
float s = 0.9 * Time;
Diffuse += (floor(s) + Gain(frac(s), 0.8)) / 3.0;  //pauses at 1/6, 0.5, 5/6.
Diffuse = frac(Diffuse);
float DiffuseLow = NoiseFactory(WorldPos, Diffuse, 0.);
float DiffuseHigh = NoiseFactory(WorldPos, Diffuse, 13.1);
```
## Outlines
I used sobel outlines from the tutorial and I segment it using a noise function to try to make it look more sketch-like. I also played with the thickness and added a UVWarp to make it look more natural.
Additionally, I disable the outline at the parts of the model which are brightest. I do this by calculating the lambert shading using the main light direction and the normal texture given to the post processor.
In order for the lines to correctly be hidden, I take the offsets of the sobel filter and calculate this diffuse for each of the 9 sample points, and take the maximum of those measurements. Any other method leaves artifacts like halves of edges in the render.
The outlines noise function moves around every second.

## Full screen Post processing
I overlayed a paper texture to desaturate the colors and add the grain to the render. I also added the dots seen on screen in this step.

## Interactivity
Two of the models have materials that change at the press of the space key. Additionally, holding down the E key sucks all the color out of the scene, and releasing it slowly causes it to return.
