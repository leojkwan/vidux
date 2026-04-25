// vidux browser — vanilla JS, no framework. Reads /api/* from the local server.

const state = {
  plans: [],
  filter: "",
  active: null,    // {repo, slug, path}
  activeTab: "PLAN.md",
};

const els = {
  list: document.getElementById("sidebar-list"),
  filter: document.getElementById("filter"),
  pane: document.getElementById("pane"),
  count: document.getElementById("meta-count"),
  refresh: document.getElementById("refresh"),
};

function fmtAge(days) {
  if (days < 1) return "today";
  if (days < 2) return "1d";
  if (days < 30) return `${Math.round(days)}d`;
  if (days < 365) return `${Math.round(days / 30)}mo`;
  return `${(days / 365).toFixed(1)}y`;
}

function renderSidebar() {
  const filter = state.filter.toLowerCase();
  const filtered = filter
    ? state.plans.filter(p =>
        p.repo.toLowerCase().includes(filter) ||
        p.slug.toLowerCase().includes(filter) ||
        (p.purpose || "").toLowerCase().includes(filter))
    : state.plans;

  const groups = new Map();
  for (const plan of filtered) {
    if (!groups.has(plan.repo)) groups.set(plan.repo, []);
    groups.get(plan.repo).push(plan);
  }

  els.count.textContent = `${state.plans.length} plans · ${groups.size} repos`;

  if (filtered.length === 0) {
    els.list.innerHTML = `<p class="muted" style="padding:12px">no matches</p>`;
    return;
  }

  const repoOrder = [...groups.keys()].sort();
  const html = repoOrder.map(repo => {
    const rows = groups.get(repo);
    const inner = rows.map(plan => {
      const active = state.active && state.active.path === plan.path ? "is-active" : "";
      const slug = plan.slug === "_root_" ? "(root)" : plan.slug;
      return `
        <div class="plan-row ${active}" data-path="${escapeAttr(plan.path)}">
          <div class="plan-row-head">
            <span class="pill pill-${plan.status}" title="${plan.status} · ${fmtAge(plan.age_days)}"></span>
            <span>${escapeText(slug)}</span>
          </div>
          ${plan.purpose ? `<div class="plan-row-purpose">${escapeText(plan.purpose)}</div>` : ""}
          <div class="plan-row-meta">
            <span>${fmtAge(plan.age_days)}</span>
            <span>${(plan.size / 1024).toFixed(1)}KB</span>
            ${plan.siblings.length ? `<span>+${plan.siblings.length}</span>` : ""}
          </div>
        </div>`;
    }).join("");
    return `
      <div class="repo-group">
        <h2>${escapeText(repo)} <span class="repo-count">(${rows.length})</span></h2>
      </div>
      ${inner}`;
  }).join("");

  els.list.innerHTML = html;

  els.list.querySelectorAll(".plan-row").forEach(row => {
    row.addEventListener("click", () => {
      const path = row.getAttribute("data-path");
      const plan = state.plans.find(p => p.path === path);
      if (plan) selectPlan(plan);
    });
  });
}

async function loadPlans() {
  els.count.textContent = "loading…";
  try {
    const res = await fetch("/api/plans");
    const data = await res.json();
    state.plans = data.plans || [];
    renderSidebar();
  } catch (e) {
    els.count.textContent = "error";
    els.list.innerHTML = `<div class="error">failed to load plans: ${escapeText(String(e))}</div>`;
  }
}

async function selectPlan(plan) {
  state.active = plan;
  state.activeTab = "PLAN.md";
  renderSidebar();
  await renderPane();
}

async function renderPane() {
  if (!state.active) return;
  const plan = state.active;
  const tabs = ["PLAN.md", ...plan.siblings];
  const tabPath = state.activeTab === "PLAN.md"
    ? plan.path
    : plan.path.replace(/\/PLAN\.md$/, `/${state.activeTab}`);

  const headerHTML = `
    <div class="pane-header">
      <div class="breadcrumb">${escapeText(plan.rel)}</div>
      <h2>${escapeText(plan.repo)} · ${escapeText(plan.slug === "_root_" ? "(root)" : plan.slug)}</h2>
      <div class="meta">
        <span><span class="pill pill-${plan.status}"></span>${plan.status}</span>
        <span>modified ${fmtAge(plan.age_days)} ago</span>
        <span>${(plan.size / 1024).toFixed(1)}KB</span>
        <span class="muted">${escapeText(plan.path)}</span>
      </div>
    </div>
    <div class="pane-tabs">
      ${tabs.map(t => `
        <button data-tab="${escapeAttr(t)}" class="${t === state.activeTab ? "is-active" : ""}">${escapeText(t)}</button>
      `).join("")}
    </div>
    <div class="markdown" id="md-body"><p class="muted">loading…</p></div>
  `;
  els.pane.innerHTML = headerHTML;

  els.pane.querySelectorAll(".pane-tabs button").forEach(b => {
    b.addEventListener("click", () => {
      state.activeTab = b.getAttribute("data-tab");
      renderPane();
    });
  });

  try {
    const res = await fetch(`/api/file?path=${encodeURIComponent(tabPath)}`);
    if (!res.ok) {
      const txt = await res.text();
      document.getElementById("md-body").innerHTML =
        `<div class="error">${res.status}: ${escapeText(txt)}</div>`;
      return;
    }
    const md = await res.text();
    const html = window.marked
      ? window.marked.parse(md, { breaks: false, gfm: true })
      : naiveMarkdown(md);
    document.getElementById("md-body").innerHTML = html;
  } catch (e) {
    document.getElementById("md-body").innerHTML =
      `<div class="error">failed to load file: ${escapeText(String(e))}</div>`;
  }
}

function naiveMarkdown(md) {
  // Tiny fallback if marked.js fails to load.
  return md
    .split(/\n\n+/)
    .map(p => `<p>${escapeText(p).replace(/\n/g, "<br>")}</p>`)
    .join("");
}

function escapeText(s) {
  return String(s ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}
function escapeAttr(s) {
  return escapeText(s).replace(/"/g, "&quot;");
}

els.filter.addEventListener("input", e => {
  state.filter = e.target.value;
  renderSidebar();
});
els.refresh.addEventListener("click", loadPlans);

// Initial load.
loadPlans();
