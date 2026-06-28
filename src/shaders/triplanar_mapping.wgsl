#define_import_path triplanar_mapping::triplanar_mapping

#import triplanar_mapping::{bindings, triplanar_material}

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

#ifdef PREPASS_PIPELINE
#import bevy_pbr::prepass_io::VertexOutput
#else
#import triplanar_mapping::forward_io::VertexOutput
#endif

// https://github.com/bevyengine/bevy/blob/c6f634ca9f406d68ba5109d921247b654cb42c10/crates/bevy_pbr/src/render/pbr_fragment.wgsl#L36
fn pbr_input_from_vertex_output(
    in: VertexOutput,
    is_front: bool,
    double_sided: bool,
) -> pbr_types::PbrInput {
    var pbr_input: pbr_types::PbrInput = pbr_types::pbr_input_new();

    pbr_input.flags = mesh[in.instance_index].flags;

    pbr_input.is_orthographic = view.clip_from_view[3].w == 1.0;
    pbr_input.V = pbr_functions::calculate_view(in.world_position, pbr_input.is_orthographic);
    pbr_input.frag_coord = in.position;
    pbr_input.world_position = in.world_position;

#ifdef VERTEX_COLORS
    pbr_input.material.base_color = in.color;
#endif

    pbr_input.world_normal = pbr_functions::prepare_world_normal(
        in.world_normal,
        double_sided,
        is_front,
    );

#ifdef LOAD_PREPASS_NORMALS
    pbr_input.N = prepass_utils::prepass_normal(in.position, 0u);
#else
    pbr_input.N = normalize(pbr_input.world_normal);
#endif

    return pbr_input;
}

// Pbr stuff comes from v0.19.0
// https://github.com/bevyengine/bevy/blob/c6f634ca9f406d68ba5109d921247b654cb42c10/crates/bevy_pbr/src/render/pbr_fragment.wgsl#L75
fn pbr_input_from_triplanar_material(
    in: VertexOutput,
    is_front: bool,
) -> pbr_types::PbrInput {
    let slot = mesh[in.instance_index].material_and_lightmap_bind_group_slot & 0xffffu;

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

    var pbr_input: pbr_types::PbrInput = pbr_input_from_vertex_output(in, is_front, double_sided);
    pbr_input.material.flags = standard_material_flags;
    pbr_input.material.base_color *= base_color;
    // pbr_input.material.deferred_lighting_pass_id = deferred_lighting_pass_id;

    // Neubelt and Pettineo 2013, "Crafting a Next-gen Material Pipeline for The Order: 1886"
    let NdotV = max(dot(pbr_input.N, pbr_input.V), 0.0001);

    // Fill in the sample bias so we can sample from textures.
    var bias: SampleBias;
    bias.mip_bias = view.mip_bias;

    if ((standard_material_flags & pbr_types::STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT) != 0u) {
        pbr_input.material.base_color *=
            textureSampleBias(
#ifdef BINDLESS
                bindless_textures_2d[bindings::material_indices[slot].base_color_texture],
                bindless_samplers_filtering[bindings::material_indices[slot].base_color_sampler],
#else   // BINDLESS
                bindings::base_color_texture,
                bindings::base_color_sampler,
#endif  // BINDLESS
                in.uv,
                bias.mip_bias,
        );
    }

    return pbr_input;
}
