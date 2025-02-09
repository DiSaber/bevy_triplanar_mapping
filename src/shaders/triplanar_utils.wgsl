#define_import_path triplanar_utils

#import bevy_pbr::{pbr_functions, pbr_functions::{SampleBias, sample_texture}}
#import triplanar_types::triplanar_extension;

struct TriplanarMapping {
    // Weights for blending between the planes
    w: vec3<f32>,

    // uv if no blending
    uv_x: vec2<f32>,
    // dpdx if no blending
    uv_y: vec2<f32>,
    // dpdy if no blending
    uv_z: vec2<f32>,
};

fn calculate_triplanar_mapping(p: vec3<f32>, in_n: vec3<f32>, uv_t: mat3x3<f32>, object_scale: vec3<f32>) -> TriplanarMapping {
    let n = abs(in_n);

    var uv_x = p.yz;
    var uv_y = p.zx;
    var uv_z = p.yx;

    // Only align if local space and corner alignment is set
    if ((triplanar_extension.flags & triplanar_types::LOCAL_SPACE_BIT) != 0u) && ((triplanar_extension.flags & triplanar_types::CORNER_ALIGN_BIT) != 0u) {
        uv_x += object_scale.yz / 2.0;
        uv_y += object_scale.zx / 2.0;
        uv_z += object_scale.yx / 2.0;
    }

    // Apply uv transform
    uv_x = (uv_t * vec3(uv_x, 1.0)).xy;
    uv_y = (uv_t * vec3(uv_y, 1.0)).xy;
    uv_z = (uv_t * vec3(uv_z, 1.0)).xy;

    if ((triplanar_extension.flags & triplanar_types::NO_BLENDING_BIT) != 0u) {
        // Calculate derivatives for each uv
        let x_dpdx = dpdx(uv_x);
        let x_dpdy = dpdy(uv_x);
        let y_dpdx = dpdx(uv_y);
        let y_dpdy = dpdy(uv_y);
        let z_dpdx = dpdx(uv_z);
        let z_dpdy = dpdy(uv_z);

        var uv: vec2<f32>;
        var dpdx: vec2<f32>;
        var dpdy: vec2<f32>;

        if n.x > n.y && n.x > n.z {
            uv = uv_x;
            dpdx = x_dpdx;
            dpdy = x_dpdy;
        } else if n.y > n.z {
            uv = uv_y;
            dpdx = y_dpdx;
            dpdy = y_dpdy;
        } else {
            uv = uv_z;
            dpdx = z_dpdx;
            dpdy = z_dpdy;
        }

        return TriplanarMapping(vec3<f32>(), uv, dpdx, dpdy);
    } else {
        var w = pow(n, vec3(triplanar_extension.blending));
        w /= w.x + w.y + w.z;

        return TriplanarMapping(w, uv_x, uv_y, uv_z);
    }
}

fn triplanar_texture(
    tex: texture_2d<f32>,
    samp: sampler,
    tm: TriplanarMapping,
    bias: SampleBias
) -> vec4<f32> {
    if ((triplanar_extension.flags & triplanar_types::NO_BLENDING_BIT) != 0u) {
        // uv_y and uv_z are dpdx and dpdy respectively
        return textureSampleGrad(tex, samp, tm.uv_x, tm.uv_y, tm.uv_z);
    } else {
        let x = pbr_functions::sample_texture(tex, samp, tm.uv_x, bias);
        let y = pbr_functions::sample_texture(tex, samp, tm.uv_y, bias);
        let z = pbr_functions::sample_texture(tex, samp, tm.uv_z, bias);

        return tm.w.x * x + tm.w.y * y + tm.w.z * z;
    }
}

