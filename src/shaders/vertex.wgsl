#import triplanar_mapping::{
    bindings,
    triplanar_material,
    forward_io::VertexOutput
}

#import bevy_pbr::{
    mesh_bindings::mesh,
    mesh_functions,
    skinning,
    morph::{morph_position, morph_normal, morph_tangent},
    forward_io::Vertex,
    view_transformations::position_world_to_clip,
}

#ifdef MORPH_TARGETS
// The instance_index parameter must match vertex_in.instance_index. This is a work around for a wgpu dx12 bug.
// See https://github.com/gfx-rs/naga/issues/2416
fn morph_vertex(vertex_in: Vertex, instance_index: u32) -> Vertex {
    var vertex = vertex_in;
    let first_vertex = mesh[instance_index].first_vertex_index;
    let vertex_index = vertex.index - first_vertex;

    let weight_count = bevy_pbr::morph::layer_count(instance_index);
    for (var i: u32 = 0u; i < weight_count; i ++) {
        let weight = bevy_pbr::morph::weight_at(i, instance_index);
        if weight == 0.0 {
            continue;
        }
        vertex.position += weight * morph_position(vertex_index, i, instance_index);
#ifdef VERTEX_NORMALS
        vertex.normal += weight * morph_normal(vertex_index, i, instance_index);
#endif
#ifdef VERTEX_TANGENTS
        vertex.tangent += vec4(weight * morph_tangent(vertex_index, i, instance_index), 0.0);
#endif
    }
    return vertex;
}
#endif

@vertex
fn vertex(vertex_no_morph: Vertex) -> VertexOutput {
    var out: VertexOutput;

#ifdef MORPH_TARGETS
    var vertex = morph_vertex(vertex_no_morph, vertex_no_morph.instance_index);
#else
    var vertex = vertex_no_morph;
#endif

    let mesh_world_from_local = mesh_functions::get_world_from_local(vertex_no_morph.instance_index);

#ifdef SKINNED
    // Use vertex_no_morph.instance_index instead of vertex.instance_index to work around a wgpu dx12 bug.
    // See https://github.com/gfx-rs/naga/issues/2416 .
    var world_from_local = skinning::skin_model(
        vertex.joint_indices,
        vertex.joint_weights,
        vertex_no_morph.instance_index
    );
#else
    var world_from_local = mesh_world_from_local;
#endif

#ifdef VERTEX_NORMALS
#ifdef SKINNED
    out.world_normal = skinning::skin_normals(world_from_local, vertex.normal);
#else
    out.world_normal = mesh_functions::mesh_normal_local_to_world(
        vertex.normal,
        // Use vertex_no_morph.instance_index instead of vertex.instance_index to work around a wgpu dx12 bug.
        // See https://github.com/gfx-rs/naga/issues/2416
        vertex_no_morph.instance_index
    );
#endif
#endif

#ifdef VERTEX_POSITIONS
    out.world_position = mesh_functions::mesh_position_local_to_world(world_from_local, vec4<f32>(vertex.position, 1.0));
    out.position = position_world_to_clip(out.world_position.xyz);
#endif

#ifdef VERTEX_UVS_A
    out.uv = vertex.uv;
#endif
#ifdef VERTEX_UVS_B
    out.uv_b = vertex.uv_b;
#endif

#ifdef VERTEX_TANGENTS
    out.world_tangent = mesh_functions::mesh_tangent_local_to_world(
        world_from_local,
        vertex.tangent,
        // Use vertex_no_morph.instance_index instead of vertex.instance_index to work around a wgpu dx12 bug.
        // See https://github.com/gfx-rs/naga/issues/2416
        vertex_no_morph.instance_index
    );
#endif

#ifdef VERTEX_COLORS
    out.color = vertex.color;
#endif

#ifdef VERTEX_OUTPUT_INSTANCE_INDEX
    // Use vertex_no_morph.instance_index instead of vertex.instance_index to work around a wgpu dx12 bug.
    // See https://github.com/gfx-rs/naga/issues/2416
    out.instance_index = vertex_no_morph.instance_index;
#endif

#ifdef VISIBILITY_RANGE_DITHER
    out.visibility_range_dither = mesh_functions::get_visibility_range_dither_level(
        vertex_no_morph.instance_index, mesh_world_from_local[3]
    );
#endif

#ifdef BINDLESS
    let slot = mesh[vertex_no_morph.instance_index].material_and_lightmap_bind_group_slot & 0xffffu;
    let offset = bindings::material_array[bindings::material_indices[slot].material].offset;
    let scale = bindings::material_array[bindings::material_indices[slot].material].scale;
    let local_offset_fraction = bindings::material_array[bindings::material_indices[slot].material].local_offset_fraction;
    let triplanar_material_flags = bindings::material_array[bindings::material_indices[slot].material].triplanar_material_flags;
#else   // BINDLESS
    let offset = bindings::material.offset;
    let scale = bindings::material.scale;
    let local_offset_fraction = bindings::material.local_offset_fraction;
    let triplanar_material_flags = bindings::material.triplanar_material_flags;
#endif  // BINDLESS


    if ((triplanar_material_flags & triplanar_material::LOCAL_SPACE_BIT) != 0u) {
        let world_from_local3x3 = mat3x3<f32>(
            world_from_local[0].xyz,
            world_from_local[1].xyz,
            world_from_local[2].xyz,
        );
        let mesh_scale = vec3<f32>(length(world_from_local3x3[0]), length(world_from_local3x3[1]), length(world_from_local3x3[2]));

        out.triplanar_position = vertex.position * mesh_scale;
        out.triplanar_position += (mesh_scale * local_offset_fraction) / 2.0;
#ifdef VERTEX_NORMALS
        out.triplanar_normal = normalize(vertex.normal / mesh_scale);
#endif
    } else {
        out.triplanar_position = out.world_position.xyz;
#ifdef VERTEX_NORMALS
        out.triplanar_normal = out.world_normal;
#endif
    }

    out.triplanar_position = (out.triplanar_position / scale) - offset;

    return out;
}
