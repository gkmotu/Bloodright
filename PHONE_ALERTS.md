# Bloodright phone alerts

Bloodright sends a shared phone alert whenever a build is successfully pushed to `main`.

## One-time Android setup

1. Install **ntfy** from Google Play.
2. Open it and add a subscription.
3. Use this exact topic URL:

   `https://ntfy.sh/bloodright-build-c9a4e71f0db843c6a2e9`

4. Allow notifications for ntfy.

Both phones subscribe to the same Bloodright topic. A normal Bloodright Push then reaches both phones, even if the game is closed.
