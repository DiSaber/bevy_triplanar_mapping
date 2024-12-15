use bevy::{
    asset::Asset,
    pbr::MaterialExtension,
    reflect::Reflect,
    render::render_resource::{AsBindGroup, ShaderRef},
};

use crate::TRIPLANAR_EXTENSION_SHADER_HANDLE;

#[derive(Asset, AsBindGroup, Reflect, Debug, Clone)]
pub struct TriplanarExtension {
    /// The uv scale of the mapping. (default: 1.0)
    #[uniform(100)]
    pub uv_scale: f32,
}

impl Default for TriplanarExtension {
    fn default() -> Self {
        Self { uv_scale: 1.0 }
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
