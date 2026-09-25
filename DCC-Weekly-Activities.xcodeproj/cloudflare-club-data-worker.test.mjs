// Tests for the club-data Worker's activity dating and fetching.
//
// Run:  node DCC-Weekly-Activities.xcodeproj/cloudflare-club-data-worker.test.mjs
//
// Strava's club-activities endpoint returns no start_date and no activity id,
// so these exercise the first-seen registry that stands in for ride dates.
// Test 3 is a regression guard: before the fingerprint stopped including the
// user-editable activity title, renaming a ride minted a new registry entry
// and re-dated it to "now", letting one ride count in two different weeks.

import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

// The worker ships as .js (CommonJS by default under Node) but is an ES module,
// so stage a .mjs copy and import that. Keeps the test dependency-free.
const here = dirname(fileURLToPath(import.meta.url));
const src = readFileSync(join(here, 'cloudflare-club-data-worker.js'), 'utf8');
const staged = join(mkdtempSync(join(tmpdir(), 'dcc-')), 'worker.mjs');
writeFileSync(staged, src);
const worker = (await import(staged)).default;

// ── In-memory KV ────────────────────────────────────────────────────────────
const makeKV = () => {
  const m = new Map();
  return { m,
    get: async k => (m.has(k) ? m.get(k) : null),
    put: async (k, v) => { m.set(k, v); } };
};

// Strava club activities: NO start_date, NO id — the real endpoint's shape.
const act = (first, last, name, distKm, secs, elev, sport = 'Ride') => ({
  athlete: { firstname: first, lastname: last },
  name, distance: distKm * 1000, moving_time: secs,
  total_elevation_gain: elev, type: sport, sport_type: sport,
});

let CLUB_ACTIVITIES = [];
globalThis.fetch = async (url) => {
  if (String(url).includes('oauth/token'))
    return new Response(JSON.stringify({
      access_token: 'a', refresh_token: 'r',
      expires_at: Math.floor(Date.now()/1000) + 21600 }), { status: 200 });
  if (String(url).includes('/activities'))
    return new Response(JSON.stringify(CLUB_ACTIVITIES), { status: 200 });
  return new Response('{}', { status: 200 });
};

const env = () => ({ STRAVA_KV: makeKV(), STRAVA_CLIENT_ID: '1',
  STRAVA_CLIENT_SECRET: 's', STRAVA_CLUB_ID: '212760', BOT_REFRESH_TOKEN: 'boot' });
const call = (e, path) => worker.fetch(new Request('https://w.dev' + path), e);

let pass = 0, fail = 0;
const check = (label, cond, extra = '') => {
  if (cond) { pass++; console.log('  PASS', label); }
  else { fail++; console.log('  FAIL', label, extra); }
};

// ── 1. Activities with no start_date still land in the current week ─────────
console.log('\n1. Dating activities that Strava returns without start_date');
CLUB_ACTIVITIES = [
  act('Sanjay','Lal','Morning Ride', 40, 6000, 200),
  act('Amit','Kamat','Commute', 25, 4000, 100),
];
let e = env();
let d = await (await call(e, '/club-data')).json();
check('both riders aggregated', d.memberCount === 2, JSON.stringify(d.members?.map(m=>m.name)));
check('dateSource reports observed', d.dateSource === 'observed', d.dateSource);
check('distances correct', d.members.find(m=>m.name==='Sanjay L.').totalDistance === 40);

// ── 2. Walks excluded, rides kept ──────────────────────────────────────────
console.log('\n2. Non-cycling sports excluded');
CLUB_ACTIVITIES = [
  act('Amit','Kamat','Ride', 30, 4000, 100, 'Ride'),
  act('Amit','Kamat','Walk', 5, 3000, 20, 'Walk'),
  act('Amit','Kamat','Gravel', 20, 3000, 80, 'GravelRide'),
];
e = env();
d = await (await call(e, '/club-data')).json();
const amit = d.members.find(m => m.name === 'Amit K.');
check('walk excluded, 2 rides counted', amit.rideCount === 2, `got ${amit.rideCount}`);
check('walk distance excluded', amit.totalDistance === 50, `got ${amit.totalDistance}`);

// ── 3. THE REGRESSION: renaming an activity must not re-date it ────────────
console.log('\n3. Rename does not re-enter the activity into a later week');
e = env();
CLUB_ACTIVITIES = [act('Kishor','M','Morning Ride', 50, 7000, 300)];
await call(e, '/club-data?force=1');
const reg1 = JSON.parse(await e.STRAVA_KV.get('activity_registry'));
const fp1 = Object.keys(reg1)[0];
const seen1 = reg1[fp1];
// rider renames the same ride; all physical fields unchanged
CLUB_ACTIVITIES = [act('Kishor','M','Chill in the wind!', 50, 7000, 300)];
await new Promise(r => setTimeout(r, 15));
await call(e, '/club-data?force=1');
const reg2 = JSON.parse(await e.STRAVA_KV.get('activity_registry'));
check('registry still holds exactly 1 entry', Object.keys(reg2).length === 1,
  `got ${Object.keys(reg2).length}: ${JSON.stringify(reg2)}`);
check('first-seen timestamp unchanged by rename', reg2[fp1] === seen1,
  `${seen1} -> ${reg2[fp1]}`);

// ── 4. weekOffset beyond registry retention is refused, not silently empty ──
console.log('\n4. Week offsets beyond the registry horizon');
e = env();
let r = await call(e, '/club-data?weekOffset=-40');
check('offset -40 refused with 422', r.status === 422, `got ${r.status}`);
check('error explains the horizon', (await r.json()).error.includes('registry'));
r = await call(e, '/club-data?weekOffset=-4');
check('offset -4 still allowed', r.status === 200, `got ${r.status}`);
r = await call(e, '/club-data?weekOffset=1');
check('future offset refused', r.status === 400, `got ${r.status}`);

// ── 5. Pagination cap ──────────────────────────────────────────────────────
console.log('\n5. Pagination is bounded');
let pages = 0;
const realFetch = globalThis.fetch;
globalThis.fetch = async (url) => {
  if (String(url).includes('/activities')) {
    pages++;
    return new Response(JSON.stringify(
      Array.from({length:200}, (_,i) => act('R'+i,'X','Ride', 10, 1000, 10))), {status:200});
  }
  return realFetch(url);
};
e = env();
await call(e, '/club-data?force=1');
check('stops at MAX_ACTIVITY_PAGES (5)', pages === 5, `fetched ${pages} pages`);
globalThis.fetch = realFetch;   // restore, or later tests see the paging mock

// ── 6. Deploying the new fingerprint must not re-date existing activities ───
console.log('\n6. v1 -> v2 fingerprint migration preserves first-seen dates');
e = env();
// Deliberately in an EARLIER week than today, so inheriting it must keep the
// ride out of the current week's totals.
const oldSeen = '2026-09-08T08:00:00.000Z';
// Two v1 entries for ONE ride, because the rider renamed it mid-week.
await e.STRAVA_KV.put('activity_registry', JSON.stringify({
  'JalajM_Morning Ride_42000_6000': oldSeen,
  'JalajM_Epic climb!_42000_6000': '2026-09-09T19:30:00.000Z',   // same ride, renamed
}));
CLUB_ACTIVITIES = [act('Jalaj','M','Epic climb!', 42, 6000, 250)];
d = await (await call(e, '/club-data?force=1')).json();
const reg6 = JSON.parse(await e.STRAVA_KV.get('activity_registry'));
const v2key = Object.keys(reg6).find(k => k.startsWith('v2:'));
check('a v2 entry was created', !!v2key, Object.keys(reg6).join(' | '));
check('it inherited the EARLIEST v1 sighting, not now', reg6[v2key] === oldSeen,
  `expected ${oldSeen}, got ${reg6[v2key]}`);
check('so the ride is not counted into the current week', d.memberCount === 0,
  `memberCount ${d.memberCount} - ride wrongly re-dated into this week`);

// Without a v1 match, a genuinely new activity is still stamped now.
e = env();
CLUB_ACTIVITIES = [act('Ram','A','Brand new ride', 12, 2000, 40)];
await call(e, '/club-data?force=1');
const reg6b = JSON.parse(await e.STRAVA_KV.get('activity_registry'));
const k6b = Object.keys(reg6b)[0];
check('unmatched activity still dated now', new Date(reg6b[k6b]) > new Date(Date.now() - 60000),
  reg6b[k6b]);

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
