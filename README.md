# bevy_triplanar_mapping
Triplanar mapping for the Bevy game engine. Takes inspiration from [bevy_triplanar_splatting](https://github.com/bonsairobo/bevy_triplanar_splatting).
*Note: Only supports triplanar mapping for the `base_color_texture` at the moment*

## Usage 
Simply add the `TriplanarMappingPlugin` to your app and create triplanar materials using `TriplanarMaterial` (or `ExtendedMaterial<StandardMaterial, TriplanarExtension>` directly).

`TriplanarExtension` can be configured with various options that change the mapping:
```
TriplanarExtension { 
    blending: 15.0,
    local_space: false,
    ..Default::default() 
}
```
You can change the scale of the mapping by using the `uv_transform` property on the base `StandardMaterial`:
```
triplanar_material.base.uv_transform = Affine2::from_scale(Vec2::splat(uv_scale));
```
