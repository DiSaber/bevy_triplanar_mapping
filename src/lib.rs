mod triplanar_extension;
mod triplanar_mapping_plugin;

pub use triplanar_extension::*;
pub use triplanar_mapping_plugin::*;

use bevy::pbr::{ExtendedMaterial, StandardMaterial};

/// Typedef for `ExtendedMaterial<StandardMaterial, TriplanarExtension>`
pub type TriplanarMaterial = ExtendedMaterial<StandardMaterial, TriplanarExtension>;
