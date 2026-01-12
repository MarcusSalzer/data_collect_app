<script lang="ts">
  import Database from "@tauri-apps/plugin-sql";
  const db = Database.get("sqlite:data_app.db");

  let evts = $state<any[]>();

  async function loadEvts() {
    evts = await db.select("SELECT * FROM events");
  }
  loadEvts();
</script>

<main>
  <header>
    <a href="/">Home</a>
    <h1>temporary history screen</h1>

    <div id="hist">
      {#if evts === undefined}
        Loading
      {:else if evts.length == 0}
        No events
      {:else}
        <ul>
          {#each evts as e}
            <li>{JSON.stringify(e)}</li>
          {/each}
        </ul>
      {/if}
    </div>
  </header>
</main>
