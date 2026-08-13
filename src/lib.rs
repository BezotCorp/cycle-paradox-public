use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RuntimePaths {
    pub base_game: ProductPaths,
    pub extensions: Vec<ExtensionPaths>,
    pub user_data_root: PathBuf,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProductPaths {
    pub root: PathBuf,
    pub data: PathBuf,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExtensionPaths {
    pub id: String,
    pub root: PathBuf,
    pub data: PathBuf,
}

impl RuntimePaths {
    pub fn read(path: &Path) -> Result<Self, Box<dyn std::error::Error>> {
        let bytes = std::fs::read(path)?;

        let (value, _): (Self, usize) =
            bincode_next::serde::decode_from_slice(&bytes, bincode_next::config::standard())?;

        Ok(value)
    }

    pub fn write(&self, path: &Path) -> Result<(), Box<dyn std::error::Error>> {
        let bytes = bincode_next::serde::encode_to_vec(self, bincode_next::config::standard())?;

        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)?;
        }

        std::fs::write(path, bytes)?;

        Ok(())
    }

    pub fn extension(&self, id: &str) -> Option<&ExtensionPaths> {
        self.extensions.iter().find(|extension| extension.id == id)
    }
}
