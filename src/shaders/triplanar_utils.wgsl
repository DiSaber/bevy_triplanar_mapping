#define_import_path triplanar_utils

#import bevy_pbr::{pbr_functions, pbr_functions::{SampleBias, sample_texture}}

struct TriplanarMapping {
    // Weights for blending between the planes
    w: vec3<f32>,

    uv_x: vec2<f32>,
    uv_y: vec2<f32>,
    uv_z: vec2<f32>,
};

fn calculate_triplanar_mapping(p: vec3<f32>, n: vec3<f32>, k: f32) -> TriplanarMapping {
    var w = pow(abs(n), vec3(k));
    w = w / (w.x + w.y + w.z);
    return TriplanarMapping(w, p.yz, p.zx, p.xy);
}

fn triplanar_texture(
    tex: texture_2d<f32>,
    samp: sampler,
    tm: TriplanarMapping,
    bias: SampleBias
) -> vec4<f32> {
    let x = pbr_functions::sample_texture(tex, samp, tm.uv_x, bias);
    let y = pbr_functions::sample_texture(tex, samp, tm.uv_y, bias);
    let z = pbr_functions::sample_texture(tex, samp, tm.uv_z, bias);
    return tm.w.x * x + tm.w.y * y + tm.w.z * z;
}

