use crate::TriplanarMaterial;
use bevy::{asset::load_internal_asset, prelude::*};

pub(crate) const TRIPLANAR_EXTENSION_SHADER_HANDLE: Handle<Shader> =
    Handle::weak_from_u128(11996004641749241285);
const CUSTOM_PBR_SHADER_HANDLE: Handle<Shader> = Handle::weak_from_u128(1286143009025404084);
const TRIPLANAR_TYPES_SHADER_HANDLE: Handle<Shader> = Handle::weak_from_u128(8524188430017026455);
const TRIPLANAR_UTILS_SHADER_HANDLE: Handle<Shader> = Handle::weak_from_u128(5873599907443613347);

/// Plugin that sets up the shaders and `TriplanarMaterial`
pub struct TriplanarMappingPlugin;
impl Plugin for TriplanarMappingPlugin {
    fn build(&self, app: &mut App) {
        app.add_plugins(MaterialPlugin::<TriplanarMaterial>::default());

        load_internal_asset!(
            app,
            TRIPLANAR_EXTENSION_SHADER_HANDLE,
            "shaders/triplanar_extension.wgsl",
            Shader::from_wgsl
        );
        load_internal_asset!(
            app,
            CUSTOM_PBR_SHADER_HANDLE,
            "shaders/custom_pbr.wgsl",
            Shader::from_wgsl
        );
        load_internal_asset!(
            app,
            TRIPLANAR_TYPES_SHADER_HANDLE,
            "shaders/triplanar_types.wgsl",
            Shader::from_wgsl
        );
        load_internal_asset!(
            app,
            TRIPLANAR_UTILS_SHADER_HANDLE,
            "shaders/triplanar_utils.wgsl",
            Shader::from_wgsl
        );
    }
}
