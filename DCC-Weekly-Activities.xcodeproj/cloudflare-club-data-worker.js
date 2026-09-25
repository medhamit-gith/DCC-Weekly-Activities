/**
 * DCC Weekly Activities — Club Data Worker
 *
 * Deployed as the Cloudflare Worker `dcc-strava`
 * (https://dcc-strava.amit-r-kamat.workers.dev).
 *
 * This file was re-synced from the deployed script, which had drifted far ahead
 * of the repository: the committed copy exposed only /club-data and still
 * carried the broken date filter. Deploying that copy would have silently
 * reverted six endpoints and the first-seen registry. Treat this file as the
 * source of truth and deploy from it.
 *
 * ── How activities are dated (important) ─────────────────────────────────────
 *   Strava's GET /clubs/{id}/activities returns NO start_date and NO activity
 *   id. Week filtering therefore cannot use the ride's real start time.
 *
 *   Instead the hourly cron records the first time each activity is observed,
 *   keyed by a fingerprint of its immutable fields, in the KV key
 *   `activity_registry`. That first-seen timestamp becomes the activity's
 *   effective date. Consequences the UI should respect:
 *     • A ride uploaded late is counted in the week it was first SEEN.
 *     • History only reaches back as far as REGISTRY_RETENTION_DAYS.
 *     • The payload's `dateSource` field reports "observed" whenever dates come
 *       from the registry rather than from Strava.
 *
 * ── Environment variables (Settings → Variables) ─────────────────────────────
 *   STRAVA_CLIENT_ID      = 161984
 *   STRAVA_CLIENT_SECRET  = <Strava client secret>
 *   STRAVA_CLUB_ID        = 212760
 *   BOT_REFRESH_TOKEN     = <club-admin refresh token, bootstrap fallback>
 *
 * ── KV binding ───────────────────────────────────────────────────────────────
 *   STRAVA_KV → the namespace titled "DCC_DATA"
 *     (the binding name and the namespace title differ; this is expected)
 *   Keys: strava_refresh_token, strava_access_token,
 *         strava_access_token_expires, activity_registry,
 *         club_data_week_{YYYY-MM-DD}, features_dashboard_cache
 *
 * ── Endpoints ────────────────────────────────────────────────────────────────
 *   GET  /club-data[?weekOffset=N][&force=1]   per-member weekly aggregates
 *   GET  /diagnostics                          token/club/registry health
 *   GET  /features, /features-api, /release-notes
 *   POST /feature-request, /github-webhook
 *
 * ── Cron ─────────────────────────────────────────────────────────────────────
 *   "0 * * * *" — hourly. This is what populates the first-seen registry, so
 *   the cron is load-bearing, not merely a cache warmer.
 */

const STRAVA_TOKEN_URL = "https://www.strava.com/api/v3/oauth/token";
const STRAVA_CLUB_URL = "https://www.strava.com/api/v3/clubs";
const CACHE_TTL_SECONDS = 3600;
// Strava's club-activities endpoint is unbounded; cap paging so a busy club
// cannot exhaust the Worker's subrequest budget in a single invocation.
const MAX_ACTIVITY_PAGES = 5;
// Single source of truth for how far back the first-seen registry reaches.
// Both the prune cutoff and the KV TTL derive from this, and /club-data
// refuses week offsets older than it can honestly answer.
const REGISTRY_RETENTION_DAYS = 90;
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
async function getAccessToken(env) {
  const nowSec = Math.floor(Date.now() / 1e3);
  const expiresStr = await env.STRAVA_KV.get("strava_access_token_expires");
  const expires = expiresStr ? parseInt(expiresStr, 10) : 0;
  if (expires - nowSec > 300) {
    const cached = await env.STRAVA_KV.get("strava_access_token");
    if (cached) return cached;
  }
  let refreshToken = await env.STRAVA_KV.get("strava_refresh_token");
  if (!refreshToken && env.BOT_REFRESH_TOKEN) {
    refreshToken = env.BOT_REFRESH_TOKEN;
    await env.STRAVA_KV.put("strava_refresh_token", refreshToken);
  }
  if (!refreshToken) {
    throw new Error("No Strava refresh token in KV or env. Bootstrap required.");
  }
  const params = new URLSearchParams({
    client_id: env.STRAVA_CLIENT_ID,
    client_secret: env.STRAVA_CLIENT_SECRET,
    refresh_token: refreshToken,
    grant_type: "refresh_token"
  });
  const res = await fetch(STRAVA_TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: params.toString()
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Token refresh failed (${res.status}): ${err}`);
  }
  const data = await res.json();
  await env.STRAVA_KV.put("strava_access_token", data.access_token);
  await env.STRAVA_KV.put("strava_access_token_expires", String(data.expires_at));
  await env.STRAVA_KV.put("strava_refresh_token", data.refresh_token);
  return data.access_token;
}
function activityFingerprint(act) {
  // NB: act.name is deliberately excluded. Riders routinely rename an activity
  // after upload ("Morning Ride" -> "Chill in the wind!"). Including the title
  // made a rename mint a fresh fingerprint, so the activity was stamped with a
  // new first-seen date and re-entered the current week - counting it twice.
  // Every field below is fixed at upload time.
  const athlete = `${act.athlete?.firstname || ""}${act.athlete?.lastname || ""}`;
  const sport = act.sport_type ?? act.type ?? "";
  const distance = Math.round(act.distance || 0);
  const movingTime = act.moving_time || 0;
  const elevation = Math.round(act.total_elevation_gain || 0);
  return `v2:${athlete}_${sport}_${distance}_${movingTime}_${elevation}`;
}

// ── Migration off the v1 fingerprint ────────────────────────────────────────
// v1 keys were `${athlete}_${title}_${distance}_${movingTime}`. Changing the
// format orphans every existing entry, so without this every activity Strava
// returns would look new on the first run after deploy, be stamped with the
// deploy time, and pile into whatever week that happened to be.
//
// A v1 title could itself contain underscores, so those keys are read from the
// ends: first field is the athlete, last two are distance and moving time.
// Those three re-identify an activity well enough to inherit its date.
function legacyLookupKey(act) {
  const athlete = `${act.athlete?.firstname || ""}${act.athlete?.lastname || ""}`;
  return `${athlete}_${act.distance || 0}_${act.moving_time || 0}`;
}

function buildLegacyIndex(registry) {
  const index = new Map();
  for (const [key, seenAt] of Object.entries(registry)) {
    if (key.startsWith("v2:")) continue;
    const parts = key.split("_");
    if (parts.length < 4) continue;
    const lookup = `${parts[0]}_${parts[parts.length - 2]}_${parts[parts.length - 1]}`;
    const existing = index.get(lookup);
    // A rename left several v1 entries for one ride; the earliest is the true
    // first sighting, so that is the one worth carrying forward.
    if (!existing || seenAt < existing) index.set(lookup, seenAt);
  }
  return index;
}
async function fetchClubActivities(clubID, accessToken, weekStart, env) {
  const activities = [];
  let page = 1;
  const perPage = 200;
  const allRaw = [];
  while (true) {
    const url = `${STRAVA_CLUB_URL}/${clubID}/activities?per_page=${perPage}&page=${page}`;
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${accessToken}` }
    });
    if (!res.ok) {
      const err = await res.text();
      throw new Error(`Strava club activities fetch failed (${res.status}): ${err}`);
    }
    const batch = await res.json();
    if (!Array.isArray(batch) || batch.length === 0) break;
    allRaw.push(...batch);
    if (batch.length < perPage) break;
    if (page >= MAX_ACTIVITY_PAGES) {
      console.warn(
        `Reached MAX_ACTIVITY_PAGES (${MAX_ACTIVITY_PAGES}); club activity list truncated.`
      );
      break;
    }
    page++;
  }
  const registryKey = "activity_registry";
  let registry = {};
  try {
    const raw = await env.STRAVA_KV.get(registryKey);
    if (raw) registry = JSON.parse(raw);
  } catch (e) {
    console.error("Failed to load activity registry:", e.message);
  }
  const now = (new Date()).toISOString();
  const legacyIndex = buildLegacyIndex(registry);
  let registryChanged = false;
  let migrated = 0;
  for (const act of allRaw) {
    const fp = activityFingerprint(act);
    if (!registry[fp]) {
      const inherited = legacyIndex.get(legacyLookupKey(act));
      if (inherited) migrated++;
      registry[fp] = inherited || now;
      registryChanged = true;
    }
    const firstSeen = registry[fp];
    act._effectiveDate = firstSeen;
    const seenDate = new Date(firstSeen);
    if (seenDate >= weekStart) {
      activities.push(act);
    }
  }
  if (registryChanged) {
    try {
      const cutoff = new Date(Date.now() - REGISTRY_RETENTION_DAYS * 86400 * 1e3).toISOString();
      const pruned = {};
      for (const [k, v] of Object.entries(registry)) {
        if (v >= cutoff) pruned[k] = v;
      }
      await env.STRAVA_KV.put(registryKey, JSON.stringify(pruned), {
        expirationTtl: REGISTRY_RETENTION_DAYS * 86400
      });
      console.log(
        `Activity registry updated: ${Object.keys(pruned).length} entries` +
        (migrated > 0 ? ` (${migrated} dates inherited from v1 fingerprints)` : "")
      );
    } catch (e) {
      console.error("Failed to save activity registry:", e.message);
    }
  }
  return activities;
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
function aggregateActivities(rawActivities, weekStart, weekEnd, fetchedAt) {
  // Strava's club-activities endpoint omits start_date entirely, so dates here
  // are first-seen observations recorded by the hourly cron, not ride times.
  let datedFromStrava = 0;
  let datedFromRegistry = 0;
  const memberMap = new Map();
  for (const act of rawActivities) {
    const actDate = new Date(act._effectiveDate || act.start_date);
    if (isNaN(actDate.getTime())) continue;
    if (act.start_date) datedFromStrava++;
    else datedFromRegistry++;
    if (actDate < weekStart || actDate > weekEnd) continue;
    if (!CYCLING_SPORT_TYPES.has(act.sport_type ?? act.type)) continue;
    const name = `${act.athlete.firstname} ${act.athlete.lastname.charAt(0)}.`;
    if (!memberMap.has(name)) {
      memberMap.set(name, {
        name,
        totalDistance: 0,
        totalElevation: 0,
        totalMovingTime: 0,
        rideCount: 0,
        activities: [],
        // For weighted avg speed calc
        _weightedSpeedSum: 0
      });
    }
    const member = memberMap.get(name);
    const distKm = act.distance / 1e3;
    const movingSec = act.moving_time ?? 0;
    const speedKmh = movingSec > 0 ? act.distance / movingSec * 3.6 : 0;
    member.totalDistance += distKm;
    member.totalElevation += Math.round(act.total_elevation_gain ?? 0);
    member.totalMovingTime += act.moving_time ?? 0;
    member.rideCount += 1;
    member._weightedSpeedSum += speedKmh * distKm;
    member.activities.push({
      name: act.name,
      distance: Math.round(distKm * 10) / 10,
      movingTime: act.moving_time ?? 0,
      elevationGain: Math.round(act.total_elevation_gain ?? 0),
      averageSpeed: Math.round(speedKmh * 10) / 10,
      type: act.type,
      sportType: act.sport_type ?? act.type,
      // prefer sport_type (Ride, MountainBikeRide, GravelRide, EBikeRide, VirtualRide)
      startDate: act._effectiveDate || act.start_date || null
      // first-seen timestamp from KV
    });
  }
  const members = Array.from(memberMap.values()).map((m) => {
    const avgSpeed = m.totalDistance > 0 ? Math.round(m._weightedSpeedSum / m.totalDistance * 10) / 10 : 0;
    const { _weightedSpeedSum, ...rest } = m;
    return {
      ...rest,
      totalDistance: Math.round(m.totalDistance * 10) / 10,
      avgSpeed,
      movingTimeFormatted: formatMovingTime(m.totalMovingTime)
    };
  }).sort((a, b) => b.totalDistance - a.totalDistance);
  const totalActivities = members.reduce((s, m) => s + m.rideCount, 0);
  return {
    lastFetchedAt: fetchedAt,
    weekLabel: weekLabel(weekStart),
    weekStart: weekStart.toISOString().slice(0, 10),
    weekEnd: weekEnd.toISOString().slice(0, 10),
    memberCount: members.length,
    totalActivities,
    // "observed" means every activity was dated by first sighting rather than
    // by its real start time, so a ride uploaded late lands in the week it was
    // first seen. Clients should caption week totals accordingly.
    dateSource: datedFromStrava > 0 ? (datedFromRegistry > 0 ? "mixed" : "strava") : "observed",
    registryRetentionDays: REGISTRY_RETENTION_DAYS,
    members
  };
}
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

async function fetchAndCacheWeek(env, weekOffset) {
  const { start: weekStart, end: weekEnd } = getWeekRange(weekOffset);
  const cacheKey = `club_data_week_${isoWeekKey(weekStart)}`;
  const accessToken = await getAccessToken(env);
  const clubID = env.STRAVA_CLUB_ID ?? "212760";
  const rawActivities = await fetchClubActivities(clubID, accessToken, weekStart, env);
  const payload = aggregateActivities(
    rawActivities,
    weekStart,
    weekEnd,
    (new Date()).toISOString()
  );
  await env.STRAVA_KV.put(cacheKey, JSON.stringify(payload), {
    expirationTtl: CACHE_TTL_SECONDS
  });
  return payload;
}
export default {
  // ── Cron trigger: refresh current week every hour ──────────────────────────
  async scheduled(event, env, ctx) {
    ctx.waitUntil(fetchAndCacheWeek(env, 0));
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
      const { value: refreshToken, error } = await readJsonField(request, "refresh_token");
      if (error) return error;
      return stravaTokenGrant(env, {
        refresh_token: refreshToken,
        grant_type: "refresh_token"
      });
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
        const accessToken = await getAccessToken(env);
        const clubID = env.STRAVA_CLUB_ID ?? "212760";
        const meRes = await fetch("https://www.strava.com/api/v3/athlete", {
          headers: { Authorization: `Bearer ${accessToken}` }
        });
        const meBody = meRes.ok ? await meRes.json() : await meRes.text();
        const clubRes = await fetch(`https://www.strava.com/api/v3/clubs/${clubID}`, {
          headers: { Authorization: `Bearer ${accessToken}` }
        });
        const clubBody = clubRes.ok ? await clubRes.json() : await clubRes.text();
        const actUrl = `https://www.strava.com/api/v3/clubs/${clubID}/activities?per_page=5&page=1`;
        const actRes = await fetch(actUrl, {
          headers: { Authorization: `Bearer ${accessToken}` }
        });
        const actBody = actRes.ok ? await actRes.json() : await actRes.text();
        const regRaw = await env.STRAVA_KV.get("activity_registry");
        const regSize = regRaw ? Object.keys(JSON.parse(regRaw)).length : 0;
        return jsonResponse({
          tokenValid: meRes.ok,
          tokenStatus: meRes.status,
          athlete: meRes.ok ? { id: meBody.id, firstname: meBody.firstname, lastname: meBody.lastname } : meBody,
          clubStatus: clubRes.status,
          club: clubRes.ok ? { id: clubBody.id, name: clubBody.name, member_count: clubBody.member_count } : clubBody,
          activitiesStatus: actRes.status,
          activitiesSample: actBody,
          registryEntries: regSize
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
      const maxWeeksBack = Math.floor(REGISTRY_RETENTION_DAYS / 7);
      if (isNaN(weekOffset) || weekOffset > 0) {
        return errorResponse("Invalid weekOffset. Must be 0 (current) or negative (past weeks).");
      }
      if (weekOffset < -maxWeeksBack) {
        return errorResponse(
          `weekOffset ${weekOffset} predates the activity registry, which retains ` +
          `${REGISTRY_RETENTION_DAYS} days (max ${-maxWeeksBack}). Older weeks cannot be dated reliably.`,
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
        const payload = await fetchAndCacheWeek(env, weekOffset);
        return jsonResponse(payload);
      } catch (err) {
        return errorResponse(`Failed to fetch club data: ${err.message}`, 502);
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
