import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import {
  getTimezone,
  getUtcOffsetString,
  parseTime,
  getCurrentTime,
  addDays,
  formatDate,
} from "../time.js";

describe("time utilities", () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  describe("getTimezone", () => {
    it("should return TIMEZONE env var when set", () => {
      process.env.TIMEZONE = "America/New_York";
      expect(getTimezone()).toBe("America/New_York");
    });

    it("should auto-detect timezone when env not set", () => {
      delete process.env.TIMEZONE;
      const tz = getTimezone();
      expect(tz).toBeTruthy();
      // Should be a valid IANA timezone
      expect(tz).toMatch(/^[A-Z][a-z]+\/[A-Z][a-z_]+/);
    });
  });

  describe("getUtcOffsetString", () => {
    it("should return a valid offset format", () => {
      process.env.TIMEZONE = "Asia/Seoul";
      const offset = getUtcOffsetString();
      expect(offset).toMatch(/^[+-]\d{2}:\d{2}$/);
    });

    it("should return +09:00 for Asia/Seoul", () => {
      process.env.TIMEZONE = "Asia/Seoul";
      expect(getUtcOffsetString()).toBe("+09:00");
    });
  });

  describe("parseTime", () => {
    it("should pass through ISO strings unchanged", () => {
      const iso = "2024-01-15T10:00:00+09:00";
      expect(parseTime(iso)).toBe(iso);
    });

    it("should convert date-time string to ISO", () => {
      process.env.TIMEZONE = "Asia/Seoul";
      const result = parseTime("2024-01-15 10:00");
      expect(result).toBe("2024-01-15T10:00:00+09:00");
    });

    it("should handle date-only strings", () => {
      process.env.TIMEZONE = "UTC";
      const result = parseTime("2024-01-15");
      expect(result).toContain("2024-01-15T");
    });
  });

  describe("getCurrentTime", () => {
    it("should return ISO string", () => {
      const time = getCurrentTime();
      expect(new Date(time).toISOString()).toBe(time);
    });
  });

  describe("addDays", () => {
    it("should add days correctly", () => {
      const result = addDays("2024-01-15T00:00:00Z", 7);
      expect(new Date(result).getDate()).toBe(22);
    });

    it("should handle Date objects", () => {
      const date = new Date("2024-01-15T00:00:00Z");
      const result = addDays(date, 1);
      expect(new Date(result).getDate()).toBe(16);
    });
  });

  describe("formatDate", () => {
    it("should format date to locale string", () => {
      const result = formatDate("2024-01-15T10:30:00Z");
      expect(result).toBeTruthy();
      expect(result).toContain("2024");
    });
  });
});
