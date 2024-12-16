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
    /// The uv scale of the mapping. (default: 1.0)
    pub uv_scale: f32,

    /// The sharpness of the blending in transition areas. (default: 8.0)
    /// Lower -> Smoother transitions, Higher -> Sharper transitions
    pub blending: f32,

    /// If the triplanar mapping should be done in local object space. (default: true)
    pub local_space: bool,
}

impl Default for TriplanarExtension {
    fn default() -> Self {
        Self {
            uv_scale: 1.0,
            blending: 8.0,
            local_space: true,
        }
    }
}

/// The GPU representation of the uniform data of a [`TriplanarExtension`].
#[derive(Clone, Default, ShaderType)]
struct TriplanarExtensionUniform {
    pub uv_scale: f32,
    pub blending: f32,
    /// 1 -> true
    pub local_space: u32,
}

impl AsBindGroupShaderType<TriplanarExtensionUniform> for TriplanarExtension {
    fn as_bind_group_shader_type(&self, _: &RenderAssets<GpuImage>) -> TriplanarExtensionUniform {
        TriplanarExtensionUniform {
            uv_scale: self.uv_scale,
            blending: self.blending,
            local_space: self.local_space.into(),
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
