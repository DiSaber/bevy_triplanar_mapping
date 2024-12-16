#define_import_path triplanar_types

struct TriplanarExtension {
    uv_scale: f32,
    blending: f32,
    local_space: u32,
}

@group(2) @binding(100)
var<uniform> triplanar_extension: TriplanarExtension;
