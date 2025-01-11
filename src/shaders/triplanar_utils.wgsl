#define_import_path triplanar_utils

#import bevy_pbr::{pbr_functions, pbr_functions::{SampleBias, sample_texture}}
#import triplanar_types::triplanar_extension;

// From: https://github.com/bonsairobo/bevy_triplanar_splatting/blob/main/src/shaders/triplanar.wgsl
// ----------------------- ----------------------- //
struct TriplanarMapping {
    // Weights for blending between the planes or abs(normal) if the no blending bit is set
    w_or_n: vec3<f32>,

    uv_x: vec2<f32>,
    uv_y: vec2<f32>,
    uv_z: vec2<f32>,

    // Used when the no blending bit is set
    dpdx: vec3<f32>,
    dpdy: vec3<f32>,
};

fn calculate_triplanar_mapping(p: vec3<f32>, in_n: vec3<f32>) -> TriplanarMapping {
    let n = abs(in_n);
    var w_or_n: vec3<f32>;
    var dpdx: vec3<f32>;
    var dpdy: vec3<f32>;

    if ((triplanar_extension.flags & triplanar_types::NO_BLENDING_BIT) != 0u) {
        w_or_n = n;
        dpdx = dpdx(p);
        dpdy = dpdy(p);
    } else {
        w_or_n = pow(n, vec3(triplanar_extension.blending));
        w_or_n /= w_or_n.x + w_or_n.y + w_or_n.z;
    }

    return TriplanarMapping(w_or_n, p.yz, p.zx, p.yx, dpdx, dpdy);
}
// ----------------------- ----------------------- //

fn triplanar_texture(
    tex: texture_2d<f32>,
    samp: sampler,
    tm: TriplanarMapping,
    bias: SampleBias
) -> vec4<f32> {
    if ((triplanar_extension.flags & triplanar_types::NO_BLENDING_BIT) != 0u) {
        let n = tm.w_or_n;
        var uv: vec2<f32>;
        var dpdx: vec2<f32>;
        var dpdy: vec2<f32>;

        if n.x > n.y && n.x > n.z {
            uv = tm.uv_x;
            dpdx = tm.dpdx.yz;
            dpdy = tm.dpdy.yz;
        } else if n.y > n.z {
            uv = tm.uv_y;
            dpdx = tm.dpdx.zx;
            dpdy = tm.dpdy.zx;
        } else {
            uv = tm.uv_z;
            dpdx = tm.dpdx.yx;
            dpdy = tm.dpdy.yx;
        }

        return textureSampleGrad(tex, samp, uv, dpdx, dpdy);
    } else {
        let x = pbr_functions::sample_texture(tex, samp, tm.uv_x, bias);
        let y = pbr_functions::sample_texture(tex, samp, tm.uv_y, bias);
        let z = pbr_functions::sample_texture(tex, samp, tm.uv_z, bias);
        let w = tm.w_or_n;
        return w.x * x + w.y * y + w.z * z;
    }
}

