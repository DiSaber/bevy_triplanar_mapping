use bevy::{pbr::PbrPlugin, prelude::*, shader::load_shader_library};

use crate::TriplanarMaterial;

/// Plugin that sets up the shaders and `TriplanarMaterial`
pub struct TriplanarMappingPlugin;
impl Plugin for TriplanarMappingPlugin {
    fn build(&self, app: &mut App) {
        // Pbr lighting methods needed
        if !app.is_plugin_added::<PbrPlugin>() {
            app.add_plugins(PbrPlugin::default());
        }

        app.add_plugins(MaterialPlugin::<TriplanarMaterial>::default());

        load_shader_library!(app, "shaders/vertex.wgsl");
        load_shader_library!(app, "shaders/fragment.wgsl");
        load_shader_library!(app, "shaders/triplanar_mapping.wgsl");
        load_shader_library!(app, "shaders/types.wgsl");
        load_shader_library!(app, "shaders/bindings.wgsl");
    }
}
