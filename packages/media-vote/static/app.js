const state = {
  session: null,
  items: [],
  view: "library",
  type: "all",
  query: "",
  loading: false,
  sync: null,
};

const choiceMeta = {
  archive: { label: "Forever", icon: "◆", hint: "Keep this permanently" },
  delete: { label: "Delete", icon: "×", hint: "Candidate for deletion" },
  quality: { label: "Better", icon: "↑", hint: "Find a higher-quality copy" },
  dontcare: { label: "Don't care", icon: "–", hint: "No preference" },
};

const views = {
  library: ["Make your call", "The library"],
  "my-votes": ["Your decisions", "My votes"],
  shortlist: ["Juicy’s desk", "Actionable shortlist"],
  storage: ["Storage diagnosis", "Largest files"],
};

const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => [...document.querySelectorAll(selector)];

function escapeHtml(value = "") {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function formatBytes(bytes = 0) {
  if (!bytes) return "Size unknown";
  const units = ["B", "KB", "MB", "GB", "TB"];
  const index = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1);
  return `${(bytes / 1024 ** index).toFixed(index > 2 ? 1 : 0)} ${units[index]}`;
}

function formatBitrate(bitrate = 0) {
  if (!bitrate) return "—";
  return `${(bitrate / 1_000_000).toFixed(1)} Mb/s`;
}

function formatDate(timestamp) {
  if (!timestamp) return "Never";
  return new Date(timestamp * 1000).toLocaleString();
}

function qualityLabel(item) {
  const parts = [];
  if (item.height) parts.push(item.height >= 2160 ? "4K" : `${item.height}p`);
  if (item.codecs?.length) parts.push(item.codecs.join("/"));
  return parts.join(" · ") || "Quality unknown";
}

async function api(path, options = {}) {
  const headers = { ...(options.headers || {}) };
  if (options.body) headers["Content-Type"] = "application/json";
  if (state.session?.csrf && options.method && options.method !== "GET") {
    headers["X-CSRF-Token"] = state.session.csrf;
  }
  const response = await fetch(path, { ...options, headers });
  const contentType = response.headers.get("content-type") || "";
  const payload = contentType.includes("json") ? await response.json() : null;
  if (!response.ok) {
    if (response.status === 401 && path !== "/api/login") showLogin();
    throw new Error(payload?.error || `Request failed (${response.status})`);
  }
  return payload;
}

function toast(message) {
  const element = $("#toast");
  element.textContent = message;
  element.classList.add("show");
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => element.classList.remove("show"), 2400);
}

function showLogin() {
  state.session = null;
  $("#app-view").hidden = true;
  $("#login-view").hidden = false;
}

async function showApp(session) {
  state.session = session;
  $("#login-view").hidden = true;
  $("#app-view").hidden = false;
  $("#username").textContent = session.username;
  $("#user-role").textContent = session.isAdmin ? "Administrator" : "Voter";
  $("#user-avatar").textContent = session.username.slice(0, 1).toUpperCase();
  $$(".admin-only").forEach((element) => {
    element.hidden = !session.isAdmin;
  });
  await loadCatalog();
  if (session.isAdmin) await loadSyncStatus();
}

function setLoading(message = "Reading Jellyfin…") {
  $("#main-content").innerHTML = `
    <div class="loading-state">
      <div class="spinner"></div>
      <strong>${escapeHtml(message)}</strong>
      <span>Large libraries can take a moment.</span>
    </div>`;
}

async function loadCatalog() {
  state.loading = true;
  setLoading("Reading the catalog…");
  try {
    const result = await api("/api/catalog");
    state.items = result.items;
    state.sync = result.sync;
    render();
    renderSyncStatus();
  } catch (error) {
    renderError(error.message);
  } finally {
    state.loading = false;
  }
}

function renderSyncStatus() {
  const banner = $("#sync-banner");
  const button = $("#refresh-button");
  if (!state.session?.isAdmin || !state.sync) {
    banner.hidden = true;
    return;
  }
  const running = state.sync.status === "running";
  button.disabled = running;
  button.textContent = running ? "Syncing…" : "Sync Jellyfin";
  banner.hidden = false;
  banner.className = `sync-banner sync-${state.sync.status}`;
  banner.innerHTML = `
    <div>
      <strong>${running ? "Jellyfin sync in progress" : "Catalog snapshot"}</strong>
      <span>Last successful sync: ${escapeHtml(formatDate(state.sync.succeededAt))}</span>
    </div>
    <div>
      <span>${state.sync.itemCount || 0} votable titles</span>
      <span>${state.sync.fileCount || 0} media files</span>
      ${state.sync.error ? `<span class="sync-error">${escapeHtml(state.sync.error)}</span>` : ""}
    </div>`;
}

async function loadSyncStatus() {
  try {
    state.sync = await api("/api/sync-status");
    renderSyncStatus();
  } catch (error) {
    toast(error.message);
  }
}

async function waitForSync() {
  for (let attempt = 0; attempt < 180; attempt += 1) {
    await new Promise((resolve) => setTimeout(resolve, 2000));
    await loadSyncStatus();
    if (state.sync?.status === "ready") {
      await loadCatalog();
      toast("Jellyfin catalog updated");
      return;
    }
    if (state.sync?.status === "error") {
      toast(state.sync.error || "Jellyfin sync failed");
      return;
    }
  }
  toast("Sync is still running in the background");
}

async function startSync() {
  const button = $("#refresh-button");
  button.disabled = true;
  try {
    await api("/api/admin/sync", { method: "POST" });
    state.sync = { ...(state.sync || {}), status: "running", error: null };
    renderSyncStatus();
    toast("Jellyfin sync started");
    await waitForSync();
  } catch (error) {
    toast(error.message);
    await loadSyncStatus();
  }
}

function renderError(message) {
  $("#main-content").innerHTML = `
    <div class="empty-state">
      <span>!</span>
      <h2>Couldn’t load this view</h2>
      <p>${escapeHtml(message)}</p>
    </div>`;
}

function renderSummary(items) {
  const counts = {
    total: items.length,
    voted: items.filter((item) => item.vote).length,
    forever: items.filter((item) => item.vote === "archive").length,
    delete: items.filter((item) => item.vote === "delete").length,
  };
  $("#summary-strip").innerHTML = `
    <article><span>Visible titles</span><strong>${counts.total}</strong></article>
    <article><span>You voted</span><strong>${counts.voted}</strong></article>
    <article><span>Forever picks</span><strong>${counts.forever}</strong></article>
    <article><span>Delete picks</span><strong>${counts.delete}</strong></article>`;
}

function card(item) {
  const subtitle = [
    item.parentName,
    item.type === "Movie" ? item.year : item.type,
  ].filter(Boolean).join(" · ");
  const image = item.imageTag && item.imageId
    ? `<img src="/api/images/${encodeURIComponent(item.imageId)}" alt="" loading="lazy">`
    : `<div class="poster-fallback"><span>${escapeHtml(item.name.slice(0, 1))}</span></div>`;
  const buttons = Object.entries(choiceMeta).map(([choice, meta]) => `
    <button class="vote-button ${choice} ${item.vote === choice ? "selected" : ""}"
      data-item-id="${escapeHtml(item.id)}" data-choice="${choice}"
      title="${escapeHtml(meta.hint)}">
      <span>${meta.icon}</span>${meta.label}
    </button>`).join("");
  return `
    <article class="media-card ${item.type.toLowerCase()}">
      <div class="poster">
        ${image}
        <span class="type-badge">${escapeHtml(item.type)}</span>
      </div>
      <div class="card-copy">
        <p class="card-kicker">${escapeHtml(subtitle)}</p>
        <h2>${escapeHtml(item.name)}</h2>
        <div class="media-facts">
          <span>${formatBytes(item.sizeBytes)}</span>
          <span>${escapeHtml(qualityLabel(item))}</span>
          ${item.fileCount ? `<span>${item.fileCount} file${item.fileCount === 1 ? "" : "s"}</span>` : ""}
        </div>
        <div class="vote-buttons">${buttons}</div>
      </div>
    </article>`;
}

function filteredItems() {
  const query = state.query.trim().toLowerCase();
  return state.items.filter((item) => {
    if (state.view === "my-votes" && !item.vote) return false;
    if (state.type !== "all" && item.type !== state.type) return false;
    if (query && !`${item.name} ${item.parentName || ""}`.toLowerCase().includes(query)) return false;
    return true;
  });
}

function renderLibrary() {
  const items = filteredItems();
  renderSummary(state.items);
  $("#summary-strip").hidden = false;
  $("#library-tools").hidden = false;
  if (!items.length) {
    $("#main-content").innerHTML = `
      <div class="empty-state">
        <span>◇</span>
        <h2>Nothing in this cut</h2>
        <p>Try another media type or search.</p>
      </div>`;
    return;
  }
  $("#main-content").innerHTML = `<div class="media-grid">${items.map(card).join("")}</div>`;
}

function recommendationLabel(value) {
  return {
    conflict: "Needs a call",
    delete: "Review deletion",
    quality: "Find better copy",
    protect: "Protect forever",
  }[value] || value;
}

async function renderShortlist() {
  $("#library-tools").hidden = true;
  $("#summary-strip").hidden = true;
  setLoading("Building the shortlist…");
  try {
    const result = await api("/api/admin/shortlist");
    if (!result.items.length) {
      $("#main-content").innerHTML = `
        <div class="empty-state">
          <span>✓</span>
          <h2>Nothing needs attention</h2>
          <p>Only decisive votes appear here; “don’t care” votes stay out of the way.</p>
        </div>`;
      return;
    }
    $("#main-content").innerHTML = `
      <div class="queue-intro">
        <div><strong>${result.items.length}</strong><span>actionable item${result.items.length === 1 ? "" : "s"}</span></div>
        <p>Conflicts first, then deletion, quality, and permanent protection. No action is automatic.</p>
      </div>
      <div class="queue">
        ${result.items.map((item) => `
          <article class="queue-row recommendation-${item.recommendation}">
            <div class="queue-action">
              <span>${escapeHtml(recommendationLabel(item.recommendation))}</span>
              <small>${escapeHtml(item.type)}</small>
            </div>
            <div class="queue-title">
              <strong>${escapeHtml(item.name)}</strong>
              <span>${escapeHtml(item.parentName || "")}</span>
            </div>
            <div class="queue-votes">
              ${Object.entries(item.counts)
                .filter(([, count]) => count)
                .map(([choice, count]) => `<span class="${choice}" title="${escapeHtml((item.voters[choice] || []).join(", "))}">${choiceMeta[choice].icon} ${count}</span>`)
                .join("")}
            </div>
            <div class="queue-size">${formatBytes(item.sizeBytes)}</div>
            <button class="review-button" data-review-id="${escapeHtml(item.id)}">Mark reviewed</button>
          </article>`).join("")}
      </div>`;
  } catch (error) {
    renderError(error.message);
  }
}

async function renderStorage() {
  $("#library-tools").hidden = true;
  $("#summary-strip").hidden = true;
  setLoading("Measuring the library…");
  try {
    const result = await api("/api/admin/storage?limit=150");
    $("#main-content").innerHTML = `
      <div class="storage-note">
        <strong>Why is a file large?</strong>
        <p>Compare total size with size per hour. Resolution, codec and bitrate explain most outliers; paths help trace the exact release.</p>
      </div>
      <div class="table-wrap">
        <table>
          <thead><tr>
            <th>Title</th><th>Size</th><th>Per hour</th><th>Video</th><th>Bitrate</th><th>Path</th>
          </tr></thead>
          <tbody>
            ${result.files.map((file) => `
              <tr>
                <td><strong>${escapeHtml(file.name)}</strong><span>${escapeHtml(file.seasonName || file.type)}</span></td>
                <td>${formatBytes(file.sizeBytes)}</td>
                <td>${formatBytes(file.bytesPerHour)}</td>
                <td>${escapeHtml(qualityLabel(file))}</td>
                <td>${formatBitrate(file.bitrate)}</td>
                <td><code title="${escapeHtml(file.path)}">${escapeHtml(file.path)}</code></td>
              </tr>`).join("")}
          </tbody>
        </table>
      </div>`;
  } catch (error) {
    renderError(error.message);
  }
}

function render() {
  const [eyebrow, title] = views[state.view];
  $("#view-eyebrow").textContent = eyebrow;
  $("#view-title").textContent = title;
  $("#refresh-button").hidden = !state.session?.isAdmin;
  $$(".nav-item").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === state.view);
  });
  if (["library", "my-votes"].includes(state.view)) renderLibrary();
  if (state.view === "shortlist") renderShortlist();
  if (state.view === "storage") renderStorage();
}

$("#login-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const form = new FormData(event.currentTarget);
  const button = event.currentTarget.querySelector("button");
  $("#login-error").textContent = "";
  button.disabled = true;
  button.textContent = "Checking Jellyfin…";
  try {
    const session = await api("/api/login", {
      method: "POST",
      body: JSON.stringify({
        username: form.get("username"),
        password: form.get("password"),
      }),
    });
    await showApp(session);
  } catch (error) {
    $("#login-error").textContent = error.message;
  } finally {
    button.disabled = false;
    button.textContent = "Enter the library";
  }
});

$("#logout-button").addEventListener("click", async () => {
  try {
    await api("/api/logout", { method: "POST" });
  } finally {
    showLogin();
  }
});

$("#refresh-button").addEventListener("click", startSync);

$("#search-input").addEventListener("input", (event) => {
  state.query = event.target.value;
  renderLibrary();
});

$$(".segmented button").forEach((button) => {
  button.addEventListener("click", () => {
    state.type = button.dataset.type;
    $$(".segmented button").forEach((candidate) => {
      candidate.classList.toggle("active", candidate === button);
    });
    renderLibrary();
  });
});

$$(".nav-item").forEach((button) => {
  button.addEventListener("click", () => {
    state.view = button.dataset.view;
    render();
  });
});

$("#main-content").addEventListener("click", async (event) => {
  const voteButton = event.target.closest(".vote-button");
  if (voteButton) {
    const item = state.items.find((candidate) => candidate.id === voteButton.dataset.itemId);
    if (!item) return;
    const previous = item.vote;
    const choice = previous === voteButton.dataset.choice ? "clear" : voteButton.dataset.choice;
    item.vote = choice === "clear" ? null : choice;
    renderLibrary();
    try {
      await api("/api/votes", {
        method: "POST",
        body: JSON.stringify({ itemId: item.id, choice }),
      });
      toast(item.vote ? `Voted ${choiceMeta[item.vote].label.toLowerCase()}` : "Vote cleared");
    } catch (error) {
      item.vote = previous;
      renderLibrary();
      toast(error.message);
    }
    return;
  }

  const reviewButton = event.target.closest(".review-button");
  if (reviewButton) {
    try {
      await api("/api/admin/reviews", {
        method: "POST",
        body: JSON.stringify({ itemId: reviewButton.dataset.reviewId, status: "reviewed" }),
      });
      toast("Removed from the open queue");
      await renderShortlist();
    } catch (error) {
      toast(error.message);
    }
  }
});

(async function initialize() {
  try {
    const session = await api("/api/session");
    if (session.authenticated) await showApp(session);
    else showLogin();
  } catch {
    showLogin();
  }
})();
