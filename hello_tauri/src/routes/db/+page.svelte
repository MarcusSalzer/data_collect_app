<script lang="ts">
  import { invoke } from "@tauri-apps/api/core";
  import Database from "@tauri-apps/plugin-sql";
  // when using `"withGlobalTauri": true`, you may use
  // const Database = window.__TAURI__.sql;

  let r = $state("loading...");

  async function loadDbOverview() {
    const db = Database.get("sqlite:data_app.db");
    console.log("ööh");

    // const result = await invoke("list_tables", { dbPath: "data_app.db" });
    const tblNames = await db.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_sqlx%'"
    );
    r = JSON.stringify(tblNames, undefined, 4);
  }
  loadDbOverview();
</script>

<main>
  <header>
    <a href="/">Home</a>

    <h1>DB overview</h1>
  </header>
  <pre>{r}</pre>
</main>
