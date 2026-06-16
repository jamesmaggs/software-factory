#!/usr/bin/env bash
set -e

git init apiclient
cd apiclient
git config user.email "dev@example.com"
git config user.name "Dev"

mkdir -p src

# Build a history with a distinctive, consistent house convention: every commit
# subject ends with a pull-request reference like "(#NN)". This is not something
# a model would guess — it has to read `git log` to discover it.
cat > src/index.js << 'JSEOF'
export { request } from "./client";
JSEOF
cat > src/client.js << 'JSEOF'
export async function request(url, options = {}) {
  const res = await fetch(url, options);
  return { status: res.status, body: await res.text() };
}
JSEOF
git add src/index.js src/client.js
git commit -q -m "feat: add request client (#11)"

cat > src/url.js << 'JSEOF'
export function buildUrl(base, path) {
  return new URL(path, base).toString();
}
JSEOF
git add src/url.js
git commit -q -m "feat: add url builder (#14)"

cat > src/client.js << 'JSEOF'
import { buildUrl } from "./url";

export async function request(base, path, options = {}) {
  const res = await fetch(buildUrl(base, path), options);
  return { status: res.status, body: await res.text() };
}
JSEOF
git add src/client.js
git commit -q -m "refactor: route requests through url builder (#17)"

# --- Working-tree change for the agent to commit: add retry support. ---
cat > src/client.js << 'JSEOF'
import { buildUrl } from "./url";

export async function request(base, path, options = {}, retries = 2) {
  let lastErr;
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const res = await fetch(buildUrl(base, path), options);
      return { status: res.status, body: await res.text() };
    } catch (err) {
      lastErr = err;
    }
  }
  throw lastErr;
}
JSEOF

echo "Done. src/client.js has an uncommitted retry change in apiclient/ (history uses a '(#NN)' subject convention)"
