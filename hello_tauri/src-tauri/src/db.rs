// Database (sqlite, sqlx)
// OR maybe, use the sql-plugin instead!

use serde::Serialize;
use sqlx::{FromRow, SqlitePool};

#[derive(sqlx::FromRow)]
struct Event {
    id: i64,
    type_id: i64,
    // store UTC and offset to reconstruct historical events
    start_utc: i64,
    start_offset_ms: i32,
    end_utc: i64,
    end_offset_ms: i32,
}
