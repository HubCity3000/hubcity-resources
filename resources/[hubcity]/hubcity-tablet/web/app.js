// Hub City Tablet — NUI logic (functional v1).
// Talks to the client through the NUI callbacks defined in client/main.lua:
//   getTabletData -> { hotNeighborhood, allActive, catalog[], laundering[], vibezUrl }
//   submitOrder   -> { items: [{ item, amount }] } => { state, message, deal? }
//   getMyDeal     -> { items[], total, neighborhood, minutesLeft } | null
//   closeTablet
// Need 2 Speed (street racing — state lives in hubcity-streetrace):
//   getStreetRaceData -> { routes[], races[], myRace|null, records[], lastResults|null }
//   srCreateRace { routeId } | srJoinRace { raceId } | srLeaveRace | srStartRace | srCancelRace
//     -> { ok, message }
const resource = window.GetParentResourceName ? GetParentResourceName() : 'hubcity-tablet';

async function nui(event, data) {
  const resp = await fetch(`https://${resource}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  });
  try { return await resp.json(); } catch { return null; }
}

const $ = (id) => document.getElementById(id);
const views = { home: $('view-home'), market: $('view-market'), vibez: $('view-vibez'), race: $('view-race') };
let tabletData = null;
let raceData = null;
const order = {}; // item -> qty

function show(name) {
  Object.values(views).forEach((v) => v.classList.add('hidden'));
  views[name].classList.remove('hidden');
}

function money(n) { return '$' + Math.floor(n).toLocaleString('en-US'); }

function renderCatalog() {
  const wrap = $('catalog');
  wrap.innerHTML = '';
  (tabletData.catalog || []).forEach((entry) => {
    order[entry.item] = order[entry.item] || 0;
    const row = document.createElement('div');
    row.className = 'cat-row';
    row.innerHTML = `
      <div><span class="cat-name">${entry.label}</span><span class="cat-price">${money(entry.price)} each</span></div>
      <div class="stepper">
        <button data-dec="${entry.item}">−</button>
        <span class="qty" id="qty-${entry.item}">0</span>
        <button data-inc="${entry.item}">+</button>
      </div>`;
    wrap.appendChild(row);
  });
  wrap.querySelectorAll('[data-inc]').forEach((b) => b.addEventListener('click', () => changeQty(b.dataset.inc, 1)));
  wrap.querySelectorAll('[data-dec]').forEach((b) => b.addEventListener('click', () => changeQty(b.dataset.dec, -1)));
  renderTotal();
}

function changeQty(item, delta) {
  order[item] = Math.max(0, Math.min(99, (order[item] || 0) + delta));
  $('qty-' + item).textContent = order[item];
  renderTotal();
}

function renderTotal() {
  let total = 0;
  (tabletData.catalog || []).forEach((e) => { total += (order[e.item] || 0) * e.price; });
  $('order-total').textContent = money(total);
  $('submit-order').disabled = total <= 0;
}

function renderDeal(deal) {
  const panel = $('deal-panel');
  if (!deal) { panel.classList.add('hidden'); return; }
  panel.classList.remove('hidden');
  const lines = (deal.items || []).map((i) => `${i.amount} × ${i.label}`).join('<br>');
  $('deal-details').innerHTML =
    `<div class="deal-line">${lines}<br>Total due in cash: <b>${money(deal.total)}</b><br>` +
    `Meet in: <b>${deal.neighborhood}</b> · about <b>${deal.minutesLeft} min</b> left.<br>` +
    `Show up, talk to the dealer, complete the deal.</div>`;
}

function renderLaundering() {
  const spots = tabletData.laundering;
  if (spots && spots.length) {
    $('laundering-text').innerHTML = spots.map((s) =>
      `Wash active in <b>${s.neighborhood}</b> — fee <b>${s.feePercent}%</b>, ready in ~${s.processingMinutes} min after drop-off.`
    ).join('<br>');
  } else {
    $('laundering-text').textContent = 'No wash spot advertised right now.';
  }
}

async function refreshMarket() {
  tabletData = await nui('getTabletData');
  if (!tabletData) return;
  $('hot-text').textContent = tabletData.allActive
    ? 'Dealers are out in every neighborhood tonight.'
    : (tabletData.hotNeighborhood
        ? `The meet is in ${tabletData.hotNeighborhood} tonight. That's all you get — find it.`
        : 'No meet set. Check back later.');
  renderCatalog();
  renderLaundering();
  renderDeal(await nui('getMyDeal'));
}

$('tile-market').addEventListener('click', async () => { show('market'); await refreshMarket(); });
$('tile-vibez').addEventListener('click', () => {
  show('vibez');
  const frame = $('vibez-frame');
  const url = (tabletData && tabletData.vibezUrl) || 'https://vibez-social-hub.base44.app';
  if (frame.src !== url) frame.src = url;
});
document.querySelectorAll('[data-back]').forEach((b) => b.addEventListener('click', () => show('home')));

// ── Need 2 Speed ────────────────────────────────────────────────────────────

function fmtTime(ms) {
  if (ms == null) return 'DNF';
  const m = Math.floor(ms / 60000);
  const s = Math.floor((ms % 60000) / 1000);
  const millis = ms % 1000;
  return `${m}:${String(s).padStart(2, '0')}.${String(millis).padStart(3, '0')}`;
}

function renderRace() {
  if (!raceData) return;
  const mine = raceData.myRace;

  if (mine) {
    $('myrace-panel').classList.remove('hidden');
    $('create-panel').classList.add('hidden');
    $('lobby-panel').classList.add('hidden');
    const stateText = {
      lobby: 'Waiting in the lobby',
      grid: 'Race is on — get to the grid!',
      countdown: 'On the grid — countdown!',
      racing: 'Racing now — eyes on the HUD',
      finished: 'Finished',
    }[mine.state] || mine.state;
    $('myrace-details').innerHTML =
      `<div class="deal-line"><b>${mine.routeName}</b> — ${stateText}<br>` +
      `Racers (${mine.players.length}/${mine.maxRacers}): ${mine.players.join(', ')}</div>`;
    const hostInLobby = mine.isHost && mine.state === 'lobby';
    $('sr-start').classList.toggle('hidden', !hostInLobby);
    $('sr-cancel').classList.toggle('hidden', !hostInLobby);
    $('sr-leave').classList.toggle('hidden', hostInLobby);
  } else {
    $('myrace-panel').classList.add('hidden');
    $('create-panel').classList.remove('hidden');
    $('lobby-panel').classList.remove('hidden');

    const rl = $('route-list');
    rl.innerHTML = '';
    (raceData.routes || []).forEach((r) => {
      const row = document.createElement('div');
      row.className = 'cat-row';
      row.innerHTML =
        `<div><span class="cat-name">${r.name}</span><span class="cat-price">${r.checkpoints} checkpoints</span>` +
        `<div class="fineprint">${r.description}</div></div>` +
        `<button class="race-btn primary" data-create="${r.id}">Create</button>`;
      rl.appendChild(row);
    });
    rl.querySelectorAll('[data-create]').forEach((b) =>
      b.addEventListener('click', () => raceAction('srCreateRace', { routeId: b.dataset.create })));

    const ll = $('lobby-list');
    ll.innerHTML = '';
    const races = raceData.races || [];
    if (!races.length) ll.innerHTML = '<div class="deal-line">No open lobbies. Start one above.</div>';
    races.forEach((race) => {
      const row = document.createElement('div');
      row.className = 'cat-row';
      row.innerHTML =
        `<div><span class="cat-name">${race.routeName}</span>` +
        `<span class="cat-price">hosted by ${race.hostName} · ${race.players}/${race.maxRacers} racers</span></div>` +
        `<button class="race-btn primary" data-join="${race.id}">Join</button>`;
      ll.appendChild(row);
    });
    ll.querySelectorAll('[data-join]').forEach((b) =>
      b.addEventListener('click', () => raceAction('srJoinRace', { raceId: Number(b.dataset.join) })));
  }

  const lr = raceData.lastResults;
  if (lr && lr.rows && lr.rows.length) {
    $('lastresults-panel').classList.remove('hidden');
    $('lastresults').innerHTML = `<div class="deal-line"><b>${lr.routeName}</b></div>` + lr.rows.map((row) =>
      `<div class="cat-row"><span class="cat-name">${row.position > 0 ? 'P' + row.position : 'DNF'} — ${row.name}${row.me ? ' (you)' : ''}</span>` +
      `<span class="cat-price">${fmtTime(row.timeMs)}</span></div>`
    ).join('');
  } else {
    $('lastresults-panel').classList.add('hidden');
  }

  const rec = $('records-list');
  rec.innerHTML = '';
  const records = raceData.records || [];
  if (!records.length) rec.innerHTML = '<div class="deal-line">No finished races yet. Set the first record.</div>';
  records.forEach((group) => {
    const head = document.createElement('div');
    head.className = 'deal-line';
    head.innerHTML = `<b>${group.routeName}</b>`;
    rec.appendChild(head);
    (group.rows || []).forEach((row) => {
      const el = document.createElement('div');
      el.className = 'cat-row';
      el.innerHTML = `<span class="cat-name">${row.name}</span>` +
        `<span class="cat-price">${row.wins} win${row.wins === 1 ? '' : 's'} · best ${fmtTime(row.bestMs)} · ${row.races} race${row.races === 1 ? '' : 's'}</span>`;
      rec.appendChild(el);
    });
  });
}

async function refreshRace() {
  raceData = await nui('getStreetRaceData');
  renderRace();
}

async function raceAction(event, data) {
  const res = await nui(event, data);
  const out = $('race-result');
  if (res && res.message) {
    out.textContent = res.message;
    out.className = 'result ' + (res.ok ? 'good' : 'bad');
  }
  await refreshRace();
}

$('tile-race').addEventListener('click', async () => { show('race'); await refreshRace(); });
$('sr-start').addEventListener('click', () => raceAction('srStartRace'));
$('sr-leave').addEventListener('click', () => raceAction('srLeaveRace'));
$('sr-cancel').addEventListener('click', () => raceAction('srCancelRace'));

$('submit-order').addEventListener('click', async () => {
  const items = Object.entries(order)
    .filter(([, qty]) => qty > 0)
    .map(([item, amount]) => ({ item, amount }));
  if (!items.length) return;
  $('submit-order').disabled = true;
  const res = await nui('submitOrder', { items });
  const out = $('order-result');
  if (!res) { out.textContent = 'No answer. Try again.'; out.className = 'result bad'; }
  else if (res.state === 'agreed') {
    out.textContent = 'Deal agreed — details in "Your active deal" above. Move.';
    out.className = 'result good';
    renderDeal(res.deal);
  } else {
    out.textContent = res.message || 'The dealer passes.';
    out.className = 'result bad';
  }
  $('submit-order').disabled = false;
});

window.addEventListener('message', async (e) => {
  const d = e.data || {};
  if (d.action === 'open') {
    $('tablet').classList.remove('hidden');
    show('home');
    tabletData = await nui('getTabletData');
  } else if (d.action === 'close') {
    $('tablet').classList.add('hidden');
  } else if (d.action === 'dealExpired') {
    if (tabletData) { renderDeal(null); await refreshMarket(); }
  } else if (d.action === 'streetRaceUpdate') {
    if (!views.race.classList.contains('hidden')) await refreshRace();
  }
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') nui('closeTablet');
});

// Clock for the home screen status bar
setInterval(() => {
  const el = $('clock');
  if (el) el.textContent = new Date().toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
}, 5000);
