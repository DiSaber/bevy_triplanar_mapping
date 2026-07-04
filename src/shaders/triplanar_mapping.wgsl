#define_import_path triplanar_mapping::triplanar_mapping

#import triplanar_mapping::{
    bindings,
    triplanar_material
}

#import bevy_render::bindless::{bindless_samplers_filtering, bindless_textures_2d}
#import bevy_pbr::{
    mesh_bindings::mesh,
    pbr_functions::SampleBias,
};

#ifdef PREPASS_PIPELINE
#import bevy_pbr::prepass_io::VertexOutput
#else
#import triplanar_mapping::forward_io::VertexOutput
#endif

struct TriplanarMapping {
    in: VertexOutput,
#ifdef NORMAL_MAP
	// Normal used in the mapping
	n: vec3<f32>,
#endif
	// Weights for blending between the planes
	w: vec3<f32>,
	// uv if no blending
	uv_x: vec2<f32>,
	// duvdx if no blending
	uv_y: vec2<f32>,
	// duvdy if no blending
	uv_z: vec2<f32>,
}


// May need to get blending uniform directly
fn calculate_triplanar_mapping(in: VertexOutput) -> TriplanarMapping {
#ifdef BINDLESS
    let slot = mesh[in.instance_index].material_and_lightmap_bind_group_slot & 0xffffu;
    let blending = bindings::material_array[bindings::material_indices[slot].material].blending;
    let triplanar_material_flags = bindings::material_array[bindings::material_indices[slot].material].triplanar_material_flags;
#else   // BINDLESS
    let blending = bindings::material.blending;
    let triplanar_material_flags = bindings::material.triplanar_material_flags;
#endif  // BINDLESS

    let p = in.triplanar_position;
    let n = normalize(in.triplanar_normal);
	let abs_n = abs(n);

	// Godot TODO: Figure out why these transformations fix normal mapping
    // TODO: Is this the same with bevy?
	let uv_x = p.zy * vec2<f32>(1.0, -1.0);
	let uv_y = p.xz * vec2<f32>(1.0, -1.0);
	let uv_z = p.xy * vec2<f32>(1.0, -1.0);

    var triplanar_mapping: TriplanarMapping;
    triplanar_mapping.in = in;

	if ((triplanar_material_flags & triplanar_material::BLENDING_BIT) != 0u) {
		var w = pow(abs_n, vec3<f32>(blending));
		w /= w.x + w.y + w.z;

#ifdef NORMAL_MAP
        triplanar_mapping.n = n;
#endif
        triplanar_mapping.w = w;
        triplanar_mapping.uv_x = uv_x;
        triplanar_mapping.uv_y = uv_y;
        triplanar_mapping.uv_z = uv_z;
	} else {
		// Use explicit gradients to prevent seams between each xyz plane
		let dpdx = dpdx(p);
		let dpdy = dpdy(p);

		var uv: vec2<f32>;
		var duvdx: vec2<f32>;
		var duvdy: vec2<f32>;

		// Select uv based on dominant normal direction
		if (abs_n.x > abs_n.y && abs_n.x > abs_n.z) {
			uv = uv_x;
			duvdx = dpdx.zy;
			duvdy = dpdy.zy;
		} else if (abs_n.y > abs_n.z) {
			uv = uv_y;
			duvdx = dpdx.xz;
			duvdy = dpdy.xz;
		} else {
			uv = uv_z;
			duvdx = dpdx.xy;
			duvdy = dpdy.xy;
		}

#ifdef NORMAL_MAP
        triplanar_mapping.n = n;
#endif
        triplanar_mapping.w = vec3<f32>(0.0);
        triplanar_mapping.uv_x = uv;
        triplanar_mapping.uv_y = duvdx;
        triplanar_mapping.uv_z = duvdy;
	}

    return triplanar_mapping;
}

fn sample_base_color_triplanar(
    triplanar_mapping: TriplanarMapping,
    bias: SampleBias
) -> vec4<f32> {
#ifdef BINDLESS
    let slot = mesh[triplanar_mapping.in.instance_index].material_and_lightmap_bind_group_slot & 0xffffu;
    let triplanar_material_flags = bindings::material_array[bindings::material_indices[slot].material].triplanar_material_flags;
#else   // BINDLESS
    let triplanar_material_flags = bindings::material.triplanar_material_flags;
#endif  // BINDLESS

	if ((triplanar_material_flags & triplanar_material::BLENDING_BIT) != 0u) {
        let x = textureSampleBias(
#ifdef BINDLESS
            bindless_textures_2d[bindings::material_indices[slot].base_color_texture],
            bindless_samplers_filtering[bindings::material_indices[slot].base_color_sampler],
#else   // BINDLESS
            bindings::base_color_texture,
            bindings::base_color_sampler,
#endif  // BINDLESS
            triplanar_mapping.uv_x,
            bias.mip_bias
        );
        let y = textureSampleBias(
#ifdef BINDLESS
            bindless_textures_2d[bindings::material_indices[slot].base_color_texture],
            bindless_samplers_filtering[bindings::material_indices[slot].base_color_sampler],
#else   // BINDLESS
            bindings::base_color_texture,
            bindings::base_color_sampler,
#endif  // BINDLESS
            triplanar_mapping.uv_y,
            bias.mip_bias
        );
        let z = textureSampleBias(
#ifdef BINDLESS
            bindless_textures_2d[bindings::material_indices[slot].base_color_texture],
            bindless_samplers_filtering[bindings::material_indices[slot].base_color_sampler],
#else   // BINDLESS
            bindings::base_color_texture,
            bindings::base_color_sampler,
#endif  // BINDLESS
            triplanar_mapping.uv_z,
            bias.mip_bias
        );
		return triplanar_mapping.w.x * x + triplanar_mapping.w.y * y + triplanar_mapping.w.z * z;
	} else {
		// uv_y and uv_z are duvdx and duvdy respectively
        return textureSampleGrad(
#ifdef BINDLESS
            bindless_textures_2d[bindings::material_indices[slot].base_color_texture],
            bindless_samplers_filtering[bindings::material_indices[slot].base_color_sampler],
#else   // BINDLESS
            bindings::base_color_texture,
            bindings::base_color_sampler,
#endif  // BINDLESS
            triplanar_mapping.uv_x,
            triplanar_mapping.uv_y,
            triplanar_mapping.uv_z
        );
	}
}
