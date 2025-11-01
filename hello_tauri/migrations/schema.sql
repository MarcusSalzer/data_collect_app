CREATE TABLE event_types (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type_id INTEGER NOT NULL REFERENCES event_types(id),
  start_utc INTEGER NOT NULL,     -- Unix timestamp (ms)
  end_utc INTEGER NOT NULL,
  offset_ms INTEGER NOT NULL      -- offset (ms) from UTC at creation
);
