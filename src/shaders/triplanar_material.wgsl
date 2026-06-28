#define_import_path triplanar_mapping::triplanar_material

struct TriplanarMaterial {
    base_color: vec4<f32>,
    offset: vec3<f32>,
    scale: vec3<f32>,
    local_offset_fraction: vec3<f32>,
    blending: f32,
    triplanar_material_flags: u32,
    standard_material_flags: u32,
}

const LOCAL_SPACE_BIT: u32 = 1u << 0u;
const BLENDING_BIT: u32 = 1u << 1u;
