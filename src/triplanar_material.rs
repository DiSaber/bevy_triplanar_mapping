use std::path::PathBuf;

use bevy::{
    asset::{Asset, AssetPath, Handle, embedded_path},
    color::{Color, ColorToComponents, LinearRgba},
    image::Image,
    math::{Vec3, Vec4},
    pbr::{Material, StandardMaterialFlags},
    reflect::{Reflect, std_traits::ReflectDefault},
    render::render_resource::{AsBindGroup, ShaderType},
    shader::ShaderRef,
};

#[derive(Asset, AsBindGroup, Reflect, Debug, Clone)]
#[uniform(0, TriplanarMaterialUniform, binding_array(10))]
#[bindless]
#[reflect(Default, Debug, Clone)]
pub struct TriplanarMaterial {
    /// The sharpness of the blending in transition areas.
    /// Lower -> Smoother transitions, Higher -> Sharper transitions
    ///
    /// Note: Setting this value to `None` will improve performance by only performing a single texture
    /// lookup.
    pub blending: Option<f32>,

    /// The world space offset of the triplanar mapping on each axis.
    pub offset: Vec3,

    /// The world space scale of the triplanar mapping on each axis.
    pub scale: Vec3,

    /// If the triplanar mapping should be done in local object space.
    pub local_space: bool,

    /// How much to offset the mapping in local space, fraction of scale.
    /// Ex: (0.5, 0.5, 0.5) will offset to the corner of unit shapes.
    ///
    /// Note: This value only has an effect if `local_space` is `true`.
    pub local_offset_fraction: Vec3,

    pub base_color: Color,

    #[texture(1)]
    #[sampler(2)]
    #[dependency]
    pub base_color_texture: Option<Handle<Image>>,
}

impl Default for TriplanarMaterial {
    fn default() -> Self {
        Self {
            blending: Some(8.0),
            offset: Vec3::ZERO,
            scale: Vec3::ONE,
            local_space: false,
            local_offset_fraction: Vec3::ZERO,
            base_color: Color::WHITE,
            base_color_texture: None,
        }
    }
}

// NOTE: These must match the bit flags in src/shaders/types.wgsl
bitflags::bitflags! {
    #[repr(transparent)]
    pub struct TriplanarMaterialFlags: u32 {
        const LOCAL_SPACE = 1 << 0;
        const BLENDING = 1 << 1;
    }
}

/// The GPU representation of the uniform data of a `TriplanarMaterial`.
#[derive(ShaderType)]
struct TriplanarMaterialUniform {
    pub base_color: Vec4,
    pub offset: Vec3,
    pub scale: Vec3,
    pub local_offset_fraction: Vec3,
    pub blending: f32,
    pub triplanar_material_flags: u32,
    pub standard_material_flags: u32,
}

impl<'a> From<&'a TriplanarMaterial> for TriplanarMaterialUniform {
    fn from(material: &'a TriplanarMaterial) -> Self {
        let mut triplanar_material_flags = TriplanarMaterialFlags::empty();
        let mut standard_material_flags = StandardMaterialFlags::empty();

        if material.local_space {
            triplanar_material_flags |= TriplanarMaterialFlags::LOCAL_SPACE;
        }
        if material.blending.is_some() {
            triplanar_material_flags |= TriplanarMaterialFlags::BLENDING;
        }

        if material.base_color_texture.is_some() {
            standard_material_flags |= StandardMaterialFlags::BASE_COLOR_TEXTURE;
        }

        TriplanarMaterialUniform {
            base_color: LinearRgba::from(material.base_color).to_vec4(),
            offset: material.offset,
            scale: material.scale,
            local_offset_fraction: material.local_offset_fraction,
            blending: material.blending.unwrap_or_default(),
            triplanar_material_flags: triplanar_material_flags.bits(),
            standard_material_flags: standard_material_flags.bits(),
        }
    }
}

fn shader_ref(path: PathBuf) -> ShaderRef {
    ShaderRef::Path(AssetPath::from_path_buf(path).with_source("embedded"))
}

impl Material for TriplanarMaterial {
    fn vertex_shader() -> ShaderRef {
        shader_ref(embedded_path!("shaders/vertex.wgsl"))
    }

    fn deferred_vertex_shader() -> ShaderRef {
        shader_ref(embedded_path!("shaders/vertex.wgsl"))
    }

    // TODO
    fn prepass_vertex_shader() -> ShaderRef {
        ShaderRef::Default
    }

    fn fragment_shader() -> ShaderRef {
        shader_ref(embedded_path!("shaders/fragment.wgsl"))
    }

    fn deferred_fragment_shader() -> ShaderRef {
        shader_ref(embedded_path!("shaders/fragment.wgsl"))
    }

    // TODO
    fn prepass_fragment_shader() -> ShaderRef {
        ShaderRef::Default
    }
}
