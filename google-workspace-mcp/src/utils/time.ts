/**
 * Unified time utilities -- absorbs timezone.ts functionality.
 *
 * FR-S3-05b: Shared utility extraction (parseTime, getCurrentTime, addDays, formatDate)
 * FR-S4-03: Dynamic timezone (getTimezone, getUtcOffsetString)
 *
 * Replaces hardcoded "Asia/Seoul" with Intl API auto-detection + TIMEZONE env override.
 */

/**
 * Get the current timezone.
 * Uses TIMEZONE environment variable if set, otherwise auto-detects from system.
 */
export function getTimezone(): string {
  return (
    process.env.TIMEZONE ||
    Intl.DateTimeFormat().resolvedOptions().timeZone
  );
}

/**
 * Get the UTC offset string for the current timezone (e.g., "+09:00", "-05:00").
 */
export function getUtcOffsetString(): string {
  const tz = getTimezone();
  const formatter = new Intl.DateTimeFormat("en-US", {
    timeZone: tz,
    timeZoneName: "longOffset",
  });
  const parts = formatter.formatToParts(new Date());
  const offset =
    parts.find((p) => p.type === "timeZoneName")?.value || "+00:00";
  const match = offset.match(/GMT([+-]\d{2}:\d{2})/);
  return match ? match[1] : "+00:00";
}

/**
 * Parse a time string into ISO 8601 format.
 * If the input already contains 'T', it is returned as-is.
 * Otherwise, appends the timezone offset.
 *
 * @param timeStr - Time string like "2024-01-15 10:00" or "2024-01-15T10:00:00+09:00"
 */
export function parseTime(timeStr: string): string {
  if (timeStr.includes("T")) return timeStr;
  const [date, time] = timeStr.split(" ");
  const offset = getUtcOffsetString();
  return `${date}T${time || "00:00"}:00${offset}`;
}

/**
 * Get current time in ISO 8601 format.
 */
export function getCurrentTime(): string {
  return new Date().toISOString();
}

/**
 * Add days to a date and return as ISO string.
 */
export function addDays(date: string | Date, days: number): string {
  const baseDate = typeof date === "string" ? new Date(date) : date;
  return new Date(baseDate.getTime() + days * 86400000).toISOString();
}

/**
 * Format an ISO date string to a human-readable locale string.
 */
export function formatDate(
  isoString: string,
  locale: string = "en-US"
): string {
  return new Date(isoString).toLocaleString(locale, {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
}
