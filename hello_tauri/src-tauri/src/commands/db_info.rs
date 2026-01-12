use serde::Serialize;
use sqlx::{Connection, SqliteConnection};

#[derive(Serialize)]
pub struct TableInfo {
    name: String,
    count: i64,
}

#[tauri::command]
pub async fn list_tables(db_path: String) -> Result<Vec<TableInfo>, String> {
    #[cfg(dev)]
    {
        println!("--- list_tables called ---")
    }

    // Open a connection
    let mut conn = SqliteConnection::connect(&format!("sqlite://{}", db_path))
        .await
        .map_err(|e| format!("DB connect error: {}", e))?;

    // Get all table names
    let table_names: Vec<String> = sqlx::query_scalar::<_, String>(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
    )
    .fetch_all(&mut conn)
    .await
    .map_err(|e| format!("Failed to fetch table names: {}", e))?;

    // For each table, count rows
    let mut result = Vec::new();
    for name in table_names {
        let query = format!("SELECT COUNT(*) FROM {}", name);
        let count: i64 = sqlx::query_scalar(&query)
            .fetch_one(&mut conn)
            .await
            .map_err(|e| format!("Failed counting rows in {}: {}", name, e))?;
        result.push(TableInfo { name, count });
    }
    #[cfg(dev)]
    {
        println!("--- list_tables OK ---")
    }
    Ok(result)
}
