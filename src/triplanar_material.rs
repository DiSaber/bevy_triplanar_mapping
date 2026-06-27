use std::path::PathBuf;

use bevy::{
    asset::{Asset, AssetPath, Handle, embedded_path},
    color::{Color, ColorToComponents, LinearRgba},
    image::Image,
    math::Vec4,
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

    /// If the triplanar mapping should be done in local object space.
    pub local_space: bool,

    /// If the triplanar mapping should be corner aligned versus in the center aligned.
    ///
    /// Note: This value only has an effect if `local_space` is `true`.
    // TODO: Maybe make this a vec2 offset instead of constant
    pub corner_align: bool,

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
            local_space: true,
            corner_align: false,
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
        const CORNER_ALIGN = 1 << 1;
        const BLENDING = 1 << 2;
    }
}

/// The GPU representation of the uniform data of a `TriplanarMaterial`.
#[derive(ShaderType)]
struct TriplanarMaterialUniform {
    pub base_color: Vec4,
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
        if material.corner_align {
            triplanar_material_flags |= TriplanarMaterialFlags::CORNER_ALIGN;
        }
        if material.blending.is_some() {
            triplanar_material_flags |= TriplanarMaterialFlags::BLENDING;
        }

        if material.base_color_texture.is_some() {
            standard_material_flags |= StandardMaterialFlags::BASE_COLOR_TEXTURE;
        }

        TriplanarMaterialUniform {
            base_color: LinearRgba::from(material.base_color).to_vec4(),
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
    fn fragment_shader() -> ShaderRef {
        shader_ref(embedded_path!("shaders/fragment.wgsl"))
    }

    fn deferred_fragment_shader() -> ShaderRef {
        shader_ref(embedded_path!("shaders/fragment.wgsl"))
    }
}
