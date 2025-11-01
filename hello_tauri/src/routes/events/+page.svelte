<script lang="ts">
  import Database from "@tauri-apps/plugin-sql";
  const db = Database.get("sqlite:data_app.db");

  let start_input_text = $state<string>("");
  async function startEvt(event: Event) {
    event.preventDefault;

    const start_name = start_input_text.trim();
    if (!start_name) {
      return;
    }
    // TODO Move this to evt types, here should make event
    const r = await db.execute("INSERT into event_types (name) VALUES ($1)", [
      start_name,
    ]);
    // Clear input field
    start_input_text = "";
  }
</script>

<header>
  <a href="/">Home</a>
  <h1>Events</h1>
</header>
<main>
  <div id="current">
    <div id="current-text">current...</div>
    <button disabled>Stop</button>
  </div>

  <form onsubmit={startEvt}>
    <input
      type="text"
      id="start-evt"
      placeholder="start"
      bind:value={start_input_text}
    />
    <button type="submit">+</button>
  </form>

  <div id="suggestions">TODO suggestions</div>
</main>

<style>
  main {
    height: 1dvh;
    padding: 1em;
  }
  header {
    display: flex;
    gap: 1em;
    align-items: center;
  }
  header > * {
    display: block;
    color: antiquewhite;
  }

  #current {
    margin: 1em 0;
    height: 2em;
    display: flex;
    gap: 1em;
  }
  #current-text {
    flex: 1;
  }
  #current > button {
    width: 3em;
  }

  form {
    margin: 1em 0;
    height: 2em;
    display: flex;
    gap: 1em;
  }
  form > input {
    flex: 1;
    min-width: 2em;
  }
  form > button {
    width: 3em;
  }
  button:hover {
    opacity: 0.8;
    cursor: pointer;
  }

  #suggestions {
    margin: 1em 0;
    background-color: rgb(55, 55, 53);
    min-height: 30vh;
    align-content: center;
    text-align: center;
  }
</style>
