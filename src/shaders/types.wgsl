#define_import_path triplanar_mapping::types

struct TriplanarMaterial {
    base_color: vec4<f32>,
    blending: f32,
    triplanar_material_flags: u32,
    standard_material_flags: u32,
}

const LOCAL_SPACE_BIT: u32 = 1u << 0u;
const CORNER_ALIGN_BIT: u32 = 1u << 1u;
const BLENDING_BIT: u32 = 1u << 2u;
