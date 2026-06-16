#!/usr/bin/env bash
set -e

git init fetchkit
cd fetchkit
git config user.email "dev@example.com"
git config user.name "Dev"

mkdir -p src examples

cat > package.json << 'EOF'
{
  "name": "fetchkit",
  "version": "1.2.0",
  "description": "Minimal TypeScript HTTP client library",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "test": "jest"
  }
}
EOF

cat > src/types.ts << 'EOF'
export interface RequestOptions {
  method?: string;
  headers?: Record<string, string>;
  body?: string;
}

export interface Response {
  status: number;
  body: string;
}
EOF

cat > src/client.ts << 'EOF'
import { RequestOptions, Response } from "./types";

export async function makeRequest(
  url: string,
  options: RequestOptions = {}
): Promise<Response> {
  const response = await fetch(url, options);
  return {
    status: response.status,
    body: await response.text(),
  };
}
EOF

cat > src/index.ts << 'EOF'
export { makeRequest } from "./client";
export type { RequestOptions, Response } from "./types";
EOF

cat > src/middleware.ts << 'EOF'
import { makeRequest } from "./client";
import { RequestOptions, Response } from "./types";

export async function withLogging(
  url: string,
  options: RequestOptions = {}
): Promise<Response> {
  console.log(`[fetchkit] ${options.method ?? "GET"} ${url}`);
  const result = await makeRequest(url, options);
  console.log(`[fetchkit] Response: ${result.status}`);
  return result;
}
EOF

cat > src/retry.ts << 'EOF'
import { makeRequest } from "./client";
import { RequestOptions, Response } from "./types";

export async function withRetry(
  url: string,
  options: RequestOptions = {},
  maxAttempts = 3
): Promise<Response> {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await makeRequest(url, options);
    } catch (err) {
      if (attempt === maxAttempts) throw err;
    }
  }
  throw new Error("unreachable");
}
EOF

cat > src/utils.ts << 'EOF'
// Builds query strng from a key-value object
export function buildQuery(params: Record<string, string>): string {
  return Object.entries(params)
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
    .join("&");
}
EOF

cat > examples/basic.ts << 'EOF'
import { makeRequest } from "../src/client";

async function main() {
  const res = await makeRequest("https://api.example.com/data");
  console.log(res.status, res.body);
}

main().catch(console.error);
EOF

git add .
git commit -q -m "feat: initial fetchkit implementation"

# --- Leave the following as uncommitted working-tree changes for the agent ---

# 1) Rename makeRequest -> sendRequest across the definition, export and call sites.
cat > src/client.ts << 'EOF'
import { RequestOptions, Response } from "./types";

export async function sendRequest(
  url: string,
  options: RequestOptions = {}
): Promise<Response> {
  const response = await fetch(url, options);
  return {
    status: response.status,
    body: await response.text(),
  };
}
EOF

cat > src/index.ts << 'EOF'
export { sendRequest } from "./client";
export type { RequestOptions, Response } from "./types";
EOF

cat > src/middleware.ts << 'EOF'
import { sendRequest } from "./client";
import { RequestOptions, Response } from "./types";

export async function withLogging(
  url: string,
  options: RequestOptions = {}
): Promise<Response> {
  console.log(`[fetchkit] ${options.method ?? "GET"} ${url}`);
  const result = await sendRequest(url, options);
  console.log(`[fetchkit] Response: ${result.status}`);
  return result;
}
EOF

cat > src/retry.ts << 'EOF'
import { sendRequest } from "./client";
import { RequestOptions, Response } from "./types";

export async function withRetry(
  url: string,
  options: RequestOptions = {},
  maxAttempts = 3
): Promise<Response> {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await sendRequest(url, options);
    } catch (err) {
      if (attempt === maxAttempts) throw err;
    }
  }
  throw new Error("unreachable");
}
EOF

cat > examples/basic.ts << 'EOF'
import { sendRequest } from "../src/client";

async function main() {
  const res = await sendRequest("https://api.example.com/data");
  console.log(res.status, res.body);
}

main().catch(console.error);
EOF

# 2) An unrelated typo fix in a comment ("strng" -> "string").
cat > src/utils.ts << 'EOF'
// Builds query string from a key-value object
export function buildQuery(params: Record<string, string>): string {
  return Object.entries(params)
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
    .join("&");
}
EOF

echo "Done. fetchkit/ has a baseline commit; the rename and typo fix are unstaged."
