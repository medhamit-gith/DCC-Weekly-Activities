// Tests for the club-data Worker.
//
// Run:  node DCC-Weekly-Activities.xcodeproj/cloudflare-club-data-worker.test.mjs
//
// Strava removed the club activity feed on 1 September 2026, so the leaderboard
// is now assembled from riders who opt in individually. These cover enrolment,
// per-member sync, aggregation, and the failure modes that would quietly lose
// a rider's data.
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const src = readFileSync(join(here, 'cloudflare-club-data-worker.js'), 'utf8');
const staged = join(mkdtempSync(join(tmpdir(), 'dcc-')), 'worker.mjs');
writeFileSync(staged, src);
const worker = (await import(staged)).default;

// ── Mock KV, including the list/delete the sync engine relies on ────────────
const makeKV = () => {
  const m = new Map();
  return { m,
    get: async (k) => (m.has(k) ? m.get(k) : null),
    put: async (k, v) => { m.set(k, v); },
    delete: async (k) => { m.delete(k); },
    list: async ({ prefix = '', cursor } = {}) => ({
      keys: [...m.keys()].filter((k) => k.startsWith(prefix)).map((name) => ({ name })),
      list_complete: true, cursor: undefined,
    }) };
};

const env = () => ({ STRAVA_KV: makeKV(), STRAVA_CLIENT_ID: '1',
  STRAVA_CLIENT_SECRET: 's', STRAVA_CLUB_ID: '212760' });

const call = (e, path) => worker.fetch(new Request('https://w.dev' + path), e);
const postJSON = (e, path, body) => worker.fetch(new Request('https://w.dev' + path, {
  method: 'POST', headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(body) }), e);

let pass = 0, fail = 0;
const check = (label, cond, extra = '') => {
  if (cond) { pass++; console.log('  PASS', label); }
  else { fail++; console.log('  FAIL', label, extra); }
};

// ── Mock Strava ─────────────────────────────────────────────────────────────
// Real feed shape: /athlete/activities DOES return start_date, unlike the club
// feed it replaces.
const ride = (name, km, secs, elev, startDate, sport = 'Ride') => ({
  name, distance: km * 1000, moving_time: secs, total_elevation_gain: elev,
  type: sport, sport_type: sport, start_date: startDate,
});

let athletes = {};        // accessToken -> athlete
let activitiesFor = {};   // athleteId -> [ride]
let refreshCount = 0;
let lastActivitiesURL = null;
let rotate = true;

const installStrava = () => {
  globalThis.fetch = async (url, init) => {
    const u = String(url);
    if (u.includes('oauth/token')) {
      refreshCount++;
      const sent = new URLSearchParams(init.body).get('refresh_token');
      if (sent === 'REVOKED') {
        return new Response(JSON.stringify({ message: 'Bad Request' }), { status: 400 });
      }
      // Strava rotates the refresh token on every single use.
      const next = rotate ? `${sent}-r${refreshCount}` : sent;
      return new Response(JSON.stringify({
        access_token: `AT-${sent}`, refresh_token: next,
        expires_at: Math.floor(Date.now() / 1000) + 21600, token_type: 'Bearer',
      }), { status: 200 });
    }
    // Tokens carry rotation suffixes (AT-RT-k-r3), so resolve by base prefix
    // the way a real account would still map to the same athlete.
    const athleteFor = (t) => athletes[Object.keys(athletes).find((k) => t.startsWith(k))];
    if (u.endsWith('/api/v3/athlete')) {
      const token = (init?.headers?.Authorization || '').replace('Bearer ', '');
      const a = athleteFor(token);
      if (!a) return new Response('Unauthorized', { status: 401 });
      return new Response(JSON.stringify(a), { status: 200 });
    }
    if (u.includes('/athlete/activities')) {
      lastActivitiesURL = u;
      const token = (init?.headers?.Authorization || '').replace('Bearer ', '');
      const a = athleteFor(token);
      return new Response(JSON.stringify(a ? (activitiesFor[a.id] ?? []) : []), { status: 200 });
    }
    return new Response('{}', { status: 200 });
  };
};

// Monday of the current week, so fixtures always land inside it.
const monday = (() => {
  const n = new Date();
  const d = new Date(Date.UTC(n.getUTCFullYear(), n.getUTCMonth(), n.getUTCDate()));
  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));
  return d;
})();
const dayInWeek = (i, h = 9) =>
  new Date(monday.getTime() + i * 86400000 + h * 3600000).toISOString();

// ── 1. Enrolment ────────────────────────────────────────────────────────────
console.log('\n1. Opting a rider in');
installStrava();
athletes = { 'AT-RT-sanjay': { id: 11, firstname: 'Sanjay', lastname: 'Lal' } };
let e = env();
let r = await postJSON(e, '/enrol', { refresh_token: 'RT-sanjay' });
check('POST /enrol returns 200', r.status === 200, `got ${r.status}`);
let body = await r.json();
check('reports the athlete', body.athlete_id === 11 && body.name === 'Sanjay L.', JSON.stringify(body));
let stored = JSON.parse(await e.STRAVA_KV.get('member:11'));
check('stores the ROTATED refresh token, not the one sent',
  stored.refreshToken.startsWith('RT-sanjay-r'), stored.refreshToken);
r = await postJSON(e, '/enrol', { refresh_token: 'REVOKED' });
check('a dead token is rejected, not stored', r.status === 502, `got ${r.status}`);
check('nothing extra written', (await e.STRAVA_KV.list({ prefix: 'member:' })).keys.length === 1);

// ── 2. Sync and aggregation ─────────────────────────────────────────────────
console.log('\n2. Syncing rides and building the leaderboard');
e = env();
athletes = {
  'AT-RT-a': { id: 11, firstname: 'Sanjay', lastname: 'Lal' },
  'AT-RT-b': { id: 22, firstname: 'Amit', lastname: 'Kamat' },
};
activitiesFor = {
  11: [ride('Long one', 100, 12000, 500, dayInWeek(1)),
       ride('Short', 40, 5000, 100, dayInWeek(3))],
  22: [ride('Commute', 25, 4000, 80, dayInWeek(2)),
       ride('Parkrun', 5, 1800, 10, dayInWeek(2), 'Run')],   // must be excluded
};
await postJSON(e, '/enrol', { refresh_token: 'RT-a' });
await postJSON(e, '/enrol', { refresh_token: 'RT-b' });
let data = await (await call(e, '/club-data?force=1')).json();
check('both riders on the board', data.memberCount === 2, JSON.stringify(data.members?.map(m => m.name)));
check('ordered by distance', data.members[0].name === 'Sanjay L.', data.members[0]?.name);
check('distances summed', data.members[0].totalDistance === 140, `${data.members[0].totalDistance}`);
check('run excluded from a cycling board', data.members[1].rideCount === 1, `${data.members[1].rideCount}`);
check('dates are real, not observed', data.dateSource === 'strava', data.dateSource);
check('real start_date preserved',
  data.members[0].activities[0].startDate?.startsWith(dayInWeek(1).slice(0, 10)),
  data.members[0].activities[0].startDate);
check('enrolledCount reported so the UI can caption it', data.enrolledCount === 2, `${data.enrolledCount}`);
check('week window sent to Strava', /after=\d+&before=\d+/.test(lastActivitiesURL), lastActivitiesURL);

// ── 3. Refresh-token rotation must be persisted ─────────────────────────────
// If a rotation is dropped, the stored token is dead and that rider silently
// stops syncing forever, with no way back but re-authorising.
console.log('\n3. Rotation survives repeated syncs');
e = env();
athletes = { 'AT-RT-c': { id: 33, firstname: 'Kishor', lastname: 'M' } };
activitiesFor = { 33: [ride('Ride', 30, 4000, 90, dayInWeek(1))] };
await postJSON(e, '/enrol', { refresh_token: 'RT-c' });
let before = JSON.parse(await e.STRAVA_KV.get('member:33')).refreshToken;
// Expire the access token so the next sync is forced to refresh.
let m33 = JSON.parse(await e.STRAVA_KV.get('member:33'));
m33.accessExpires = Math.floor(Date.now() / 1000) - 10;
await e.STRAVA_KV.put('member:33', JSON.stringify(m33));
await call(e, '/club-data?force=1');
let after = JSON.parse(await e.STRAVA_KV.get('member:33')).refreshToken;
check('token rotated on use', after !== before, `${before} -> ${after}`);
check('rider still syncing after rotation',
  (await (await call(e, '/club-data')).json()).memberCount === 1);

// ── 4. One broken rider must not block the club ─────────────────────────────
console.log('\n4. A revoked authorisation is isolated');
e = env();
athletes = { 'AT-RT-ok': { id: 44, firstname: 'Jalaj', lastname: 'M' } };
activitiesFor = { 44: [ride('Ride', 60, 8000, 200, dayInWeek(2))] };
await postJSON(e, '/enrol', { refresh_token: 'RT-ok' });
// Plant a member whose authorisation has since been revoked.
await e.STRAVA_KV.put('member:99', JSON.stringify({
  athleteId: 99, firstname: 'Gone', lastname: 'Away',
  refreshToken: 'REVOKED', enrolledAt: '2026-09-01T00:00:00.000Z' }));
data = await (await call(e, '/club-data?force=1')).json();
check('healthy rider still counted', data.memberCount === 1, JSON.stringify(data.members?.map(m => m.name)));
const broken = JSON.parse(await e.STRAVA_KV.get('member:99'));
check('failure recorded against that rider', !!broken.lastError, JSON.stringify(broken.lastError));
let diag = await (await call(e, '/diagnostics')).json();
check('diagnostics surfaces the broken rider',
  diag.enrolledCount === 2 && diag.members.some(m => m.lastError), JSON.stringify(diag.members));

// ── 5. Opting out removes the rider AND their rides ─────────────────────────
console.log('\n5. Opting out');
r = await postJSON(e, '/leave', { access_token: 'AT-RT-ok' });
check('POST /leave returns 200', r.status === 200, `got ${r.status}`);
check('member record deleted', (await e.STRAVA_KV.get('member:44')) === null);
const leftovers = (await e.STRAVA_KV.list({ prefix: 'week:' })).keys
  .filter(k => k.name.endsWith(':44'));
check('their stored rides deleted too', leftovers.length === 0, JSON.stringify(leftovers));
r = await postJSON(e, '/leave', { access_token: 'not-a-token' });
check('cannot opt out without a valid token', r.status === 401, `got ${r.status}`);

// ── 6. OAuth endpoints the apps depend on ───────────────────────────────────
// Regression guard: these 404'd after one Worker script was deployed over the
// other, which blocked sign-in in both the iOS and tvOS apps.
console.log('\n6. /exchange and /refresh');
e = env();
r = await postJSON(e, '/exchange', { code: 'auth-code-123' });
check('POST /exchange returns 200 (was 404)', r.status === 200, `got ${r.status}`);
body = await r.json();
check('returns the token pair', !!body.access_token && !!body.refresh_token);
check('does not leak extra Strava fields', body.athlete === undefined, JSON.stringify(Object.keys(body)));
r = await postJSON(e, '/refresh', { refresh_token: 'old-RT' });
check('POST /refresh returns 200 (was 404)', r.status === 200, `got ${r.status}`);
r = await postJSON(e, '/exchange', { nope: 1 });
check('missing code rejected with 400', r.status === 400, `got ${r.status}`);

// ── 7. Week range ───────────────────────────────────────────────────────────
console.log('\n7. Week offsets');
r = await call(e, '/club-data?weekOffset=1');
check('future week refused', r.status === 400, `got ${r.status}`);
r = await call(e, '/club-data?weekOffset=-60');
check('beyond retained data refused with 422', r.status === 422, `got ${r.status}`);
r = await call(e, '/club-data?weekOffset=-3');
check('recent past week allowed', r.status === 200, `got ${r.status}`);

// ── 8. Enrolled riders get access tokens from the Worker ───────────────────
// Strava issues one refresh token per rider and rotates it on every use, so
// once the Worker owns it the app cannot refresh independently - it would
// invalidate the Worker's token and sign the rider out. The app presents its
// member_key instead.
console.log('\n8. Token ownership after enrolment');
e = env();
athletes = { 'AT-RT-k': { id: 55, firstname: 'Anand', lastname: 'I' } };
activitiesFor = { 55: [] };
r = await postJSON(e, '/enrol', { refresh_token: 'RT-k' });
const enrolBody = await r.json();
check('enrolment returns a member_key',
  typeof enrolBody.member_key === 'string' && enrolBody.member_key.length === 64,
  JSON.stringify(enrolBody.member_key));

r = await postJSON(e, '/refresh', { athlete_id: 55, member_key: enrolBody.member_key });
check('refresh by member_key returns 200', r.status === 200, `got ${r.status}`);
body = await r.json();
check('returns an access token', typeof body.access_token === 'string', JSON.stringify(body));
check('never hands back the refresh token', body.refresh_token === undefined,
  JSON.stringify(Object.keys(body)));

r = await postJSON(e, '/refresh', { athlete_id: 55, member_key: 'wrong'.padEnd(64, '0') });
check('wrong key rejected with 401', r.status === 401, `got ${r.status}`);
r = await postJSON(e, '/refresh', { athlete_id: 55 });
check('athlete_id alone is not enough', r.status === 400, `got ${r.status}`);
r = await postJSON(e, '/refresh', { athlete_id: 999999, member_key: enrolBody.member_key });
check('key does not work for another rider', r.status === 401, `got ${r.status}`);

// Re-enrolling must not invalidate the app's stored key.
r = await postJSON(e, '/enrol', { refresh_token: JSON.parse(await e.STRAVA_KV.get('member:55')).refreshToken });
check('re-enrolling keeps the same member_key',
  (await r.json()).member_key === enrolBody.member_key);

// ── 9. A new rider appears immediately, not an hour later ──────────────────
console.log('\n9. First sync happens at enrolment');
e = env();
athletes = { 'AT-RT-new': { id: 77, firstname: 'Pankaj', lastname: 'B' } };
activitiesFor = { 77: [ride('First ride', 33, 5000, 120, dayInWeek(1))] };
await postJSON(e, '/enrol', { refresh_token: 'RT-new' });
// Read WITHOUT force, exactly as the app does right after opting in.
data = await (await call(e, '/club-data')).json();
check('rider is on the board straight after opting in', data.memberCount === 1,
  JSON.stringify(data.members?.map(m => m.name)));
check('with their ride already counted', data.members?.[0]?.totalDistance === 33,
  `${data.members?.[0]?.totalDistance}`);

// A rider whose feed cannot be read must still enrol; the cron retries later.
e = env();
athletes = { 'AT-RT-odd': { id: 88, firstname: 'Ram', lastname: 'A' } };
activitiesFor = {};
r = await postJSON(e, '/enrol', { refresh_token: 'RT-odd' });
check('enrolment survives a failed first sync', r.status === 200, `got ${r.status}`);

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
