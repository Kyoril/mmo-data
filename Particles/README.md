# Particle System Default Materials

## Required Materials

### Additive.hmat
- **Location**: data/client/Particles/Additive.hmat
- **Type**: MaterialType::Translucent
- **Blend Mode**: Additive (src=One, dst=One)
- **Depth Write**: Disabled
- **Depth Test**: Enabled  
- **Two-Sided**: True
- **Purpose**: Bright, glowing particles (fire, sparks, magic effects)

### Alpha.hmat
- **Location**: data/client/Particles/Alpha.hmat
- **Type**: MaterialType::Translucent
- **Blend Mode**: Alpha (src=SrcAlpha, dst=InvSrcAlpha)
- **Depth Write**: Disabled
- **Depth Test**: Enabled
- **Two-Sided**: True
- **Purpose**: Standard transparent particles (smoke, dust, water splash)

## Creation Instructions

These materials should be created using the material editor (mmo_edit) with the following settings:

1. Create new material
2. Set material type to Translucent
3. Configure blend settings as specified above
4. Disable depth write (critical for transparency)
5. Enable two-sided rendering
6. Add texture parameter 'ParticleTexture' with default white texture
7. Pixel shader: texture * vertex color
8. Save to data/client/Particles/

## Default Texture

A 1x1 white texture (data/client/Textures/white.htex) is used as the default
so vertex colors control the particle appearance.
