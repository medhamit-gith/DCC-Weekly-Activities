/**
 * DCC Weekly Activities — Club Data Worker
 *
 * Fetches DCC club activities from the Strava API, filters to the requested
 * week, aggregates per-member stats, and caches the result in KV.
 *
 * This worker is separate from the token-exchange worker (cloudflare-workerworker.js).
 * It is the source of truth for the /club-data endpoint.
 *
 * ── Required Environment Variables (Settings → Variables) ────────────────────
 *   STRAVA_CLIENT_ID     = 161984
 *   STRAVA_CLIENT_SECRET = <your Strava client secret>
 *   STRAVA_CLUB_ID       = 212760
 *
 * ── Required KV Namespace binding ────────────────────────────────────────────
 *   STRAVA_KV  →  bind a KV namespace called "STRAVA_KV"
 *   Keys used:
 *     strava_refresh_token          – the club-admin refresh token
 *     strava_access_token           – cached access token string
 *     strava_access_token_expires   – expiry unix timestamp (string)
 *     club_data_week_{YYYY-Www}     – cached JSON for that ISO week
 *
 * ── How to bootstrap the refresh token ───────────────────────────────────────
 *   1. Authenticate once as the club admin via the normal Strava OAuth flow.
 *   2. In the Cloudflare dashboard → KV namespace → add key:
 *        strava_refresh_token  =  <refresh_token from the auth response>
 *
 * ── Cron trigger (optional but recommended) ──────────────────────────────────
 *   Add a Cron Trigger of "0 * * * *" (every hour) so the current-week data
 *   is always warm in KV and the app gets fast cached responses.
 *
 * ── Endpoints ────────────────────────────────────────────────────────────────
 *   GET /club-data              → current week (weekOffset = 0)
 *   GET /club-data?weekOffset=N → week offset (0 = current, -1 = last, etc.)
 *
 * ── Response shape ───────────────────────────────────────────────────────────
 *   {
 *     lastFetchedAt: "2026-03-21T20:00:00.000Z",
 *     weekLabel:     "w/c 16 Mar",          // human-readable week label
 *     weekStart:     "2026-03-16",           // Monday ISO date
 *     weekEnd:       "2026-03-22",           // Sunday ISO date
 *     memberCount:   12,
 *     totalActivities: 7,
 *     members: [
 *       {
 *         name: "Amit K.",
 *         rideCount: 3,
 *         totalDistance: 112.4,             // km
 *         totalElevation: 450,             // m
 *         totalMovingTime: 14400,           // seconds
 *         avgSpeed: 22.5,                  // km/h (weighted average)
 *         movingTimeFormatted: "4h 0m",
 *         activities: [
 *           {
 *             name: "Morning Ride",
 *             distance: 38.2,
 *             movingTime: 5400,
 *             elevationGain: 150,
 *             averageSpeed: 25.4,
 *             type: "Ride",
 *             startDate: "2026-03-18T07:30:00Z"  // ← NOW INCLUDED
 *           }
 *         ]
 *       }
 *     ]
 *   }
 */

const STRAVA_TOKEN_URL    = "https://www.strava.com/api/v3/oauth/token";
const STRAVA_CLUB_URL     = "https://www.strava.com/api/v3/clubs";
const CACHE_TTL_SECONDS   = 3600; // 1 hour — refresh via cron anyway

// ── Date helpers ──────────────────────────────────────────────────────────────

/**
 * Returns { start: Date, end: Date } for an ISO week relative to now.
 * weekOffset=0  → current week (Mon 00:00 UTC → Sun 23:59:59 UTC)
 * weekOffset=-1 → previous week, etc.
 */
function getWeekRange(weekOffset = 0) {
  const now = new Date();
  // day-of-week: 0=Sun … 6=Sat → convert to Mon-based (0=Mon … 6=Sun)
  const dayOfWeek = (now.getUTCDay() + 6) % 7; // Mon=0 … Sun=6
  const monday = new Date(now);
  monday.setUTCDate(now.getUTCDate() - dayOfWeek + weekOffset * 7);
  monday.setUTCHours(0, 0, 0, 0);
  const sunday = new Date(monday);
  sunday.setUTCDate(monday.getUTCDate() + 6);
  sunday.setUTCHours(23, 59, 59, 999);
  return { start: monday, end: sunday };
}

/** ISO week key, e.g. "2026-W12" */
function isoWeekKey(date) {
  // Simple approach: use Monday's date as the key
  const d = new Date(date);
  const year  = d.getUTCFullYear();
  const month = String(d.getUTCMonth() + 1).padStart(2, "0");
  const day   = String(d.getUTCDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

/** Human label like "w/c 16 Mar" */
function weekLabel(monday) {
  const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
  return `w/c ${monday.getUTCDate()} ${months[monday.getUTCMonth()]}`;
}

/** Format seconds as "4h 30m" or "45m" */
function formatMovingTime(seconds) {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  return h > 0 ? `${h}h ${m}m` : `${m}m`;
}

// ── KV token management ───────────────────────────────────────────────────────

/**
 * Returns a valid Strava access token, refreshing via KV-stored refresh token
 * if the cached one has expired.
 */
async function getAccessToken(env) {
  const nowSec = Math.floor(Date.now() / 1000);
  const expiresStr = await env.STRAVA_KV.get("strava_access_token_expires");
  const expires    = expiresStr ? parseInt(expiresStr, 10) : 0;

  // Use cached token if it has >5 min left
  if (expires - nowSec > 300) {
    const cached = await env.STRAVA_KV.get("strava_access_token");
    if (cached) return cached;
  }

  // Refresh
  const refreshToken = await env.STRAVA_KV.get("strava_refresh_token");
  if (!refreshToken) {
    throw new Error("No Strava refresh token in KV. Bootstrap required.");
  }

  const params = new URLSearchParams({
    client_id:     env.STRAVA_CLIENT_ID,
    client_secret: env.STRAVA_CLIENT_SECRET,
    refresh_token: refreshToken,
    grant_type:    "refresh_token",
  });

  const res  = await fetch(STRAVA_TOKEN_URL, {
    method:  "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body:    params.toString(),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Token refresh failed (${res.status}): ${err}`);
  }

  const data = await res.json();
  // Store the new tokens
  await env.STRAVA_KV.put("strava_access_token",         data.access_token);
  await env.STRAVA_KV.put("strava_access_token_expires", String(data.expires_at));
  // Strava rotates refresh tokens on each refresh
  await env.STRAVA_KV.put("strava_refresh_token",        data.refresh_token);

  return data.access_token;
}

// ── Strava fetch helpers ──────────────────────────────────────────────────────

/**
 * Fetches all club activities from the Strava API, paging through all results
 * (up to perPage=200 per request) until no more activities come back or until
 * the oldest activity is before weekStart.
 *
 * Strava returns activities in reverse chronological order (newest first).
 * Each activity object includes: `athlete.firstname`, `athlete.lastname`,
 * `name`, `distance`, `moving_time`, `total_elevation_gain`,
 * `average_speed`, `type`, `start_date`.
 */
async function fetchClubActivities(clubID, accessToken, weekStart) {
  const activities = [];
  let page = 1;
  const perPage = 200;

  while (true) {
    const url = `${STRAVA_CLUB_URL}/${clubID}/activities?per_page=${perPage}&page=${page}`;
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!res.ok) {
      const err = await res.text();
      throw new Error(`Strava club activities fetch failed (${res.status}): ${err}`);
    }

    const batch = await res.json();
    if (!Array.isArray(batch) || batch.length === 0) break;

    for (const act of batch) {
      const actDate = new Date(act.start_date);
      // Stop fetching once we've gone before the start of the target week
      if (actDate < weekStart) {
        return activities;
      }
      activities.push(act);
    }

    if (batch.length < perPage) break; // last page
    page++;
  }

  return activities;
}

// ── Aggregation ───────────────────────────────────────────────────────────────

/**
 * Groups raw Strava activities by athlete name, computes per-member stats,
 * and builds the response payload.
 */
function aggregateActivities(rawActivities, weekStart, weekEnd, fetchedAt) {
  const memberMap = new Map(); // name → { stats + activities[] }

  for (const act of rawActivities) {
    const actDate = new Date(act.start_date);
    // Only include activities within the week window
    if (actDate < weekStart || actDate > weekEnd) continue;

    const name = `${act.athlete.firstname} ${act.athlete.lastname.charAt(0)}.`;

    if (!memberMap.has(name)) {
      memberMap.set(name, {
        name,
        totalDistance:   0,
        totalElevation:  0,
        totalMovingTime: 0,
        rideCount:       0,
        activities:      [],
        // For weighted avg speed calc
        _weightedSpeedSum: 0,
      });
    }

    const member = memberMap.get(name);
    const distKm = act.distance / 1000;
    const speedKmh = (act.average_speed ?? 0) * 3.6; // m/s → km/h

    member.totalDistance   += distKm;
    member.totalElevation  += Math.round(act.total_elevation_gain ?? 0);
    member.totalMovingTime += act.moving_time ?? 0;
    member.rideCount       += 1;
    member._weightedSpeedSum += speedKmh * distKm;

    member.activities.push({
      name:          act.name,
      distance:      Math.round(distKm * 10) / 10,
      movingTime:    act.moving_time ?? 0,
      elevationGain: Math.round(act.total_elevation_gain ?? 0),
      averageSpeed:  Math.round(speedKmh * 10) / 10,
      type:          act.type,
      startDate:     act.start_date,  // ← ISO8601 string, e.g. "2026-03-18T07:30:00Z"
    });
  }

  // Sort members by totalDistance desc, compute formatted fields
  const members = Array.from(memberMap.values())
    .map(m => {
      const avgSpeed = m.totalDistance > 0
        ? Math.round((m._weightedSpeedSum / m.totalDistance) * 10) / 10
        : 0;
      const { _weightedSpeedSum, ...rest } = m;
      return {
        ...rest,
        totalDistance:   Math.round(m.totalDistance * 10) / 10,
        avgSpeed,
        movingTimeFormatted: formatMovingTime(m.totalMovingTime),
      };
    })
    .sort((a, b) => b.totalDistance - a.totalDistance);

  const totalActivities = members.reduce((s, m) => s + m.rideCount, 0);

  return {
    lastFetchedAt:   fetchedAt,
    weekLabel:       weekLabel(weekStart),
    weekStart:       weekStart.toISOString().slice(0, 10),
    weekEnd:         weekEnd.toISOString().slice(0, 10),
    memberCount:     members.length,
    totalActivities,
    members,
  };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type":                "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}

function errorResponse(message, status = 400) {
  return jsonResponse({ error: message }, status);
}

// ── Core fetch-and-cache logic ────────────────────────────────────────────────

async function fetchAndCacheWeek(env, weekOffset) {
  const { start: weekStart, end: weekEnd } = getWeekRange(weekOffset);
  const cacheKey = `club_data_week_${isoWeekKey(weekStart)}`;

  const accessToken  = await getAccessToken(env);
  const clubID       = env.STRAVA_CLUB_ID ?? "212760";
  const rawActivities = await fetchClubActivities(clubID, accessToken, weekStart);

  const payload = aggregateActivities(
    rawActivities,
    weekStart,
    weekEnd,
    new Date().toISOString()
  );

  // Cache in KV
  await env.STRAVA_KV.put(cacheKey, JSON.stringify(payload), {
    expirationTtl: CACHE_TTL_SECONDS,
  });

  return payload;
}

// ── Main handler ──────────────────────────────────────────────────────────────

export default {
  // ── Cron trigger: refresh current week every hour ──────────────────────────
  async scheduled(event, env, ctx) {
    ctx.waitUntil(fetchAndCacheWeek(env, 0));
  },

  // ── HTTP requests ──────────────────────────────────────────────────────────
  async fetch(request, env) {
    // CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin":  "*",
          "Access-Control-Allow-Methods": "GET, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type",
        },
      });
    }

    if (request.method !== "GET") {
      return errorResponse("Method not allowed", 405);
    }

    const url = new URL(request.url);

    // ── GET /club-data[?weekOffset=N] ──────────────────────────────────────
    if (url.pathname === "/club-data") {
      const offsetParam = url.searchParams.get("weekOffset");
      const weekOffset  = offsetParam !== null ? parseInt(offsetParam, 10) : 0;

      if (isNaN(weekOffset) || weekOffset > 0 || weekOffset < -52) {
        return errorResponse("Invalid weekOffset. Must be 0 (current) or negative (past weeks, max -52).");
      }

      const { start: weekStart } = getWeekRange(weekOffset);
      const cacheKey = `club_data_week_${isoWeekKey(weekStart)}`;

      // Try KV cache first
      const cached = await env.STRAVA_KV.get(cacheKey);
      if (cached) {
        return new Response(cached, {
          headers: {
            "Content-Type":                "application/json",
            "Access-Control-Allow-Origin": "*",
            "X-Cache":                     "HIT",
          },
        });
      }

      // Cache miss — fetch live
      try {
        const payload = await fetchAndCacheWeek(env, weekOffset);
        return jsonResponse(payload);
      } catch (err) {
        return errorResponse(`Failed to fetch club data: ${err.message}`, 502);
      }
    }

    // ── POST /exchange and /refresh are handled by the OTHER worker ────────
    return errorResponse("Not found", 404);
  },
};
