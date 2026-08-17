use std::{
    fs,
    path::PathBuf,
    time::{SystemTime, UNIX_EPOCH},
};

use cycle_paradox_extension_api::{ExtensionPaths, ProductPaths, RuntimePaths};

#[test]
fn runtime_paths_survive_a_file_round_trip() {
    let temporary_root = std::env::temp_dir().join(format!(
        "cycle-paradox-extension-api-{}-{}",
        std::process::id(),
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system clock must be after the Unix epoch")
            .as_nanos(),
    ));

    let runtime_paths_file = temporary_root.join("runtime_paths.bin");

    let expected = RuntimePaths {
        base_game: ProductPaths {
            root: PathBuf::from("/game"),
            data: PathBuf::from("/game/data"),
        },
        extensions: vec![ExtensionPaths {
            id: "aliens".to_owned(),
            root: PathBuf::from("/extensions/aliens"),
            data: PathBuf::from("/extensions/aliens/data"),
        }],
        user_data_root: PathBuf::from("/user/data"),
    };

    expected
        .write(&runtime_paths_file)
        .expect("runtime paths must be written");

    let actual = RuntimePaths::read(&runtime_paths_file).expect("runtime paths must be read");

    assert_eq!(actual.base_game.root, expected.base_game.root);
    assert_eq!(actual.base_game.data, expected.base_game.data);
    assert_eq!(actual.user_data_root, expected.user_data_root);

    let aliens = actual
        .extension("aliens")
        .expect("aliens extension must be found");

    assert_eq!(aliens.root, PathBuf::from("/extensions/aliens"));
    assert_eq!(aliens.data, PathBuf::from("/extensions/aliens/data"));
    assert!(actual.extension("unknown").is_none());

    fs::remove_dir_all(temporary_root).expect("temporary test directory must be removed");
}
