/**
 * DCC Weekly Activities — Club Data Worker
 *
 * Deployed as the Cloudflare Worker `dcc-strava`
 * (https://dcc-strava.amit-r-kamat.workers.dev).
 *
 * ── How the leaderboard is built (this changed) ──────────────────────────────
 *   Strava REMOVED GET /clubs/{id}/activities on 1 September 2026, so no token
 *   can read the whole club's rides any more. That endpoint now 404s with
 *   "resource.path:invalid", which is what silently emptied the leaderboard.
 *
 *   The Worker now reads each rider's OWN activity feed instead. Riders opt in
 *   via POST /enrol; the Worker stores their refresh token and, on an hourly
 *   cron, syncs a slice of them into per-week KV records that /club-data
 *   aggregates.
 *
 *   This is better data than the club feed ever gave: /athlete/activities
 *   returns a real start_date, so weeks are exact. The first-seen "activity
 *   registry" that used to stand in for missing dates is gone.
 *
 *   The tradeoff: the leaderboard covers only riders who opted in, never the
 *   full club. `enrolledCount` in the payload is there so the UI can say so.
 *
 * ── Privacy ─────────────────────────────────────────────────────────────────
 *   This Worker stores a Strava refresh token per opted-in rider, which grants
 *   ongoing read access to their activities. Enrolment must be an explicit
 *   choice, never a side effect of signing in. POST /leave deletes a rider's
 *   token and their stored rides. Keep PRIVACY_POLICY.md in step with this.
 *
 * ── Environment variables (Settings → Variables) ─────────────────────────────
 *   STRAVA_CLIENT_ID      = 161984
 *   STRAVA_CLIENT_SECRET  = <Strava client secret>
 *   STRAVA_CLUB_ID        = 212760   (informational only now)
 *
 * ── KV binding ───────────────────────────────────────────────────────────────
 *   STRAVA_KV → the namespace titled "DCC_DATA"
 *     (binding name and namespace title differ; this is expected)
 *   Keys: member:{athleteId}            per-rider token + sync state
 *         week:{YYYY-MM-DD}:{athleteId} that rider's rides for that week
 *         club_data_week_{YYYY-MM-DD}   cached aggregate
 *         sync_cursor                   round-robin position
 *
 * ── Endpoints ────────────────────────────────────────────────────────────────
 *   GET  /club-data[?weekOffset=N][&force=1]   leaderboard for a week
 *   GET  /diagnostics                          enrolment and sync health
 *   POST /enrol   { refresh_token }            opt a rider in
 *   POST /leave   { access_token }             opt a rider out, delete data
 *   POST /exchange, /refresh                   Strava OAuth for the apps
 *   GET  /features, /features-api, /release-notes
 *   POST /feature-request, /github-webhook
 *
 * ── Cron ─────────────────────────────────────────────────────────────────────
 *   "0 * * * *" — hourly, syncing MEMBERS_PER_SYNC riders per run so the app
 *   stays inside Strava's 2000 requests/day budget.
 */

const STRAVA_TOKEN_URL = "https://www.strava.com/api/v3/oauth/token";
const STRAVA_CLUB_URL = "https://www.strava.com/api/v3/clubs";
const CACHE_TTL_SECONDS = 3600;
function getWeekRange(weekOffset = 0) {
  const now = new Date();
  const dayOfWeek = (now.getUTCDay() + 6) % 7;
  const monday = new Date(now);
  monday.setUTCDate(now.getUTCDate() - dayOfWeek + weekOffset * 7);
  monday.setUTCHours(0, 0, 0, 0);
  const sunday = new Date(monday);
  sunday.setUTCDate(monday.getUTCDate() + 6);
  sunday.setUTCHours(23, 59, 59, 999);
  return { start: monday, end: sunday };
}
function isoWeekKey(date) {
  const d = new Date(date);
  const year = d.getUTCFullYear();
  const month = String(d.getUTCMonth() + 1).padStart(2, "0");
  const day = String(d.getUTCDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}
function weekLabel(monday) {
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  return `w/c ${monday.getUTCDate()} ${months[monday.getUTCMonth()]}`;
}
function formatMovingTime(seconds) {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor(seconds % 3600 / 60);
  return h > 0 ? `${h}h ${m}m` : `${m}m`;
}
// The club-admin bot token (getAccessToken / BOT_REFRESH_TOKEN) was removed
// with the club feed it served. Each member now authorises for themselves.

// ── Per-member sync ─────────────────────────────────────────────────────────
// Strava removed GET /clubs/{id}/activities on 1 September 2026, so there is no
// longer any way for one admin token to read the whole club's rides. Instead
// each rider opts in, and the Worker reads each of their own activity feeds.
//
// This is strictly better data than the club feed ever gave us: /athlete/
// activities returns a real start_date, so weeks are exact. The first-seen
// registry that used to stand in for missing dates is gone entirely.
const MEMBER_PREFIX = "member:";
const WEEK_PREFIX = "week:";
// Strava allows 2000 requests/day for the whole app. Syncing every member every
// hour would blow through that, so each run takes a slice and the cursor moves
// on - 20/hour covers 100 members roughly every five hours.
const MEMBERS_PER_SYNC = 20;
const WEEK_DATA_TTL_DAYS = 120;
const STRAVA_ATHLETE_URL = "https://www.strava.com/api/v3/athlete";
const STRAVA_ATHLETE_ACTIVITIES_URL = "https://www.strava.com/api/v3/athlete/activities";

function memberKey(athleteId) {
  return `${MEMBER_PREFIX}${athleteId}`;
}

function weekMemberKey(weekStart, athleteId) {
  return `${WEEK_PREFIX}${isoWeekKey(weekStart)}:${athleteId}`;
}

function displayName(member) {
  const last = (member.lastname || "").charAt(0);
  return last ? `${member.firstname} ${last}.` : `${member.firstname}`.trim();
}

async function listKeys(env, prefix) {
  const names = [];
  let cursor;
  do {
    const page = await env.STRAVA_KV.list({ prefix, cursor });
    names.push(...page.keys.map((k) => k.name));
    cursor = page.list_complete ? null : page.cursor;
  } while (cursor);
  return names;
}

async function listMembers(env) {
  const members = [];
  for (const name of await listKeys(env, MEMBER_PREFIX)) {
    const raw = await env.STRAVA_KV.get(name);
    if (!raw) continue;
    try {
      members.push(JSON.parse(raw));
    } catch {
      console.error(`Unreadable member record: ${name}`);
    }
  }
  return members;
}

async function saveMember(env, member) {
  await env.STRAVA_KV.put(memberKey(member.athleteId), JSON.stringify(member));
}

async function getMember(env, athleteId) {
  const raw = await env.STRAVA_KV.get(memberKey(athleteId));
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

/** Strava token grant returning parsed data; throws with Strava's own message. */
async function stravaTokenData(env, params) {
  const body = new URLSearchParams({
    client_id: env.STRAVA_CLIENT_ID,
    client_secret: env.STRAVA_CLIENT_SECRET,
    ...params
  });
  const res = await fetch(STRAVA_TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: body.toString()
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(data.message ?? `Strava token request failed (${res.status})`);
  }
  return data;
}

/**
 * A usable access token for one member.
 *
 * Strava rotates the refresh token on every use, so the rotation MUST be
 * persisted - dropping it locks that member out on the next sync with no way
 * back except re-authorising.
 */
async function memberAccessToken(env, member) {
  const nowSec = Math.floor(Date.now() / 1e3);
  if (member.accessToken && (member.accessExpires ?? 0) - nowSec > 300) {
    return member.accessToken;
  }
  const data = await stravaTokenData(env, {
    refresh_token: member.refreshToken,
    grant_type: "refresh_token"
  });
  member.refreshToken = data.refresh_token ?? member.refreshToken;
  member.accessToken = data.access_token;
  member.accessExpires = data.expires_at;
  await saveMember(env, member);
  return member.accessToken;
}

function newMemberKey() {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  return [...bytes].map((b) => b.toString(16).padStart(2, "0")).join("");
}

/** Opt a rider in. Verifies the token really works before storing anything. */
async function enrolMember(env, refreshToken) {
  const data = await stravaTokenData(env, {
    refresh_token: refreshToken,
    grant_type: "refresh_token"
  });
  const res = await fetch(STRAVA_ATHLETE_URL, {
    headers: { Authorization: `Bearer ${data.access_token}` }
  });
  if (!res.ok) {
    throw new Error(`Could not read athlete profile (${res.status})`);
  }
  const athlete = await res.json();
  const existing = await getMember(env, athlete.id);
  const member = {
    athleteId: athlete.id,
    firstname: athlete.firstname ?? "",
    lastname: athlete.lastname ?? "",
    refreshToken: data.refresh_token ?? refreshToken,
    accessToken: data.access_token,
    accessExpires: data.expires_at,
    enrolledAt: existing?.enrolledAt ?? (new Date()).toISOString(),
    lastSyncAt: existing?.lastSyncAt ?? null,
    lastError: null,
    // Once enrolled the Worker owns the rotating refresh token, so the app can
    // no longer refresh on its own. It presents this secret to /refresh
    // instead. Re-enrolling keeps the existing key so the app stays valid.
    memberKey: existing?.memberKey ?? newMemberKey()
  };
  await saveMember(env, member);
  return member;
}

/** Opt a rider out and delete the week data holding their rides. */
async function removeMember(env, athleteId) {
  await env.STRAVA_KV.delete(memberKey(athleteId));
  for (const name of await listKeys(env, WEEK_PREFIX)) {
    if (name.endsWith(`:${athleteId}`)) await env.STRAVA_KV.delete(name);
  }
}

/** Read one member's rides for a week and store them under that week. */
async function syncMemberWeek(env, member, weekStart, weekEnd) {
  const token = await memberAccessToken(env, member);
  const after = Math.floor(weekStart.getTime() / 1e3) - 1;
  const before = Math.floor(weekEnd.getTime() / 1e3) + 1;
  const url = `${STRAVA_ATHLETE_ACTIVITIES_URL}?after=${after}&before=${before}&per_page=100`;
  const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
  if (!res.ok) {
    throw new Error(`Activities fetch failed (${res.status})`);
  }
  const raw = await res.json();
  const activities = (Array.isArray(raw) ? raw : [])
    .filter((a) => CYCLING_SPORT_TYPES.has(a.sport_type ?? a.type))
    .map((a) => {
      const movingTime = a.moving_time ?? 0;
      const speedKmh = movingTime > 0 ? (a.distance / movingTime) * 3.6 : 0;
      return {
        name: a.name,
        distance: Math.round((a.distance / 1e3) * 10) / 10,
        movingTime,
        elevationGain: Math.round(a.total_elevation_gain ?? 0),
        averageSpeed: Math.round(speedKmh * 10) / 10,
        type: a.type,
        sportType: a.sport_type ?? a.type,
        startDate: a.start_date
      };
    });
  await env.STRAVA_KV.put(
    weekMemberKey(weekStart, member.athleteId),
    JSON.stringify({
      athleteId: member.athleteId,
      name: displayName(member),
      activities,
      syncedAt: (new Date()).toISOString()
    }),
    { expirationTtl: WEEK_DATA_TTL_DAYS * 86400 }
  );
  return activities.length;
}

/** Aggregate whatever has been synced for a week into the leaderboard shape. */
async function buildWeekPayload(env, weekOffset) {
  const { start: weekStart, end: weekEnd } = getWeekRange(weekOffset);
  const prefix = `${WEEK_PREFIX}${isoWeekKey(weekStart)}:`;
  const rows = [];
  for (const name of await listKeys(env, prefix)) {
    const raw = await env.STRAVA_KV.get(name);
    if (!raw) continue;
    let record;
    try {
      record = JSON.parse(raw);
    } catch {
      continue;
    }
    const acts = record.activities ?? [];
    if (acts.length === 0) continue;
    const totalDistance = acts.reduce((s, a) => s + a.distance, 0);
    const totalMovingTime = acts.reduce((s, a) => s + a.movingTime, 0);
    const weightedSpeed = acts.reduce((s, a) => s + a.averageSpeed * a.distance, 0);
    rows.push({
      name: record.name,
      rideCount: acts.length,
      totalDistance: Math.round(totalDistance * 10) / 10,
      totalElevation: acts.reduce((s, a) => s + a.elevationGain, 0),
      totalMovingTime,
      avgSpeed: totalDistance > 0 ? Math.round((weightedSpeed / totalDistance) * 10) / 10 : 0,
      movingTimeFormatted: formatMovingTime(totalMovingTime),
      activities: acts
    });
  }
  rows.sort((a, b) => b.totalDistance - a.totalDistance);
  const enrolled = await listKeys(env, MEMBER_PREFIX);
  const payload = {
    lastFetchedAt: (new Date()).toISOString(),
    weekLabel: weekLabel(weekStart),
    weekStart: weekStart.toISOString().slice(0, 10),
    weekEnd: weekEnd.toISOString().slice(0, 10),
    memberCount: rows.length,
    totalActivities: rows.reduce((s, r) => s + r.rideCount, 0),
    // Real ride timestamps now, from each rider's own feed - not observations.
    dateSource: "strava",
    // The leaderboard only covers riders who opted in, so the UI should say so
    // rather than implying it speaks for all 100 club members.
    enrolledCount: enrolled.length,
    members: rows
  };
  await env.STRAVA_KV.put(
    `club_data_week_${isoWeekKey(weekStart)}`,
    JSON.stringify(payload),
    { expirationTtl: CACHE_TTL_SECONDS }
  );
  return payload;
}

/**
 * Sync a slice of members, then rebuild the week. Round-robins via a stored
 * cursor so every member is reached in turn without exceeding Strava's limits.
 * A member whose token has been revoked is recorded and skipped, never
 * blocking the rest of the club.
 */
async function syncBatch(env, weekOffset = 0) {
  const { start: weekStart, end: weekEnd } = getWeekRange(weekOffset);
  const members = await listMembers(env);
  if (members.length === 0) {
    return { enrolled: 0, synced: 0, failed: 0 };
  }
  members.sort((a, b) => a.athleteId - b.athleteId);
  const cursor = await env.STRAVA_KV.get("sync_cursor");
  const found = cursor ? members.findIndex((m) => String(m.athleteId) === cursor) : -1;
  const startIndex = found >= 0 ? found + 1 : 0;

  let synced = 0;
  let failed = 0;
  let last = null;
  const count = Math.min(MEMBERS_PER_SYNC, members.length);
  for (let i = 0; i < count; i++) {
    const member = members[(startIndex + i) % members.length];
    last = member.athleteId;
    try {
      await syncMemberWeek(env, member, weekStart, weekEnd);
      member.lastSyncAt = (new Date()).toISOString();
      member.lastError = null;
      synced++;
    } catch (err) {
      member.lastError = err.message;
      failed++;
      console.error(`Sync failed for athlete ${member.athleteId}: ${err.message}`);
    }
    await saveMember(env, member);
  }
  if (last !== null) await env.STRAVA_KV.put("sync_cursor", String(last));
  await buildWeekPayload(env, weekOffset);
  return { enrolled: members.length, synced, failed };
}
const CYCLING_SPORT_TYPES = new Set([
  "Ride",
  "MountainBikeRide",
  "GravelRide",
  "EBikeRide",
  "EMountainBikeRide",
  "VirtualRide",
  "Handcycle",
  "Velomobile"
]);
function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*"
    }
  });
}
function errorResponse(message, status = 400) {
  return jsonResponse({ error: message }, status);
}
// ── Strava OAuth token grants (used by /exchange and /refresh) ──────────────
// These endpoints belong to the iOS and tvOS clients, which post here rather
// than to Strava directly so the client secret never ships in an app binary.
//
// They previously lived in a second Worker script. Both scripts were deployed
// to the SAME Worker name, so whichever went up last silently replaced the
// other's routes - and when the club-data script won, /exchange and /refresh
// started returning 404, which blocked sign-in and token refresh in both apps.
// They are merged here so one deploy can no longer clobber the other.
async function stravaTokenGrant(env, extraParams) {
  const params = new URLSearchParams({
    client_id: env.STRAVA_CLIENT_ID,
    client_secret: env.STRAVA_CLIENT_SECRET,
    ...extraParams
  });
  const res = await fetch(STRAVA_TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: params.toString()
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    return errorResponse(data.message ?? "Strava token request failed", res.status);
  }
  // Return only the fields the clients need, never the raw Strava response.
  return jsonResponse({
    access_token: data.access_token,
    refresh_token: data.refresh_token,
    expires_at: data.expires_at,
    token_type: data.token_type
  });
}

async function readJsonField(request, field) {
  let body;
  try {
    body = await request.json();
  } catch {
    return { error: errorResponse("Invalid JSON body") };
  }
  const value = body?.[field];
  if (!value || typeof value !== "string") {
    return { error: errorResponse(`Missing or invalid '${field}' field`) };
  }
  return { value };
}

export default {
  // ── Cron: sync a slice of opted-in members every hour ─────────────────────
  async scheduled(event, env, ctx) {
    ctx.waitUntil(syncBatch(env, 0));
  },
  // ── HTTP requests ──────────────────────────────────────────────────────────
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type"
        }
      });
    }
    const url = new URL(request.url);
    if (url.pathname === "/github-webhook" && request.method === "POST") {
      try {
        const payload = await request.json();
        if (!payload.commits || !Array.isArray(payload.commits)) {
          return jsonResponse({ ok: true, message: "Not a push event" });
        }
        const jiraEmail = env.JIRA_EMAIL || "amit.r.kamat@googlemail.com";
        const jiraToken = env.JIRA_API_TOKEN;
        if (!jiraToken) return jsonResponse({ ok: false, error: "No Jira token" }, 500);
        const jiraAuth = "Basic " + btoa(`${jiraEmail}:${jiraToken}`);
        const repoName = payload.repository?.full_name || "unknown";
        const branch = (payload.ref || "").replace("refs/heads/", "");
        let linked = 0;
        for (const commit of payload.commits) {
          const matches = commit.message.match(/SCRUM-\d+/g);
          if (!matches) continue;
          const uniqueKeys = [...new Set(matches)];
          const shortSha = commit.id.substring(0, 7);
          const commitUrl = commit.url;
          const author = commit.author?.name || "Unknown";
          const filesChanged = (commit.added || []).length + (commit.modified || []).length + (commit.removed || []).length;
          for (const issueKey of uniqueKeys) {
            const commentBody = {
              body: {
                type: "doc",
                version: 1,
                content: [
                  { type: "heading", attrs: { level: 3 }, content: [{ type: "text", text: `Commit ${shortSha} on ${branch}` }] },
                  { type: "paragraph", content: [
                    { type: "text", text: `${commit.message.split("\n")[0]}`, marks: [{ type: "strong" }] }
                  ] },
                  { type: "paragraph", content: [
                    { type: "text", text: `Author: ${author} | Files: ${filesChanged} | Repo: ${repoName}` }
                  ] },
                  { type: "paragraph", content: [
                    { type: "text", text: `View commit: ${commitUrl}` }
                  ] }
                ]
              }
            };
            const commentRes = await fetch(`https://amitrkamat.atlassian.net/rest/api/3/issue/${issueKey}/comment`, {
              method: "POST",
              headers: { "Content-Type": "application/json", "Authorization": jiraAuth },
              body: JSON.stringify(commentBody)
            });
            const linkBody = {
              globalId: `github-commit-${commit.id}`,
              object: {
                url: commitUrl,
                title: `${shortSha}: ${commit.message.split("\n")[0].substring(0, 60)}`,
                icon: { url16x16: "https://github.githubassets.com/favicons/favicon.svg", title: "GitHub" }
              }
            };
            await fetch(`https://amitrkamat.atlassian.net/rest/api/3/issue/${issueKey}/remotelink`, {
              method: "POST",
              headers: { "Content-Type": "application/json", "Authorization": jiraAuth },
              body: JSON.stringify(linkBody)
            });
            linked++;
            console.log(`Linked commit ${shortSha} to ${issueKey}`);
          }
        }
        return jsonResponse({ ok: true, commits: payload.commits.length, linked });
      } catch (err) {
        console.error("GitHub webhook error:", err.message);
        return jsonResponse({ ok: false, error: err.message }, 500);
      }
    }
    if (url.pathname === "/feature-request" && request.method === "POST") {
      try {
        const body = await request.json();
        const { text, submitter, platform, appVersion, timestamp } = body;
        if (!text || text.trim().length < 10) {
          return errorResponse("Feature request text must be at least 10 characters.", 400);
        }
        const summary = `[User Feature Request] ${text.trim().substring(0, 80)}`;
        const description = [
          text.trim(),
          "",
          "---",
          `**Submitter:** ${submitter || "Anonymous"}`,
          `**Platform:** ${platform || "unknown"}`,
          `**App Version:** ${appVersion || "unknown"}`,
          `**Submitted:** ${timestamp || (new Date()).toISOString()}`
        ].join("\\\n");
        const jiraEmail = env.JIRA_EMAIL || "amit.r.kamat@googlemail.com";
        const jiraToken = env.JIRA_API_TOKEN;
        if (!jiraToken) {
          return jsonResponse({ success: false, error: "Jira API token not configured" }, 500);
        }
        const labels = ["user-feature-request", "backlog", ...inferKeywordLabels(text)];
        const jiraPayload = {
          fields: {
            project: { key: "SCRUM" },
            issuetype: { name: "Story" },
            summary,
            description: {
              type: "doc",
              version: 1,
              content: [{
                type: "paragraph",
                content: [{ type: "text", text: description }]
              }]
            },
            labels,
            priority: { name: "Medium" }
          }
        };
        const jiraRes = await fetch("https://amitrkamat.atlassian.net/rest/api/3/issue", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Basic " + btoa(`${jiraEmail}:${jiraToken}`)
          },
          body: JSON.stringify(jiraPayload)
        });
        if (!jiraRes.ok) {
          const errText = await jiraRes.text();
          console.error(`Jira API error (${jiraRes.status}): ${errText}`);
          return jsonResponse({ success: false, error: "Jira API unavailable" }, 502);
        }
        const jiraData = await jiraRes.json();
        if (env.SLACK_WEBHOOK_URL) {
          try {
            await fetch(env.SLACK_WEBHOOK_URL, {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                text: `:bulb: New feature request *${jiraData.key}* from ${submitter || "Anonymous"} (${platform || "unknown"}): ${text.trim().substring(0, 200)}
https://amitrkamat.atlassian.net/browse/${jiraData.key}`
              })
            });
          } catch (notifyErr) {
            console.error("Slack notification failed:", notifyErr.message);
          }
        }
        return jsonResponse({ success: true, issue_key: jiraData.key });
      } catch (err) {
        console.error("Feature request error:", err.message);
        return jsonResponse({ success: false, error: "Internal error" }, 500);
      }
    }
    if (url.pathname === "/exchange" && request.method === "POST") {
      const { value: code, error } = await readJsonField(request, "code");
      if (error) return error;
      return stravaTokenGrant(env, { code, grant_type: "authorization_code" });
    }

    if (url.pathname === "/refresh" && request.method === "POST") {
      const payload = await request.json().catch(() => null);
      if (!payload) return errorResponse("Invalid JSON body");

      // Enrolled rider: the Worker holds the only live refresh token, so it
      // mints the access token and keeps the rotation. Guarded by the rider's
      // own key — athlete ids are effectively public, so accepting one alone
      // would hand anybody an access token for any enrolled rider.
      if (payload.athlete_id && payload.member_key) {
        const member = await getMember(env, payload.athlete_id);
        if (!member || member.memberKey !== payload.member_key) {
          return errorResponse("Not enrolled, or member_key does not match", 401);
        }
        try {
          const accessToken = await memberAccessToken(env, member);
          return jsonResponse({
            access_token: accessToken,
            expires_at: member.accessExpires,
            token_type: "Bearer"
          });
        } catch (err) {
          return errorResponse(`Token refresh failed: ${err.message}`, 502);
        }
      }

      // Not enrolled: unchanged stateless behaviour, app keeps its own token.
      if (!payload.refresh_token || typeof payload.refresh_token !== "string") {
        return errorResponse("Missing or invalid 'refresh_token' field");
      }
      return stravaTokenGrant(env, {
        refresh_token: payload.refresh_token,
        grant_type: "refresh_token"
      });
    }

    // Opt in to the leaderboard. The rider has already authorised the app, so
    // this hands the Worker the refresh token it needs to read their rides on
    // their behalf. Consent is explicit: the app only calls this when the
    // rider has chosen to share, never as part of plain sign-in.
    if (url.pathname === "/enrol" && request.method === "POST") {
      const { value: refreshToken, error } = await readJsonField(request, "refresh_token");
      if (error) return error;
      try {
        const member = await enrolMember(env, refreshToken);
        return jsonResponse({
          enrolled: true,
          athlete_id: member.athleteId,
          name: displayName(member),
          // The app must keep this; without it an enrolled rider cannot get a
          // new access token and will be signed out when the current one ages.
          member_key: member.memberKey
        });
      } catch (err) {
        return errorResponse(`Enrolment failed: ${err.message}`, 502);
      }
    }

    // Opt out. Requires a working access token for that athlete, so a rider can
    // only remove themselves. Deletes their stored rides as well as their token.
    if (url.pathname === "/leave" && request.method === "POST") {
      const { value: accessToken, error } = await readJsonField(request, "access_token");
      if (error) return error;
      try {
        const res = await fetch(STRAVA_ATHLETE_URL, {
          headers: { Authorization: `Bearer ${accessToken}` }
        });
        if (!res.ok) return errorResponse("Access token is not valid", 401);
        const athlete = await res.json();
        await removeMember(env, athlete.id);
        // The member record held the key, so it dies with it; the app must fall
        // back to its own refresh token from here.
        return jsonResponse({ enrolled: false, athlete_id: athlete.id });
      } catch (err) {
        return errorResponse(`Opt-out failed: ${err.message}`, 502);
      }
    }

    if (request.method !== "GET") {
      return errorResponse("Method not allowed", 405);
    }
    if (url.pathname === "/release-notes" && request.method === "GET") {
      try {
        const jiraEmail = env.JIRA_EMAIL || "amit.r.kamat@googlemail.com";
        const jiraToken = env.JIRA_API_TOKEN;
        if (!jiraToken) return jsonResponse({ error: "Jira not configured" }, 500);
        const jiraAuth = "Basic " + btoa(`${jiraEmail}:${jiraToken}`);
        const issues = [];
        const fetchPromises = [];
        for (let i = 53; i <= 99; i++) {
          const issueKey = `SCRUM-${i}`;
          fetchPromises.push(
            fetch(`https://amitrkamat.atlassian.net/rest/api/3/issue/${issueKey}?fields=summary,status,labels,priority,updated`, {
              headers: { "Authorization": jiraAuth, "Content-Type": "application/json" }
            }).then(async (r) => {
              if (!r.ok) return null;
              const d = await r.json();
              if (d.fields?.status?.name !== "Done") return null;
              return {
                key: d.key,
                summary: d.fields.summary,
                labels: d.fields.labels || [],
                priority: d.fields.priority?.name || "Medium",
                updated: d.fields.updated
              };
            }).catch(() => null)
          );
        }
        const results = await Promise.all(fetchPromises);
        for (const r of results) {
          if (r) issues.push(r);
        }
        const categories = {
          bugFixes: [],
          newFeatures: [],
          improvements: [],
          infrastructure: []
        };
        for (const issue of issues) {
          const labels = issue.labels.map((l) => l.toLowerCase());
          const summary = issue.summary.toLowerCase();
          if (labels.includes("bug-fix") || labels.includes("critical") || summary.includes("fix")) {
            categories.bugFixes.push(issue);
          } else if (labels.includes("feature") || labels.includes("coaching") || labels.includes("ui") || summary.includes("add")) {
            categories.newFeatures.push(issue);
          } else if (labels.includes("enhancement") || labels.includes("performance") || labels.includes("quality")) {
            categories.improvements.push(issue);
          } else {
            categories.infrastructure.push(issue);
          }
        }
        const version = url.searchParams.get("version") || "v3.0";
        const result = {
          version,
          generatedAt: (new Date()).toISOString(),
          totalStories: issues.length,
          categories: {
            bugFixes: { title: "Bug Fixes", icon: "ladybug.fill", items: categories.bugFixes },
            newFeatures: { title: "New Features", icon: "star.fill", items: categories.newFeatures },
            improvements: { title: "Improvements", icon: "arrow.up.circle.fill", items: categories.improvements },
            infrastructure: { title: "Infrastructure", icon: "gearshape.2.fill", items: categories.infrastructure }
          }
        };
        return jsonResponse(result);
      } catch (err) {
        console.error("Release notes error:", err.message);
        return jsonResponse({ error: err.message }, 500);
      }
    }
    if (url.pathname === "/diagnostics") {
      try {
        const members = await listMembers(env);
        const { start: weekStart } = getWeekRange(0);
        const weekKeys = await listKeys(env, `${WEEK_PREFIX}${isoWeekKey(weekStart)}:`);
        return jsonResponse({
          // The club feed this Worker used to read was removed by Strava on
          // 1 September 2026; the leaderboard is now built from riders who
          // opted in individually.
          mode: "per-member",
          enrolledCount: members.length,
          syncedThisWeek: weekKeys.length,
          syncCursor: await env.STRAVA_KV.get("sync_cursor"),
          membersPerSync: MEMBERS_PER_SYNC,
          members: members
            .sort((a, b) => (b.lastSyncAt ?? "").localeCompare(a.lastSyncAt ?? ""))
            .map((m) => ({
              athleteId: m.athleteId,
              name: displayName(m),
              enrolledAt: m.enrolledAt,
              lastSyncAt: m.lastSyncAt,
              // Usually a revoked authorisation; that rider must opt in again.
              lastError: m.lastError
            }))
        });
      } catch (err) {
        return errorResponse(`Diagnostics failed: ${err.message}`, 500);
      }
    }
    if (url.pathname === "/club-data") {
      const offsetParam = url.searchParams.get("weekOffset");
      const weekOffset = offsetParam !== null ? parseInt(offsetParam, 10) : 0;
      // The first-seen registry is the only thing dating these activities, so
      // it bounds how far back a week can be answered. Past that horizon the
      // response was silently sparse and looked legitimate; now it is refused.
      const maxWeeksBack = Math.floor(WEEK_DATA_TTL_DAYS / 7);
      if (isNaN(weekOffset) || weekOffset > 0) {
        return errorResponse("Invalid weekOffset. Must be 0 (current) or negative (past weeks).");
      }
      if (weekOffset < -maxWeeksBack) {
        return errorResponse(
          `weekOffset ${weekOffset} is older than the ${WEEK_DATA_TTL_DAYS} days of ` +
          `week data kept (max ${-maxWeeksBack}).`,
          422
        );
      }
      const { start: weekStart } = getWeekRange(weekOffset);
      const cacheKey = `club_data_week_${isoWeekKey(weekStart)}`;
      const forceRefresh = url.searchParams.get("force") === "1";
      if (!forceRefresh) {
        const cached = await env.STRAVA_KV.get(cacheKey);
        if (cached) {
          return new Response(cached, {
            headers: {
              "Content-Type": "application/json",
              "Access-Control-Allow-Origin": "*",
              "X-Cache": "HIT"
            }
          });
        }
      }
      try {
        if (forceRefresh) await syncBatch(env, weekOffset);
        return jsonResponse(await buildWeekPayload(env, weekOffset));
      } catch (err) {
        return errorResponse(`Failed to build club data: ${err.message}`, 502);
      }
    }
    if (url.pathname === "/features") {
      try {
        const featuresData = await getFeatureData(env);
        const html = buildFeatureDashboardHTML(featuresData);
        return new Response(html, {
          headers: {
            "Content-Type": "text/html; charset=utf-8",
            "Access-Control-Allow-Origin": "*",
            "Cache-Control": "public, max-age=1800"
          }
        });
      } catch (err) {
        console.error("Features page error:", err.message);
        return errorResponse(`Failed to load features: ${err.message}`, 502);
      }
    }
    if (url.pathname === "/features-api") {
      try {
        const featuresData = await getFeatureData(env);
        return jsonResponse(featuresData);
      } catch (err) {
        console.error("Features API error:", err.message);
        return errorResponse(`Failed to load features: ${err.message}`, 502);
      }
    }
    return errorResponse("Not found", 404);
  }
};
const FEATURES_CACHE_KEY = "features_dashboard_cache";
const FEATURES_CACHE_TTL = 3600;
const STATUS_MAP = {
  // Live / Done
  "done": "live",
  "closed": "live",
  "released": "live",
  "resolved": "live",
  "live": "live",
  "deployed": "live",
  // In Progress → planned
  "in progress": "planned",
  "in review": "planned",
  "in development": "planned",
  "to do": "planned",
  "open": "planned",
  "backlog": "planned",
  "selected for development": "planned",
  "ready for dev": "planned",
  // Discarded
  "won't do": "discarded",
  "rejected": "discarded",
  "discarded": "discarded",
  "cancelled": "discarded",
  "shelved": "discarded",
  "won't fix": "discarded",
  "duplicate": "discarded"
};
function mapJiraStatus(jiraStatus) {
  const key = (jiraStatus || "").toLowerCase().trim();
  return STATUS_MAP[key] || "planned";
}
const LABEL_CATEGORY_MAP = {
  "auth": { category: "Authentication", icon: "&#x1F512;", iconBg: "#FFE0B2" },
  "login": { category: "Authentication", icon: "&#x1F512;", iconBg: "#FFE0B2" },
  "ride": { category: "Ride (Main Tab)", icon: "&#x1F6B4;", iconBg: "#C8E6C9" },
  "main-tab": { category: "Ride (Main Tab)", icon: "&#x1F6B4;", iconBg: "#C8E6C9" },
  "overview": { category: "Overview (Tab 2)", icon: "&#x1F4CA;", iconBg: "#BBDEFB" },
  "leaderboard": { category: "Leaderboard (Tab 3)", icon: "&#x1F3C6;", iconBg: "#FFF9C4" },
  "insights": { category: "Insights (Tab 4)", icon: "&#x1F4A1;", iconBg: "#E1BEE7" },
  "analysis": { category: "Analysis (Tab 5)", icon: "&#x1F9EA;", iconBg: "#B2DFDB" },
  "feature-request": { category: "Feature Request System", icon: "&#x1F4AC;", iconBg: "#FFE0B2" },
  "user-feature-request": { category: "Feature Request System", icon: "&#x1F4AC;", iconBg: "#FFE0B2" },
  "data-pipeline": { category: "Data Pipeline", icon: "&#x2601;&#xFE0F;", iconBg: "#B3E5FC" },
  "worker": { category: "Data Pipeline", icon: "&#x2601;&#xFE0F;", iconBg: "#B3E5FC" },
  "cloudflare": { category: "Data Pipeline", icon: "&#x2601;&#xFE0F;", iconBg: "#B3E5FC" },
  "admin": { category: "Admin & Coach Tools", icon: "&#x1F6E0;&#xFE0F;", iconBg: "#FFCCBC" },
  "coach": { category: "Admin & Coach Tools", icon: "&#x1F6E0;&#xFE0F;", iconBg: "#FFCCBC" },
  "ipad": { category: "iPad & Adaptive Layout", icon: "&#x1F4F1;", iconBg: "#D1C4E9" },
  "layout": { category: "iPad & Adaptive Layout", icon: "&#x1F4F1;", iconBg: "#D1C4E9" },
  "design": { category: "Design System", icon: "&#x1F3A8;", iconBg: "#F8BBD0" },
  "ui": { category: "Design System", icon: "&#x1F3A8;", iconBg: "#F8BBD0" },
  "tvos": { category: "Apple TV", icon: "&#x1F4FA;", iconBg: "#E0E0E0" },
  "apple-tv": { category: "Apple TV", icon: "&#x1F4FA;", iconBg: "#E0E0E0" },
  "watchos": { category: "Apple Watch", icon: "&#x231A;", iconBg: "#B2EBF2" }
};
const DEFAULT_CATEGORY = { category: "General", icon: "&#x2699;&#xFE0F;", iconBg: "#E0E0E0" };
const FEATURE_REQUEST_KEYWORD_LABELS = {
  bug: ["bug", "broken", "crash", "freeze", "frozen", "wrong", "incorrect", "doesn't work", "not working"],
  performance: ["slow", "lag", "stall", "stuck", "timeout", "hang"],
  ui: ["ui", "layout", "design", "icon", "colour", "color", "screen", "button", "chart", "graph", "radar", "scatter", "bar"],
  notifications: ["notification", "push", "alert", "reminder"],
  android: ["android", "pwa", "web", "browser"],
  ipad: ["ipad", "tablet", "sidebar"],
  gpx: ["gpx", "route", "map"],
  weather: ["weather", "rain", "forecast"],
  auth: ["login", "biometric", "face id", "auth", "password", "club code"],
  "data-pipeline": ["strava", "worker", "sync", "backend", "data pipeline", "speed", "distance", "elevation", "stats"]
};
function inferKeywordLabels(text) {
  const lower = text.toLowerCase();
  const matched = new Set();
  for (const [label, keywords] of Object.entries(FEATURE_REQUEST_KEYWORD_LABELS)) {
    if (keywords.some((kw) => lower.includes(kw))) matched.add(label);
  }
  return [...matched];
}
function categoriseIssue(labels) {
  for (const label of labels) {
    const key = label.toLowerCase().trim();
    if (LABEL_CATEGORY_MAP[key]) return LABEL_CATEGORY_MAP[key];
  }
  return DEFAULT_CATEGORY;
}
async function fetchJiraIssues(env) {
  const jiraEmail = env.JIRA_EMAIL || "amit.r.kamat@googlemail.com";
  const jiraToken = env.JIRA_API_TOKEN;
  if (!jiraToken) throw new Error("JIRA_API_TOKEN not configured");
  const authHeader = "Basic " + btoa(`${jiraEmail}:${jiraToken}`);
  const issues = [];
  let nextPageToken;
  const maxResults = 100;
  while (true) {
    const jql = encodeURIComponent("project = SCRUM ORDER BY created DESC");
    const fields = "summary,status,labels,priority,issuetype,created,updated,resolution,description";
    const pageParam = nextPageToken ? `&nextPageToken=${encodeURIComponent(nextPageToken)}` : "";
    const apiUrl = `https://amitrkamat.atlassian.net/rest/api/3/search/jql?jql=${jql}&maxResults=${maxResults}&fields=${fields}${pageParam}`;
    const res = await fetch(apiUrl, {
      headers: {
        "Content-Type": "application/json",
        "Authorization": authHeader
      }
    });
    if (!res.ok) {
      const errText = await res.text();
      throw new Error(`Jira API error (${res.status}): ${errText}`);
    }
    const data = await res.json();
    issues.push(...data.issues || []);
    if (data.isLast || !data.nextPageToken) break;
    nextPageToken = data.nextPageToken;
  }
  return issues;
}
function extractTextFromADF(node) {
  if (!node) return "";
  if (node.type === "text") return node.text || "";
  if (Array.isArray(node.content)) {
    return node.content.map(extractTextFromADF).join(" ");
  }
  return "";
}
async function getFeatureData(env) {
  const cached = await env.STRAVA_KV.get(FEATURES_CACHE_KEY);
  if (cached) {
    try {
      return JSON.parse(cached);
    } catch {
    }
  }
  const jiraIssues = await fetchJiraIssues(env);
  const jiraFeatures = jiraIssues.map((issue) => {
    const f = issue.fields;
    const status = mapJiraStatus(f.status?.name);
    const labels = f.labels || [];
    const cat = categoriseIssue(labels);
    const resolution = f.resolution?.name || null;
    const descText = extractTextFromADF(f.description);
    return {
      name: f.summary || "Untitled",
      desc: descText.substring(0, 300) || `${f.issuetype?.name || "Story"} in ${f.status?.name || "Unknown"} status`,
      status,
      jiraKey: issue.key,
      jiraStatus: f.status?.name || "Unknown",
      labels,
      priority: f.priority?.name || "Medium",
      issueType: f.issuetype?.name || "Story",
      created: f.created,
      updated: f.updated,
      resolution,
      reason: status === "discarded" ? `Resolution: ${resolution || f.status?.name}` : null,
      _category: cat.category,
      _icon: cat.icon,
      _iconBg: cat.iconBg
    };
  });
  const builtInFeatures = getBuiltInFeatures();
  const jiraNames = new Set(jiraFeatures.map((f) => f.name.toLowerCase()));
  const merged = [
    ...jiraFeatures,
    ...builtInFeatures.filter((f) => !jiraNames.has(f.name.toLowerCase()))
  ];
  const categoryMap = new Map();
  for (const feat of merged) {
    const key = feat._category;
    if (!categoryMap.has(key)) {
      categoryMap.set(key, {
        category: key,
        icon: feat._icon,
        iconBg: feat._iconBg,
        features: []
      });
    }
    const { _category, _icon, _iconBg, ...cleanFeat } = feat;
    categoryMap.get(key).features.push(cleanFeat);
  }
  const CATEGORY_ORDER = [
    "Authentication",
    "Ride (Main Tab)",
    "Overview (Tab 2)",
    "Leaderboard (Tab 3)",
    "Insights (Tab 4)",
    "Analysis (Tab 5)",
    "Feature Request System",
    "Data Pipeline",
    "Admin & Coach Tools",
    "iPad & Adaptive Layout",
    "Design System",
    "Apple TV",
    "Apple Watch",
    "General"
  ];
  const categories = Array.from(categoryMap.values()).sort((a, b) => {
    const ai = CATEGORY_ORDER.indexOf(a.category);
    const bi = CATEGORY_ORDER.indexOf(b.category);
    return (ai === -1 ? 99 : ai) - (bi === -1 ? 99 : bi);
  });
  const result = {
    lastUpdated: (new Date()).toISOString(),
    totalFeatures: merged.length,
    liveCount: merged.filter((f) => f.status === "live").length,
    plannedCount: merged.filter((f) => f.status === "planned").length,
    discardedCount: merged.filter((f) => f.status === "discarded").length,
    categories
  };
  await env.STRAVA_KV.put(FEATURES_CACHE_KEY, JSON.stringify(result), {
    expirationTtl: FEATURES_CACHE_TTL
  });
  return result;
}
function getBuiltInFeatures() {
  return [
    { name: "Club Code Login", desc: "Enter club code (DCC2026) and your name to access the app. No Strava OAuth needed.", status: "live", labels: ["auth"], _category: "Authentication", _icon: "&#x1F512;", _iconBg: "#FFE0B2", platform: "iOS / iPad" },
    { name: "Face ID / Touch ID Gate", desc: "Biometric lock on every launch after first login. Protects dashboard access.", status: "live", labels: ["auth"], _category: "Authentication", _icon: "&#x1F512;", _iconBg: "#FFE0B2", platform: "iOS / iPad" },
    { name: "Secure Keychain Storage", desc: "Club code and auth tokens stored in iOS Keychain \u2014 never in plain text.", status: "live", labels: ["auth"], _category: "Authentication", _icon: "&#x1F512;", _iconBg: "#FFE0B2", platform: "iOS / iPad" },
    { name: "Weekly Report Table", desc: "Full stats table: distance, rides, avg speed, elevation, trend arrows, previous week comparison. Scroll horizontally.", status: "live", labels: ["ride"], _category: "Ride (Main Tab)", _icon: "&#x1F6B4;", _iconBg: "#C8E6C9", tab: "Ride", platform: "iOS / iPad" },
    { name: "Animated Club Totals", desc: "Counters showing total club distance, rides, and active riders \u2014 numbers animate on load.", status: "live", labels: ["ride"], _category: "Ride (Main Tab)", _icon: "&#x1F6B4;", _iconBg: "#C8E6C9", tab: "Ride", platform: "iOS / iPad" },
    { name: "Week Picker Navigation", desc: "Navigate between weeks (current + up to 4 weeks back) using left/right arrows.", status: "live", labels: ["ride"], _category: "Ride (Main Tab)", _icon: "&#x1F6B4;", _iconBg: "#C8E6C9", tab: "Ride", platform: "iOS / iPad" },
    { name: "Trend Arrows", desc: "Up/down/flat arrows per rider showing weekly change (>10% threshold).", status: "live", labels: ["ride"], _category: "Ride (Main Tab)", _icon: "&#x1F6B4;", _iconBg: "#C8E6C9", tab: "Ride", platform: "iOS / iPad" },
    { name: "Ride Type Filter Bar", desc: "Filter by ride type: All, Road, MTB, Gravel, E-Bike, Virtual. Uses Strava sport_type.", status: "live", labels: ["ride"], _category: "Ride (Main Tab)", _icon: "&#x1F6B4;", _iconBg: "#C8E6C9", tab: "Ride", platform: "iOS / iPad" },
    { name: "Strava Branding Badge", desc: "'Powered by Strava' badge with official branding per API terms.", status: "live", labels: ["ride"], _category: "Ride (Main Tab)", _icon: "&#x1F6B4;", _iconBg: "#C8E6C9", tab: "Ride", platform: "iOS / iPad" },
    { name: "My Performance Rings", desc: "4 animated rings: distance, speed, elevation, ride count relative to club.", status: "live", labels: ["overview"], _category: "Overview (Tab 2)", _icon: "&#x1F4CA;", _iconBg: "#BBDEFB", tab: "Overview", platform: "iOS / iPad" },
    { name: "Compare With Any Rider", desc: "Side-by-side comparison with any rider from a dropdown selector.", status: "live", labels: ["overview"], _category: "Overview (Tab 2)", _icon: "&#x1F4CA;", _iconBg: "#BBDEFB", tab: "Overview", platform: "iOS / iPad" },
    { name: "Me vs Top 3", desc: "Your stats compared to the top 3 riders in a compact card.", status: "live", labels: ["overview"], _category: "Overview (Tab 2)", _icon: "&#x1F4CA;", _iconBg: "#BBDEFB", tab: "Overview", platform: "iOS / iPad" },
    { name: "Performance Zones", desc: "Best and worst performers across 4 metrics with animated progress bars.", status: "live", labels: ["overview"], _category: "Overview (Tab 2)", _icon: "&#x1F4CA;", _iconBg: "#BBDEFB", tab: "Overview", platform: "iOS / iPad" },
    { name: "Club Overview Cards", desc: "4 summary cards: Total Distance, Total Rides, Active Riders, Avg per Rider.", status: "live", labels: ["leaderboard"], _category: "Leaderboard (Tab 3)", _icon: "&#x1F3C6;", _iconBg: "#FFF9C4", tab: "Leaderboard", platform: "iOS / iPad" },
    { name: "Ranked Rider List", desc: "All riders ranked by total distance with medal badges for top 3.", status: "live", labels: ["leaderboard"], _category: "Leaderboard (Tab 3)", _icon: "&#x1F3C6;", _iconBg: "#FFF9C4", tab: "Leaderboard", platform: "iOS / iPad" },
    { name: "Rider Drill-Down", desc: "Tap any rider for full analysis: charts, coaching tips, celebration card.", status: "live", labels: ["leaderboard"], _category: "Leaderboard (Tab 3)", _icon: "&#x1F3C6;", _iconBg: "#FFF9C4", tab: "Leaderboard", platform: "iOS / iPad" },
    { name: "Rider Chip Selector", desc: "Horizontal scrollable pills to pick which rider to analyse.", status: "live", labels: ["insights"], _category: "Insights (Tab 4)", _icon: "&#x1F4A1;", _iconBg: "#E1BEE7", tab: "Insights", platform: "iOS / iPad" },
    { name: "Celebration Card", desc: "Personalised hero card with rank badge, distance, rides, elevation, motivational message.", status: "live", labels: ["insights"], _category: "Insights (Tab 4)", _icon: "&#x1F4A1;", _iconBg: "#E1BEE7", tab: "Insights", platform: "iOS / iPad" },
    { name: "Confetti Burst Animation", desc: "Animated particle effect triggers when selecting a rider.", status: "live", labels: ["insights"], _category: "Insights (Tab 4)", _icon: "&#x1F4A1;", _iconBg: "#E1BEE7", tab: "Insights", platform: "iOS / iPad" },
    { name: "Distance Bar Chart", desc: "Horizontal bars comparing all riders \u2014 selected rider highlighted in orange.", status: "live", labels: ["analysis"], _category: "Analysis (Tab 5)", _icon: "&#x1F9EA;", _iconBg: "#B2DFDB", tab: "Analysis", platform: "iOS / iPad" },
    { name: "Speed vs Elevation Scatter", desc: "Scatter plot with 4 quadrants: Fast & Climbing, Steady Climber, Fast & Flat, Endurance Base.", status: "live", labels: ["analysis"], _category: "Analysis (Tab 5)", _icon: "&#x1F9EA;", _iconBg: "#B2DFDB", tab: "Analysis", platform: "iOS / iPad" },
    { name: "Radar Chart (5-axis)", desc: "Spider chart: Distance, Speed, Elevation, Rides, Consistency \u2014 vs club average.", status: "live", labels: ["analysis"], _category: "Analysis (Tab 5)", _icon: "&#x1F9EA;", _iconBg: "#B2DFDB", tab: "Analysis", platform: "iOS / iPad" },
    { name: "AI Coaching Tips", desc: "AI-generated tips showing gaps and how to close them, with What-If scenarios.", status: "live", labels: ["analysis"], _category: "Analysis (Tab 5)", _icon: "&#x1F9EA;", _iconBg: "#B2DFDB", tab: "Analysis", platform: "iOS / iPad" },
    { name: "Floating Lightbulb Button", desc: "Orange FAB on every tab to submit feature ideas.", status: "live", labels: ["feature-request"], _category: "Feature Request System", _icon: "&#x1F4AC;", _iconBg: "#FFE0B2", tab: "All tabs", platform: "iOS / iPad" },
    { name: "Voice Dictation Input", desc: "Tap microphone to dictate feature requests using on-device Speech framework.", status: "live", labels: ["feature-request"], _category: "Feature Request System", _icon: "&#x1F4AC;", _iconBg: "#FFE0B2", tab: "All tabs", platform: "iOS / iPad" },
    { name: "Jira Integration (Feature Requests)", desc: "Submissions go to SCRUM Jira backlog via Cloudflare Worker POST /feature-request.", status: "live", labels: ["feature-request"], _category: "Feature Request System", _icon: "&#x1F4AC;", _iconBg: "#FFE0B2", tab: "All tabs", platform: "iOS / iPad" },
    { name: "Offline Feature Request Queue", desc: "Requests submitted offline are queued and auto-sent when connectivity returns.", status: "live", labels: ["feature-request"], _category: "Feature Request System", _icon: "&#x1F4AC;", _iconBg: "#FFE0B2", tab: "All tabs", platform: "iOS / iPad" },
    { name: "Cloudflare Worker /club-data", desc: "Serverless endpoint fetches Strava club activities, aggregates stats, caches in KV.", status: "live", labels: ["data-pipeline"], _category: "Data Pipeline", _icon: "&#x2601;&#xFE0F;", _iconBg: "#B3E5FC", platform: "Backend" },
    { name: "Sport Type Enrichment", desc: "Worker returns sport_type (Ride, MTB, Gravel, E-Bike, Virtual) for client filtering.", status: "live", labels: ["data-pipeline"], _category: "Data Pipeline", _icon: "&#x2601;&#xFE0F;", _iconBg: "#B3E5FC", platform: "Backend" },
    { name: "Weekly Disk Cache", desc: "On-device cache stores last successful week's data. Shown offline or pre-network.", status: "live", labels: ["data-pipeline"], _category: "Data Pipeline", _icon: "&#x2601;&#xFE0F;", _iconBg: "#B3E5FC", platform: "iOS / iPad" },
    { name: "Pull-to-Refresh", desc: "Drag down on dashboard to trigger fresh data fetch from Cloudflare Worker.", status: "live", labels: ["data-pipeline"], _category: "Data Pipeline", _icon: "&#x2601;&#xFE0F;", _iconBg: "#B3E5FC", tab: "All tabs", platform: "iOS / iPad" },
    { name: "Worst Performer Analysis", desc: "Weighted composite score with stats grid, verdict, and coaching suggestions.", status: "live", labels: ["admin"], _category: "Admin & Coach Tools", _icon: "&#x1F6E0;&#xFE0F;", _iconBg: "#FFCCBC", platform: "iOS / iPad" },
    { name: "Worker KV Dashboard", desc: "Admin view to inspect Cloudflare KV store \u2014 token status, cache age, freshness.", status: "live", labels: ["admin"], _category: "Admin & Coach Tools", _icon: "&#x1F6E0;&#xFE0F;", _iconBg: "#FFCCBC", platform: "iOS / iPad" },
    { name: "Sidebar Navigation (iPad)", desc: "On iPad/wide Split View, tabs appear in sidebar-adaptable layout.", status: "live", labels: ["ipad"], _category: "iPad & Adaptive Layout", _icon: "&#x1F4F1;", _iconBg: "#D1C4E9", platform: "iPad" },
    { name: "Two-Column Main Tab (iPad)", desc: "Left 2/3: podium + ranked table. Right 1/3: best ride card + highlights.", status: "live", labels: ["ipad"], _category: "iPad & Adaptive Layout", _icon: "&#x1F4F1;", _iconBg: "#D1C4E9", platform: "iPad" },
    { name: "Live Resize (Stage Manager)", desc: "Layout adapts dynamically in Split View and Stage Manager.", status: "live", labels: ["ipad"], _category: "iPad & Adaptive Layout", _icon: "&#x1F4F1;", _iconBg: "#D1C4E9", platform: "iPad" }
  ];
}
function buildFeatureDashboardHTML(data) {
  const categoriesJSON = JSON.stringify(data.categories).replace(/</g, "\\u003c");
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>DCC Weekly Activities \u2014 Feature Dashboard</title>
<style>
  :root {
    --orange: #FF6B00; --orange-light: #FF8C33;
    --green: #34C759; --green-bg: #E8F8ED;
    --blue: #007AFF; --blue-bg: #E5F0FF;
    --red: #FF3B30; --red-bg: #FFECEB;
    --grey: #8E8E93; --grey-bg: #F2F2F7;
    --dark: #1C1C1E; --card-bg: #FFFFFF; --body-bg: #F5F5F7;
    --shadow: 0 2px 12px rgba(0,0,0,0.08); --radius: 14px;
  }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', Roboto, sans-serif;
    background: var(--body-bg); color: var(--dark); line-height: 1.5;
    -webkit-font-smoothing: antialiased;
  }
  .hero {
    background: linear-gradient(135deg, #1C1C1E 0%, #2C2C2E 50%, #FF6B00 150%);
    color: #fff; padding: 48px 24px 36px; text-align: center;
  }
  .hero h1 { font-size: 2rem; font-weight: 700; letter-spacing: -0.5px; margin-bottom: 6px; }
  .hero .subtitle { font-size: 1rem; opacity: 0.75; margin-bottom: 24px; }
  .hero .version-badge {
    display: inline-block; background: var(--orange); color: #fff;
    font-size: 0.75rem; font-weight: 600; padding: 4px 12px;
    border-radius: 20px; margin-bottom: 8px;
  }
  .hero .live-badge {
    display: inline-block; background: rgba(52,199,89,0.2); color: #34C759;
    font-size: 0.7rem; font-weight: 600; padding: 3px 10px;
    border-radius: 12px; margin-left: 8px;
  }
  .hero .updated { font-size: 0.75rem; opacity: 0.5; margin-bottom: 20px; }
  .stats-strip { display: flex; justify-content: center; gap: 32px; flex-wrap: wrap; }
  .stat-item { text-align: center; }
  .stat-num { font-size: 1.75rem; font-weight: 700; display: block; }
  .stat-num.live { color: var(--green); }
  .stat-num.planned { color: var(--blue); }
  .stat-num.disc { color: var(--red); }
  .stat-label { font-size: 0.75rem; text-transform: uppercase; letter-spacing: 1px; opacity: 0.7; }
  .container { max-width: 960px; margin: 0 auto; padding: 24px 16px 64px; }
  .controls { position: sticky; top: 0; z-index: 100; background: var(--body-bg); padding: 16px 0 12px; }
  .search-wrap { position: relative; margin-bottom: 12px; }
  .search-wrap svg { position: absolute; left: 14px; top: 50%; transform: translateY(-50%); width: 18px; height: 18px; color: var(--grey); }
  .search-input {
    width: 100%; padding: 12px 16px 12px 42px; border: 2px solid #E5E5EA;
    border-radius: 12px; font-size: 1rem; background: #fff; outline: none; transition: border-color 0.2s;
  }
  .search-input:focus { border-color: var(--orange); }
  .search-input::placeholder { color: #C7C7CC; }
  .filter-bar { display: flex; gap: 8px; flex-wrap: wrap; }
  .filter-btn {
    padding: 7px 16px; border-radius: 20px; border: 1.5px solid #D1D1D6;
    background: #fff; font-size: 0.85rem; font-weight: 500; cursor: pointer;
    transition: all 0.2s; white-space: nowrap;
  }
  .filter-btn:hover { border-color: var(--orange); color: var(--orange); }
  .filter-btn.active { background: var(--dark); color: #fff; border-color: var(--dark); }
  .filter-btn .count {
    display: inline-block; background: rgba(0,0,0,0.08); font-size: 0.7rem;
    padding: 1px 6px; border-radius: 8px; margin-left: 4px;
  }
  .filter-btn.active .count { background: rgba(255,255,255,0.2); }
  .category { margin-top: 28px; }
  .category-header {
    display: flex; align-items: center; gap: 10px; margin-bottom: 14px;
    cursor: pointer; user-select: none;
  }
  .category-icon {
    width: 36px; height: 36px; border-radius: 10px; display: flex;
    align-items: center; justify-content: center; font-size: 1.1rem; flex-shrink: 0;
  }
  .category-title { font-size: 1.1rem; font-weight: 700; flex: 1; }
  .category-count { font-size: 0.8rem; color: var(--grey); font-weight: 500; }
  .chevron { width: 20px; height: 20px; color: var(--grey); transition: transform 0.25s; }
  .category.collapsed .chevron { transform: rotate(-90deg); }
  .category.collapsed .feature-list { display: none; }
  .feature-list { display: flex; flex-direction: column; gap: 10px; }
  .feature-card {
    background: var(--card-bg); border-radius: var(--radius); padding: 16px 18px;
    box-shadow: var(--shadow); transition: transform 0.15s, box-shadow 0.15s;
  }
  .feature-card:hover { transform: translateY(-1px); box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
  .feature-card.hidden { display: none; }
  .card-top { display: flex; align-items: flex-start; gap: 12px; margin-bottom: 6px; }
  .feature-name { font-weight: 600; font-size: 0.95rem; flex: 1; }
  .status-badge {
    font-size: 0.7rem; font-weight: 600; padding: 3px 10px; border-radius: 12px;
    white-space: nowrap; text-transform: uppercase; letter-spacing: 0.5px; flex-shrink: 0;
  }
  .status-badge.live { background: var(--green-bg); color: #1B8A38; }
  .status-badge.planned { background: var(--blue-bg); color: #0055CC; }
  .status-badge.discarded { background: var(--red-bg); color: #CC1A11; }
  .feature-desc { font-size: 0.85rem; color: #636366; margin-bottom: 8px; }
  .card-meta { display: flex; gap: 8px; flex-wrap: wrap; }
  .meta-tag {
    font-size: 0.72rem; font-weight: 500; padding: 2px 8px;
    border-radius: 6px; background: var(--grey-bg); color: #636366;
  }
  .meta-tag.scrum { background: #FFF3E0; color: #E65100; }
  .meta-tag.jira { background: #E3F2FD; color: #1565C0; }
  .meta-tag.tab { background: #E8EAF6; color: #283593; }
  .meta-tag.platform { background: #F3E5F5; color: #6A1B9A; }
  .meta-tag.priority-high { background: #FFEBEE; color: #C62828; }
  .meta-tag.priority-highest { background: #FFCDD2; color: #B71C1C; }
  .no-results { text-align: center; padding: 48px 24px; color: var(--grey); }
  .no-results .icon { font-size: 2.5rem; margin-bottom: 12px; }
  .footer { text-align: center; padding: 32px 16px; font-size: 0.8rem; color: var(--grey); }
  .footer a { color: var(--orange); text-decoration: none; }
  @media (max-width: 600px) {
    .hero h1 { font-size: 1.5rem; }
    .stats-strip { gap: 20px; }
    .stat-num { font-size: 1.4rem; }
    .feature-card { padding: 14px; }
  }
</style>
</head>
<body>
<div class="hero">
  <div>
    <span class="version-badge">DCC Weekly Activities</span>
    <span class="live-badge">LIVE from Jira</span>
  </div>
  <h1>Feature Dashboard</h1>
  <p class="subtitle">Search, explore, and track what's live, planned, and shelved</p>
  <p class="updated">Last synced: ${new Date(data.lastUpdated).toLocaleString("en-GB", { dateStyle: "medium", timeStyle: "short" })}</p>
  <div class="stats-strip" id="statsStrip">
    <div class="stat-item"><span class="stat-num live" data-target="${data.liveCount}">0</span><span class="stat-label">Live</span></div>
    <div class="stat-item"><span class="stat-num planned" data-target="${data.plannedCount}">0</span><span class="stat-label">Planned</span></div>
    <div class="stat-item"><span class="stat-num disc" data-target="${data.discardedCount}">0</span><span class="stat-label">Shelved</span></div>
    <div class="stat-item"><span class="stat-num" style="color:#fff" data-target="${data.totalFeatures}">0</span><span class="stat-label">Total</span></div>
  </div>
</div>
<div class="container">
  <div class="controls">
    <div class="search-wrap">
      <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2"><circle cx="8.5" cy="8.5" r="6"/><line x1="13" y1="13" x2="18" y2="18"/></svg>
      <input class="search-input" id="search" type="text" placeholder="Search features, Jira tickets, tabs...">
    </div>
    <div class="filter-bar" id="filterBar"></div>
  </div>
  <div id="featureContainer"></div>
  <div class="no-results" id="noResults" style="display:none;">
    <div class="icon">&#x1F50D;</div><p>No features match your search.</p>
  </div>
</div>
<div class="footer">
  Built for <a href="#">Desi Cycling Club</a> &mdash; data from Jira (SCRUM project) &bull; auto-refreshes hourly
</div>
<script>
const CATEGORIES = ${categoriesJSON};
const container = document.getElementById("featureContainer");
const searchInput = document.getElementById("search");
const filterBar = document.getElementById("filterBar");
const noResults = document.getElementById("noResults");
let activeFilter = "all";

function countByStatus(s) {
  return CATEGORIES.reduce((sum, cat) => sum + cat.features.filter(f => s === "all" || f.status === s).length, 0);
}

[{key:"all",label:"All"},{key:"live",label:"Live"},{key:"planned",label:"Planned"},{key:"discarded",label:"Shelved"}].forEach(f => {
  const btn = document.createElement("button");
  btn.className = "filter-btn" + (f.key === "all" ? " active" : "");
  btn.innerHTML = f.label + '<span class="count">' + countByStatus(f.key) + '</span>';
  btn.addEventListener("click", () => {
    activeFilter = f.key;
    filterBar.querySelectorAll(".filter-btn").forEach(b => b.classList.remove("active"));
    btn.classList.add("active");
    applyFilters();
  });
  filterBar.appendChild(btn);
});

CATEGORIES.forEach((cat, ci) => {
  const section = document.createElement("div");
  section.className = "category";
  const featHTML = cat.features.map((f, fi) => {
    const searchStr = [f.name, f.desc, f.jiraKey, f.jiraStatus, (f.labels||[]).join(" "), f.tab, f.reason, f.platform, f.priority, f.issueType].filter(Boolean).join(" ").toLowerCase();
    const statusLabel = f.status === "live" ? "&#x2705; Live" : f.status === "planned" ? "&#x1F6A7; Planned" : "&#x274C; Shelved";
    const priorityClass = (f.priority||"").toLowerCase() === "high" ? "priority-high" : (f.priority||"").toLowerCase() === "highest" ? "priority-highest" : "";
    return '<div class="feature-card" data-status="' + f.status + '" data-search="' + searchStr.replace(/"/g, '') + '">' +
      '<div class="card-top"><span class="feature-name">' + f.name + '</span><span class="status-badge ' + f.status + '">' + statusLabel + '</span></div>' +
      '<div class="feature-desc">' + (f.desc || '') + '</div>' +
      (f.reason ? '<div class="feature-desc" style="color:#FF3B30;font-style:italic;">Why shelved: ' + f.reason + '</div>' : '') +
      '<div class="card-meta">' +
        (f.jiraKey ? '<span class="meta-tag jira">' + f.jiraKey + '</span>' : '') +
        (f.jiraStatus ? '<span class="meta-tag">' + f.jiraStatus + '</span>' : '') +
        ((f.labels||[]).filter(l => l.startsWith("SCRUM") || l === "user-feature-request").map(l => '<span class="meta-tag scrum">' + l + '</span>').join('')) +
        (f.tab ? '<span class="meta-tag tab">' + f.tab + '</span>' : '') +
        (f.platform ? '<span class="meta-tag platform">' + f.platform + '</span>' : '') +
        (f.priority && priorityClass ? '<span class="meta-tag ' + priorityClass + '">' + f.priority + '</span>' : '') +
      '</div></div>';
  }).join('');

  section.innerHTML = '<div class="category-header">' +
    '<div class="category-icon" style="background:' + cat.iconBg + '">' + cat.icon + '</div>' +
    '<span class="category-title">' + cat.category + '</span>' +
    '<span class="category-count">' + cat.features.length + ' features</span>' +
    '<svg class="chevron" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><polyline points="6,4 12,10 6,16"/></svg>' +
    '</div><div class="feature-list">' + featHTML + '</div>';

  section.querySelector(".category-header").addEventListener("click", () => section.classList.toggle("collapsed"));
  container.appendChild(section);
});

function applyFilters() {
  const q = searchInput.value.toLowerCase().trim();
  let vis = 0;
  document.querySelectorAll(".category").forEach(cat => {
    let cv = 0;
    cat.querySelectorAll(".feature-card").forEach(card => {
      const show = (activeFilter === "all" || card.dataset.status === activeFilter) && (!q || card.dataset.search.includes(q));
      card.classList.toggle("hidden", !show);
      if (show) { cv++; vis++; }
    });
    cat.style.display = cv > 0 ? "" : "none";
    cat.querySelector(".category-count").textContent = cv + " feature" + (cv !== 1 ? "s" : "");
  });
  noResults.style.display = vis === 0 ? "" : "none";
}
searchInput.addEventListener("input", applyFilters);

document.querySelectorAll(".stat-num[data-target]").forEach(el => {
  const target = parseInt(el.dataset.target);
  let cur = 0; const step = Math.max(1, Math.ceil(target / 30));
  const iv = setInterval(() => { cur = Math.min(cur + step, target); el.textContent = cur; if (cur >= target) clearInterval(iv); }, 30);
});
<\/script>
</body>
</html>`;
}
