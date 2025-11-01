<script lang="ts">
  import Database from "@tauri-apps/plugin-sql";
  const db = Database.get("sqlite:data_app.db");

  let evt_types = $state<any[]>();

  async function loadEvts() {
    evt_types = await db.select("SELECT * FROM event_types");
  }
  loadEvts();
</script>

<main>
  <header>
    <a href="/">Home</a>
    <h1>Types</h1>

    <div id="hist">
      {#if evt_types === undefined}
        Loading
      {:else if evt_types.length == 0}
        No events
      {:else}
        <ul>
          {#each evt_types as et}
            <li>{et.name}</li>
          {/each}
        </ul>
      {/if}
    </div>
  </header>
</main>
