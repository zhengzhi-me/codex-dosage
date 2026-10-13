#!/usr/bin/env node
import { readCodexRateLimits } from "./app-server-client.js";
import { formatTextStatus, normalizeUsage } from "./usage-format.js";

const args = new Set(process.argv.slice(2));

try {
  const applicationPath = process.argv.find(a => a.startsWith("--app="))?.slice(6);
  const language = process.argv.find(a => a.startsWith("--lang="))?.slice(7) ?? process.env.CODEX_USAGE_LANGUAGE ?? "en";
  const raw = await readCodexRateLimits({ applicationPath });
  const usage = normalizeUsage(raw);

  if (args.has("--json")) {
    console.log(JSON.stringify(usage, null, 2));
  } else {
    console.log(formatTextStatus(usage, language));
  }
} catch (error) {
  console.error(`Unable to read Codex usage safely: ${error.message}`);
  process.exitCode = 1;
}
