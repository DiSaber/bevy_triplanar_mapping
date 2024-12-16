#define_import_path triplanar_types

struct TriplanarExtension {
    uv_scale: f32,
    blending: f32,
    flags: u32
}

const LOCAL_SPACE_BIT: u32 = 1u;
const CORNER_ALIGN_BIT: u32 = 2u;

@group(2) @binding(100)
var<uniform> triplanar_extension: TriplanarExtension;
