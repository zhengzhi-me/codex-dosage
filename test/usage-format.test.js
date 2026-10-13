import assert from "node:assert/strict";
import test from "node:test";

import { redactSensitive } from "../src/app-server-client.js";
import { formatMenuTitle, normalizeUsage } from "../src/usage-format.js";

test("normalizes Codex 5-hour and weekly windows", () => {
  const usage = normalizeUsage({
    rateLimitsByLimitId: {
      codex: {
        limitId: "codex",
        planType: "plus",
        primary: {
          usedPercent: 34,
          windowDurationMins: 300,
          resetsAt: 1780000000,
        },
        secondary: {
          usedPercent: 37,
          windowDurationMins: 10080,
          resetsAt: 1780500000,
        },
      },
    },
  });

  assert.equal(usage.limitId, "codex");
  assert.equal(usage.planType, "plus");
  assert.equal(usage.fiveHour.remainingPercent, 66);
  assert.equal(usage.weekly.remainingPercent, 63);
  assert.equal(formatMenuTitle(usage), "Codex 5h 66% 7d 63%");
});

test("falls back to backward-compatible single snapshot", () => {
  const usage = normalizeUsage({
    rateLimits: {
      limitId: "codex",
      primary: {
        usedPercent: 0,
        windowDurationMins: 300,
      },
      secondary: {
        usedPercent: 101,
        windowDurationMins: 10080,
      },
    },
  });

  assert.equal(usage.fiveHour.remainingPercent, 100);
  assert.equal(usage.weekly.remainingPercent, 0);
});

test("redacts sensitive app-server stderr snippets", () => {
  const redacted = redactSensitive(
    [
      "token: sk-local-development-secret",
      "Authorization = Bearer should-not-survive",
      "api_key=also-should-not-survive",
      "aaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbb.cccccccccccccccccccc",
    ].join("\n"),
  );

  assert.match(redacted, /token: \[redacted\]/);
  assert.match(redacted, /Authorization = \[redacted\]/);
  assert.match(redacted, /api_key=\[redacted\]/);
  assert.match(redacted, /\[redacted-jwt\]/);
  assert.doesNotMatch(redacted, /should-not-survive|also-should-not-survive/);
});

test('missing percentages stay unknown and unrelated buckets are rejected', () => {
  const usage = normalizeUsage({rateLimits:{primary:{windowDurationMins:300},secondary:{usedPercent:13,windowDurationMins:10080}}});
  assert.equal(usage.fiveHour.remainingPercent, null);
  assert.equal(usage.weekly.remainingPercent,87);
  assert.throws(()=>normalizeUsage({rateLimitsByLimitId:{other:{}}}));
});
test('reset cards distinguish absent, count-only, empty and capped details', () => {
  const response = value => normalizeUsage({rateLimits:{},rateLimitResetCredits:value}).resetCredits;
  assert.equal(response(null),null);
  assert.equal(response({availableCount:3,credits:null}).credits,null);
  assert.deepEqual(response({availableCount:0,credits:[]}).credits,[]);
  const cards=response({availableCount:3,credits:[{id:'b',expiresAt:null},{id:'a',expiresAt:42}]});
  assert.equal(cards.availableCount,3); assert.deepEqual(cards.credits.map(c=>c.id),['a','b']);
});
test('a missing primary window does not relabel secondary as five-hour', () => {
  const usage = normalizeUsage({rateLimits:{secondary:{usedPercent:10}}});
  assert.equal(usage.fiveHour, null);
  assert.equal(usage.weekly.remainingPercent, 90);
});
