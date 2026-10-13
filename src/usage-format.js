const FIVE_HOURS_MINS = 5 * 60;
const WEEK_MINS = 7 * 24 * 60;

export function normalizeUsage(rateLimitResponse, now = new Date()) {
  const snapshot =
    rateLimitResponse?.rateLimitsByLimitId?.codex ??
    rateLimitResponse?.rateLimits;

  if (!snapshot) {
    throw new Error("Codex rate-limit response did not include a usable snapshot.");
  }

  const windows = [snapshot.primary, snapshot.secondary]
    .filter(Boolean)
    .map((window) => normalizeWindow(window, now));

  const fiveHour = windows.find((window) => approximately(window.windowDurationMins, FIVE_HOURS_MINS));
  const weekly = windows.find((window) => approximately(window.windowDurationMins, WEEK_MINS));

  return {
    limitId: snapshot.limitId ?? "codex",
    planType: snapshot.planType ?? null,
    fiveHour: fiveHour ?? (snapshot.primary && toNumber(snapshot.primary.windowDurationMins) === null ? normalizeWindow(snapshot.primary, now) : null),
    weekly: weekly ?? (snapshot.secondary && toNumber(snapshot.secondary.windowDurationMins) === null ? normalizeWindow(snapshot.secondary, now) : null),
    windows,
    credits: snapshot.credits ?? null,
    resetCredits: normalizeResetCredits(rateLimitResponse?.rateLimitResetCredits),
  };
}

export function formatMenuTitle(usage) {
  const parts = [];
  if (usage.fiveHour) {
    parts.push(`5h ${usage.fiveHour.remainingPercent === null ? "--" : usage.fiveHour.remainingPercent + "%"}`);
  }
  if (usage.weekly) {
    parts.push(`7d ${usage.weekly.remainingPercent === null ? "--" : usage.weekly.remainingPercent + "%"}`);
  }
  return parts.length > 0 ? `Codex ${parts.join(" ")}` : "Codex usage";
}

export function formatTextStatus(usage, language = 'en') {
  const zh = language.startsWith('zh');
  const text = (cn, en) => zh ? cn : en;
  const date = value => value ? value.toLocaleString(zh ? 'zh-CN' : 'en-US', {hour12:false}) : text('未知', 'Unknown');
  const percent = value => value === null ? '--' : value + '%';
  const lines = [text('使用量', 'Usage')];
  for (const [label, window] of [[text('5 小时', '5-hour'), usage.fiveHour], [text('每周', 'Weekly'), usage.weekly]]) {
    lines.push(label + text('剩余：', ' remaining: ') + percent(window?.remainingPercent ?? null));
    lines.push(label + text('重置：', ' reset: ') + date(window?.resetsAt));
  }
  const cards = usage.resetCredits;
  lines.push(cards ? text('可用重置次数：', 'Available resets: ') + cards.availableCount : text('暂无重置卡信息', 'Reset information unavailable'));
  if (cards?.availableCount === 0) lines.push(text('暂无可用重置卡', 'No resets available'));
  else if (cards && !cards.credits?.length) lines.push(text('已读取可用次数，暂无卡片详情', 'Available count loaded; card details unavailable'));
  for (const card of cards?.credits ?? []) lines.push((card.resetType === 'codexRateLimits' ? text('完全重置（每周 + 5 小时）', 'Full reset (Weekly + 5 hr)') : card.title ?? card.resetType) + text(' · 到期：', ' · Expires: ') + date(card.expiresAt));
  if (cards?.availableCount > (cards?.credits?.length ?? 0) && cards?.credits?.length) lines.push(text('仅显示接口返回的部分卡片', 'Only some card details were returned'));
  if (usage.credits?.unlimited || usage.credits?.balance != null) lines.push(text('积分余额：', 'Credit balance: ') + (usage.credits.unlimited ? text('不限量', 'Unlimited') : usage.credits.balance));
  return lines.join('\n');
}

function normalizeWindow(window, now) {
  const usedPercent = clampPercent(toNumber(window.usedPercent));
  const remainingPercent = usedPercent === null ? null : clampPercent(100 - usedPercent);
  const resetsAt = typeof window.resetsAt === "number" ? new Date(window.resetsAt * 1000) : null;
  return {
    usedPercent,
    remainingPercent,
    windowDurationMins: toNumber(window.windowDurationMins),
    resetsAt,
    staleAt: new Date(now.getTime()),
  };
}

function toNumber(value) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function clampPercent(value) {
  if (value === null) {
    return null;
  }
  return Math.max(0, Math.min(100, Math.round(value)));
}

function approximately(value, target) {
  return typeof value === "number" && Math.abs(value - target) <= 1;
}

function formatReset(date) {
  if (!date) {
    return "unknown";
  }
  return date.toLocaleString(undefined, { hour12: false });
}

export function normalizeResetCredits(value) {
  if (!value) return null;
  return { availableCount: value.availableCount, credits: value.credits == null ? null : value.credits.map(c => ({ ...c, expiresAt: typeof c.expiresAt === 'number' ? new Date(c.expiresAt * 1000) : null })).sort((a,b) => (a.expiresAt?.getTime() ?? Infinity) - (b.expiresAt?.getTime() ?? Infinity)) };
}
