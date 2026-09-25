/**
 * DEPRECATED — do not deploy this file.
 *
 * This was the standalone Strava token-exchange Worker (POST /exchange and
 * POST /refresh). It is no longer a separate script.
 *
 * Both this file and cloudflare-club-data-worker.js were deployed to the SAME
 * Cloudflare Worker name (`dcc-strava`, one script, one URL). Whichever was
 * deployed last silently replaced the other's routes. When the club-data
 * script won, /exchange and /refresh began returning 404, which broke Strava
 * sign-in and token refresh in both the iOS and tvOS apps — the apps post to
 * those paths from UserAuthService.swift and TVRootView.swift.
 *
 * Both handlers now live in cloudflare-club-data-worker.js, so a single deploy
 * serves every endpoint and one script can no longer clobber the other.
 *
 * Deploying this file again would re-break sign-in by removing /club-data and
 * everything else. The implementation is kept in git history only; see
 * cloudflare-club-data-worker.js for the live code.
 */

throw new Error(
  "cloudflare-workerworker.js is deprecated; deploy cloudflare-club-data-worker.js instead."
);
