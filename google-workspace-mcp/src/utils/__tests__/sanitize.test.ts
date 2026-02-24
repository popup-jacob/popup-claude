import { describe, it, expect } from "vitest";
import {
  escapeDriveQuery,
  validateDriveId,
  sanitizeEmailHeader,
  validateEmail,
  validateMaxLength,
  sanitizeFilename,
  sanitizeRange,
} from "../sanitize.js";

describe("sanitize utilities", () => {
  describe("escapeDriveQuery", () => {
    it("should escape single quotes", () => {
      expect(escapeDriveQuery("test's file")).toBe("test\\'s file");
    });

    it("should escape backslashes", () => {
      expect(escapeDriveQuery("path\\file")).toBe("path\\\\file");
    });

    it("should escape both backslashes and quotes", () => {
      expect(escapeDriveQuery("it\\'s")).toBe("it\\\\\\'s");
    });

    it("should handle empty string", () => {
      expect(escapeDriveQuery("")).toBe("");
    });

    it("should not modify safe strings", () => {
      expect(escapeDriveQuery("normal file name")).toBe("normal file name");
    });

    it("should prevent query injection attempt", () => {
      const malicious = "test' or name contains '";
      const escaped = escapeDriveQuery(malicious);
      // Quotes are escaped with backslashes, preventing query breakout
      expect(escaped).toBe("test\\' or name contains \\'");
      // Verify no unescaped single quotes remain
      expect(escaped.replace(/\\'/g, "")).not.toContain("'");
    });
  });

  describe("validateDriveId", () => {
    it("should accept valid Drive IDs", () => {
      expect(() =>
        validateDriveId("1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms", "fileId")
      ).not.toThrow();
    });

    it("should accept 'root' as a special value", () => {
      expect(() => validateDriveId("root", "folderId")).not.toThrow();
    });

    it("should reject IDs with single quotes", () => {
      expect(() => validateDriveId("root' in parents or '1", "folderId")).toThrow(
        "Invalid folderId"
      );
    });

    it("should reject IDs with spaces", () => {
      expect(() => validateDriveId("file id", "fileId")).toThrow("Invalid fileId");
    });

    it("should accept IDs with hyphens and underscores", () => {
      expect(() => validateDriveId("abc-123_DEF", "fileId")).not.toThrow();
    });
  });

  describe("sanitizeEmailHeader", () => {
    it("should remove CR characters", () => {
      expect(sanitizeEmailHeader("user@test.com\r")).toBe("user@test.com");
    });

    it("should remove LF characters", () => {
      expect(sanitizeEmailHeader("user@test.com\n")).toBe("user@test.com");
    });

    it("should remove CRLF injection attempt", () => {
      const malicious = "user@test.com\r\nBcc: attacker@evil.com";
      expect(sanitizeEmailHeader(malicious)).toBe("user@test.comBcc: attacker@evil.com");
    });

    it("should preserve normal email addresses", () => {
      expect(sanitizeEmailHeader("user@example.com")).toBe("user@example.com");
    });
  });

  describe("validateEmail", () => {
    it("should accept valid email", () => {
      expect(validateEmail("user@example.com")).toBe(true);
    });

    it("should reject email without @", () => {
      expect(validateEmail("userexample.com")).toBe(false);
    });

    it("should reject email without domain", () => {
      expect(validateEmail("user@")).toBe(false);
    });

    it("should reject overly long emails", () => {
      const longEmail = "a".repeat(250) + "@b.com";
      expect(validateEmail(longEmail)).toBe(false);
    });
  });

  describe("validateMaxLength", () => {
    it("should truncate long strings", () => {
      expect(validateMaxLength("hello world", 5)).toBe("hello");
    });

    it("should preserve strings within limit", () => {
      expect(validateMaxLength("hello", 10)).toBe("hello");
    });
  });

  describe("sanitizeFilename", () => {
    it("should replace dangerous characters", () => {
      expect(sanitizeFilename('file<>:"/\\|?*name')).toBe("file_________name");
    });

    it("should remove leading dots", () => {
      expect(sanitizeFilename(".hidden")).toBe("hidden");
    });

    it("should collapse multiple dots", () => {
      expect(sanitizeFilename("file...txt")).toBe("file.txt");
    });

    it("should limit length to 255", () => {
      const longName = "a".repeat(300) + ".txt";
      expect(sanitizeFilename(longName).length).toBeLessThanOrEqual(255);
    });
  });

  describe("sanitizeRange", () => {
    it("should accept valid A1 notation", () => {
      expect(sanitizeRange("A1:B2")).toBe("A1:B2");
    });

    it("should accept sheet-qualified range", () => {
      expect(sanitizeRange("Sheet1!A1:B2")).toBe("Sheet1!A1:B2");
    });

    it("should accept single cell", () => {
      expect(sanitizeRange("A1")).toBe("A1");
    });

    it("should accept sheet name as valid range", () => {
      expect(sanitizeRange("Sheet1")).toBe("Sheet1");
    });

    it("should accept column-only range", () => {
      expect(sanitizeRange("A:C")).toBe("A:C");
    });

    it("should reject range with special characters", () => {
      expect(sanitizeRange("A1; DROP TABLE")).toBeNull();
    });

    it("should trim whitespace", () => {
      expect(sanitizeRange(" A1:B2 ")).toBe("A1:B2");
    });
  });

  /* ------------------------------------------------------------------ */
  /*  TC-SEC-021 ~ TC-SEC-028: Security additional tests                */
  /* ------------------------------------------------------------------ */

  describe("escapeDriveQuery - advanced injection", () => {
    it("TC-SEC-021: should prevent nested quote injection", () => {
      const malicious = "name contains 'test' or name contains '";
      const result = escapeDriveQuery(malicious);
      expect(result).toBe("name contains \\'test\\' or name contains \\'");
      // No unescaped quotes remain
      expect(result.replace(/\\'/g, "")).not.toContain("'");
    });
  });

  describe("validateDriveId - path traversal", () => {
    it("TC-SEC-022: should reject path traversal attempts", () => {
      expect(() => validateDriveId("../../../etc/passwd", "fileId")).toThrow("Invalid fileId");
    });

    it("TC-SEC-022b: should reject URL-encoded path traversal", () => {
      expect(() => validateDriveId("%2e%2e%2f", "folderId")).toThrow("Invalid folderId");
    });
  });

  describe("sanitizeEmailHeader - null byte injection", () => {
    it("TC-SEC-024: should strip null bytes from header values", () => {
      expect(sanitizeEmailHeader("user@test.com\0")).toBe("user@test.com");
    });

    it("TC-SEC-024b: should strip mixed CR, LF, and null bytes", () => {
      const malicious = "user@test.com\r\n\0Bcc: evil@attacker.com";
      expect(sanitizeEmailHeader(malicious)).toBe("user@test.comBcc: evil@attacker.com");
    });
  });

  describe("validateEmail - injection vectors", () => {
    it("TC-SEC-025: should reject emails with angle brackets", () => {
      expect(validateEmail("<script>@evil.com")).toBe(false);
    });

    it("TC-SEC-028: should reject unicode homograph attack", () => {
      // Cyrillic 'а' (U+0430) looks like Latin 'a' but is different
      expect(validateEmail("аdmin@example.com")).toBe(false);
    });
  });

  describe("sanitizeFilename - path traversal", () => {
    it("TC-SEC-026: should neutralize path traversal in filenames", () => {
      const result = sanitizeFilename("../../../etc/passwd");
      expect(result).not.toContain("..");
      expect(result).not.toContain("/");
    });

    it("TC-SEC-026b: should neutralize backslash path traversal", () => {
      const result = sanitizeFilename("..\\..\\windows\\system32");
      expect(result).not.toContain("\\");
    });
  });

  describe("sanitizeRange - injection", () => {
    it("TC-SEC-027: should reject formula injection in range", () => {
      expect(sanitizeRange("=SUM(A1:A10)")).toBeNull();
    });

    it("TC-SEC-027b: should reject pipe injection in range", () => {
      expect(sanitizeRange("A1|cat /etc/passwd")).toBeNull();
    });
  });
});
