use bevy::{
    asset::Asset,
    pbr::MaterialExtension,
    reflect::Reflect,
    render::{
        render_asset::RenderAssets,
        render_resource::{AsBindGroup, AsBindGroupShaderType, ShaderRef, ShaderType},
        texture::GpuImage,
    },
};

use crate::TRIPLANAR_EXTENSION_SHADER_HANDLE;

#[derive(Asset, AsBindGroup, Reflect, Debug, Clone)]
#[uniform(100, TriplanarExtensionUniform)]
pub struct TriplanarExtension {
    /// The sharpness of the blending in transition areas. (default: 8.0)
    /// Lower -> Smoother transitions, Higher -> Sharper transitions
    ///
    /// Note: Setting this value to `None` will improve performance by only performing a single texture
    /// lookup.
    pub blending: Option<f32>,

    /// If the triplanar mapping should be done in local object space. (default: true)
    pub local_space: bool,

    /// If the triplanar mapping should be corner aligned versus in the center aligned (default: false)
    ///
    /// Note: This value only has an effect if `local_space` is true
    pub corner_align: bool,
}

impl Default for TriplanarExtension {
    fn default() -> Self {
        Self {
            blending: Some(8.0),
            local_space: true,
            corner_align: false,
        }
    }
}

/// The GPU representation of the uniform data of a [`TriplanarExtension`].
#[derive(Clone, Default, ShaderType)]
struct TriplanarExtensionUniform {
    pub blending: f32,
    pub flags: u32,
}

impl AsBindGroupShaderType<TriplanarExtensionUniform> for TriplanarExtension {
    fn as_bind_group_shader_type(&self, _: &RenderAssets<GpuImage>) -> TriplanarExtensionUniform {
        let mut flags = 0_u32;
        if self.local_space {
            flags |= 1;
        }
        if self.corner_align {
            flags |= 2;
        }
        if self.blending.is_none() {
            flags |= 4;
        }

        TriplanarExtensionUniform {
            blending: self.blending.unwrap_or_default(),
            flags,
        }
    }
}

impl MaterialExtension for TriplanarExtension {
    fn fragment_shader() -> ShaderRef {
        TRIPLANAR_EXTENSION_SHADER_HANDLE.into()
    }

    fn deferred_fragment_shader() -> ShaderRef {
        TRIPLANAR_EXTENSION_SHADER_HANDLE.into()
    }
}
