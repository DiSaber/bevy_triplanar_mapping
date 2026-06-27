#define_import_path triplanar_mapping::bindings

#import triplanar_mapping::types::TriplanarMaterial;

#ifdef BINDLESS

struct TriplanarMaterialBindings {
    material: u32,           // 0
    base_color_texture: u32, // 1
    base_color_sampler: u32, // 2
}

@group(#{MATERIAL_BIND_GROUP}) @binding(0) var<storage> material_indices: array<TriplanarMaterialBindings>;
@group(#{MATERIAL_BIND_GROUP}) @binding(10) var<storage> material_array: binding_array<TriplanarMaterial>;

#else   // BINDLESS

@group(#{MATERIAL_BIND_GROUP}) @binding(0) var<uniform> material: TriplanarMaterial;
@group(#{MATERIAL_BIND_GROUP}) @binding(1) var base_color_texture: texture_2d<f32>;
@group(#{MATERIAL_BIND_GROUP}) @binding(2) var base_color_sampler: sampler;

#endif  // BINDLESS
