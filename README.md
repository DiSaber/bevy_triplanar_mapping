# bevy_triplanar_mapping
Triplanar mapping for the Bevy game engine. Takes inspiration from [bevy_triplanar_splatting](https://github.com/bonsairobo/bevy_triplanar_splatting).
*Note: Only supports triplanar mapping for the `base_color_texture` at the moment*

## Usage 
Simply add the `TriplanarMappingPlugin` to your app and create triplanar materials using `ExtendedMaterial<StandardMaterial, TriplanarExtension>`.

`TriplanarExtension` can be configured to set the uv scale of the mapping: `TriplanarExtension { uv_scale: 5.0 }`
