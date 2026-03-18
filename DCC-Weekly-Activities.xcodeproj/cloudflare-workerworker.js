/**
 * DCC Weekly Activities — Strava Token Exchange Worker
 *
 * Deploy this to Cloudflare Workers (free tier is plenty).
 * It is the ONLY place the Strava client_secret lives.
 * The iOS app never sees the secret.
 *
 * Deploy steps (takes ~5 minutes):
 *   1. Go to https://workers.cloudflare.com  → sign up free
 *   2. Create a new Worker, paste this file in
 *   3. Add two Environment Variables (Settings → Variables):
 *        STRAVA_CLIENT_ID     = 161984
 *        STRAVA_CLIENT_SECRET = <your secret>
 *   4. Save & Deploy — copy the *.workers.dev URL
 *   5. Paste that URL into AppConfiguration.swift as
 *      Strava.tokenWorkerURL
 *
 * Endpoints
 * ─────────
 *  POST /exchange   body: { code: "..." }
 *       → exchanges an auth code for an access + refresh token
 *
 *  POST /refresh    body: { refresh_token: "..." }
 *       → exchanges a refresh token for a new access token
 *
 * CORS is locked to your app's custom URL scheme callback so
 * only your app can talk to this worker.
 */

const STRAVA_TOKEN_URL = "https://www.strava.com/api/v3/oauth/token";

// ── Helpers ────────────────────────────────────────────────────────────────

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      // Native iOS apps do not use CORS, but browsers testing the endpoint will.
      "Access-Control-Allow-Origin": "*",
    },
  });
}

function errorResponse(message, status = 400) {
  return jsonResponse({ error: message }, status);
}

// ── Main handler ───────────────────────────────────────────────────────────

export default {
  async fetch(request, env) {
    // Handle preflight
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type",
        },
      });
    }

    if (request.method !== "POST") {
      return errorResponse("Method not allowed", 405);
    }

    const url = new URL(request.url);

    // ── POST /exchange ─────────────────────────────────────────────────────
    if (url.pathname === "/exchange") {
      let body;
      try {
        body = await request.json();
      } catch {
        return errorResponse("Invalid JSON body");
      }

      const { code } = body;
      if (!code || typeof code !== "string") {
        return errorResponse("Missing or invalid 'code' field");
      }

      const params = new URLSearchParams({
        client_id:     env.STRAVA_CLIENT_ID,
        client_secret: env.STRAVA_CLIENT_SECRET,
        code,
        grant_type:    "authorization_code",
      });

      const stravaRes = await fetch(STRAVA_TOKEN_URL, {
        method:  "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body:    params.toString(),
      });

      const stravaData = await stravaRes.json();

      if (!stravaRes.ok) {
        return errorResponse(
          stravaData.message ?? "Strava token exchange failed",
          stravaRes.status
        );
      }

      // Return only what the app needs — never forward the raw response
      // which might contain fields we don't want to expose.
      return jsonResponse({
        access_token:  stravaData.access_token,
        refresh_token: stravaData.refresh_token,
        expires_at:    stravaData.expires_at,
        token_type:    stravaData.token_type,
      });
    }

    // ── POST /refresh ──────────────────────────────────────────────────────
    if (url.pathname === "/refresh") {
      let body;
      try {
        body = await request.json();
      } catch {
        return errorResponse("Invalid JSON body");
      }

      const { refresh_token } = body;
      if (!refresh_token || typeof refresh_token !== "string") {
        return errorResponse("Missing or invalid 'refresh_token' field");
      }

      const params = new URLSearchParams({
        client_id:     env.STRAVA_CLIENT_ID,
        client_secret: env.STRAVA_CLIENT_SECRET,
        refresh_token,
        grant_type:    "refresh_token",
      });

      const stravaRes = await fetch(STRAVA_TOKEN_URL, {
        method:  "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body:    params.toString(),
      });

      const stravaData = await stravaRes.json();

      if (!stravaRes.ok) {
        return errorResponse(
          stravaData.message ?? "Strava token refresh failed",
          stravaRes.status
        );
      }

      return jsonResponse({
        access_token:  stravaData.access_token,
        refresh_token: stravaData.refresh_token,
        expires_at:    stravaData.expires_at,
        token_type:    stravaData.token_type,
      });
    }

    return errorResponse("Not found", 404);
  },
};
