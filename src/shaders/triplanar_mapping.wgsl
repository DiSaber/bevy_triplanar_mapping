#define_import_path triplanar_mapping::triplanar_mapping

#import triplanar_mapping::{bindings, types}

#import bevy_render::bindless::{bindless_samplers_filtering, bindless_textures_2d}

#import bevy_pbr::{
    pbr_fragment,
    pbr_functions,
    pbr_functions::SampleBias,
    pbr_types,
    prepass_utils,
    lighting,
    mesh_bindings::mesh,
    mesh_view_bindings::view,
    parallax_mapping::parallaxed_uv,
    lightmap::lightmap,
}

#ifdef SCREEN_SPACE_AMBIENT_OCCLUSION
#import bevy_pbr::mesh_view_bindings::screen_space_ambient_occlusion_texture
#import bevy_pbr::ssao_utils::ssao_multibounce
#endif

#ifdef MESHLET_MESH_MATERIAL_PASS
#import bevy_pbr::meshlet_visibility_buffer_resolve::VertexOutput
#else ifdef PREPASS_PIPELINE
#import bevy_pbr::prepass_io::VertexOutput
#else
#import bevy_pbr::forward_io::VertexOutput
#endif

// Pbr stuff comes from v0.19.0
// https://github.com/bevyengine/bevy/blob/c6f634ca9f406d68ba5109d921247b654cb42c10/crates/bevy_pbr/src/render/pbr_fragment.wgsl#L75
fn pbr_input_from_triplanar_material(
    in: VertexOutput,
    is_front: bool,
) -> pbr_types::PbrInput {
#ifdef MESHLET_MESH_MATERIAL_PASS
    let slot = in.material_bind_group_slot;
#else   // MESHLET_MESH_MATERIAL_PASS
    let slot = mesh[in.instance_index].material_and_lightmap_bind_group_slot & 0xffffu;
#endif  // MESHLET_MESH_MATERIAL_PASS

#ifdef BINDLESS
    let triplanar_material_flags = bindings::material_array[bindings::material_indices[slot].material].triplanar_material_flags;
    let standard_material_flags = bindings::material_array[bindings::material_indices[slot].material].standard_material_flags;
    let base_color = bindings::material_array[bindings::material_indices[slot].material].base_color;
    // TODO: Add this parameter
    // let deferred_lighting_pass_id =
    // pbr_bindings::material_array[material_indices[slot].material].deferred_lighting_pass_id;
    // let alpha_cutoff = pbr_bindings::material_array[material_indices[slot].material].alpha_cutoff;
#else   // BINDLESS
    let triplanar_material_flags = bindings::material.triplanar_material_flags;
    let standard_material_flags = bindings::material.standard_material_flags;
    let base_color = bindings::material.base_color;
    // let deferred_lighting_pass_id = pbr_bindings::material.deferred_lighting_pass_id;
    // let alpha_cutoff = pbr_bindings::material.alpha_cutoff;
#endif  // BINDLESS


    let double_sided = (standard_material_flags & pbr_types::STANDARD_MATERIAL_FLAGS_DOUBLE_SIDED_BIT) != 0u;

    var pbr_input: pbr_types::PbrInput = pbr_fragment::pbr_input_from_vertex_output(in, is_front, double_sided);
    pbr_input.material.flags = standard_material_flags;
    pbr_input.material.base_color *= base_color;
    // pbr_input.material.deferred_lighting_pass_id = deferred_lighting_pass_id;

    // Neubelt and Pettineo 2013, "Crafting a Next-gen Material Pipeline for The Order: 1886"
    let NdotV = max(dot(pbr_input.N, pbr_input.V), 0.0001);

    // Fill in the sample bias so we can sample from textures.
    var bias: SampleBias;
#ifdef MESHLET_MESH_MATERIAL_PASS
    bias.ddx_uv = in.ddx_uv;
    bias.ddy_uv = in.ddy_uv;
#else   // MESHLET_MESH_MATERIAL_PASS
    bias.mip_bias = view.mip_bias;
#endif  // MESHLET_MESH_MATERIAL_PASS

    if ((standard_material_flags & pbr_types::STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT) != 0u) {
        pbr_input.material.base_color *=
#ifdef MESHLET_MESH_MATERIAL_PASS
            textureSampleGrad(
#else   // MESHLET_MESH_MATERIAL_PASS
            textureSampleBias(
#endif  // MESHLET_MESH_MATERIAL_PASS
#ifdef BINDLESS
                bindless_textures_2d[bindings::material_indices[slot].base_color_texture],
                bindless_samplers_filtering[bindings::material_indices[slot].base_color_sampler],
#else   // BINDLESS
                bindings::base_color_texture,
                bindings::base_color_sampler,
#endif  // BINDLESS
                in.uv,
#ifdef MESHLET_MESH_MATERIAL_PASS
                bias.ddx_uv,
                bias.ddy_uv,
#else   // MESHLET_MESH_MATERIAL_PASS
                bias.mip_bias,
#endif  // MESHLET_MESH_MATERIAL_PASS
        );
    }

    return pbr_input;
}
