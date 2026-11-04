// Network picker — pure DOM renderer, no dependencies.
export function renderNetworkPicker(state, onAction) {
  const section = document.createElement("section");
  section.className = "row";

  if (!state || !Array.isArray(state.networks)) return section;

  // Disable when busy, a challenge is pending, or any outbox item is in flight.
  const outboxBlocked = state.outbox.some(
    (o) => o.phase === "ready" || o.phase === "sending"
  );
  const disabled =
    state.busy || !!state.challenge || outboxBlocked;

  const title = document.createElement("div");
  title.className = "panel";
  const t = document.createElement("span");
  t.textContent = "Network";
  t.className = "muted";
  title.appendChild(t);
  section.appendChild(title);

  const sel = document.createElement("select");
  sel.disabled = disabled;
  sel.setAttribute("aria-label", "Network");
  const options = [
    { value: "mainnet-alpha", label: "Mainnet alpha" },
    { value: "devnet", label: "Devnet" },
  ];
  for (const opt of options) {
    const profile = state.networks.find((n) => n && n.network === opt.value);
    const unavailable = !!profile && profile.available === false;
    const el = document.createElement("option");
    el.value = opt.value;
    el.textContent = unavailable ? `${opt.label} (not available)` : opt.label;
    el.disabled = unavailable;
    if (state.network === opt.value) el.selected = true;
    sel.appendChild(el);
  }
  sel.addEventListener("change", () => {
    const target = sel.value;
    const targetProfile = state.networks.find((n) => n && n.network === target);
    sel.value = state.network;
    const targetUnavailable = !!targetProfile && targetProfile.available === false;
    if (!disabled && target !== state.network && !targetUnavailable)
      onAction("network", { network: target });
  });

  const wrap = document.createElement("div");
  wrap.className = "row";
  wrap.appendChild(sel);

  // Show descriptive badge per known network.
  for (const n of state.networks) {
    if (!n || !n.network) continue;
    const badge = document.createElement("span");
    badge.className = "networkbadge muted";
    let text =
      n.imported && n.address
        ? `${n.network}: wallet ${n.address} · pending ${n.pendingCount}`
        : `${n.network}: no wallet imported`;
    if (n.available === false) text += " · not available on this ship";
    badge.textContent = text;
    wrap.appendChild(badge);
  }

  const note = document.createElement("div");
  note.className = "muted";
  note.textContent =
    "Each network has its own separate wallet, balance and history.";
  section.appendChild(wrap);
  section.appendChild(note);

  return section;
}
