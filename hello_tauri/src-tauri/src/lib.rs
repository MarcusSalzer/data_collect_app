use tauri_plugin_sql::{Migration, MigrationKind};

mod commands {
    pub mod db_info;
}

use commands::db_info::list_tables;

// Learn more about Tauri commands at https://tauri.app/develop/calling-rust/
#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

// #[tauri::command]
// async fn start_evt<R: Runtime>(// window: tauri::Window<R>,
//     // app: tauri::AppHandle<R>,
// ) -> Result<(), String> {
//     Ok(())
// }

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    #[cfg(dev)]
    {
        println!("--- App running ---")
    }
    let migrations = vec![
        // Define your migrations here
        Migration {
            version: 1,
            description: "create_initial_tables",
            sql: include_str!("../../migrations/schema.sql"),
            kind: MigrationKind::Up,
        },
    ];

    tauri::Builder::default()
        .plugin(
            tauri_plugin_sql::Builder::default()
                .add_migrations("sqlite:data_app.db", migrations)
                .build(),
        )
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![greet, list_tables])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
