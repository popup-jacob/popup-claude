/**
 * Input validation and sanitization utilities.
 *
 * Centralizes all input validation as a cross-cutting concern (OWASP A03 -- Injection).
 * Every user-supplied value MUST pass through the appropriate sanitizer before
 * being interpolated into API queries, email headers, or file operations.
 *
 * FR-S1-12: Input Validation Layer
 * References: security-spec.md Section 9.2, shared-utilities-design.md Section 2
 */

/**
 * Escape a string value for use in Google Drive API query language.
 *
 * The Drive API query language uses single quotes to delimit string values.
 * Backslashes escape the next character. We must escape both backslashes
 * (to prevent escape sequence injection) and single quotes (to prevent
 * string breakout).
 *
 * Reference: https://developers.google.com/drive/api/guides/search-files
 *
 * FR-S1-02: Drive API Query Escaping
 */
export function escapeDriveQuery(input: string): string {
  return input.replace(/\\/g, "\\\\").replace(/'/g, "\\'");
}

/**
 * Validate that a string matches the format of a Google Drive file/folder ID.
 *
 * Google Drive IDs consist of alphanumeric characters, hyphens, and underscores.
 * Rejecting anything else prevents query injection via the folderId parameter.
 *
 * FR-S1-02: Drive API Query Escaping (ID validation)
 */
export const DRIVE_ID_PATTERN = /^[a-zA-Z0-9_-]+$/;

export function validateDriveId(id: string, fieldName: string): void {
  if (id !== "root" && !DRIVE_ID_PATTERN.test(id)) {
    throw new Error(
      `Invalid ${fieldName} format. Expected alphanumeric characters, hyphens, and underscores.`
    );
  }
}

/**
 * Sanitize email header values by removing CRLF sequences.
 *
 * Email headers use CRLF as a line separator. An attacker can inject
 * additional headers (e.g., Bcc) by including \r\n in header values.
 * This function strips all CR and LF characters to prevent header injection.
 *
 * FR-S1-10: Gmail Email Header Injection Prevention
 */
export function sanitizeEmailHeader(header: string): string {
  return header.replace(/[\r\n]/g, "");
}

/**
 * Validate an email address format.
 *
 * Uses a practical regex that covers the vast majority of valid email addresses
 * without being overly permissive. Rejects obvious injection attempts.
 */
export function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+$/;
  return emailRegex.test(email) && email.length <= 254;
}

/**
 * Truncate input to a maximum length.
 *
 * Prevents excessively long inputs from consuming resources or causing
 * buffer-related issues in downstream APIs.
 */
export function validateMaxLength(input: string, max: number): string {
  return input.length > max ? input.substring(0, max) : input;
}

/**
 * Sanitize a filename by removing or replacing dangerous characters.
 *
 * Prevents path traversal and invalid filesystem characters.
 * Gap analysis D-10: Added for file upload/download operations.
 */
export function sanitizeFilename(filename: string): string {
  return filename
    // eslint-disable-next-line no-control-regex
    .replace(/[<>:"/\\|?*\x00-\x1F]/g, "_")
    .replace(/\.+/g, ".")
    .replace(/^\./, "")
    .trim()
    .substring(0, 255);
}

/**
 * Validate and sanitize a Google Sheets A1 notation range.
 *
 * Returns the trimmed range if valid, or null if the format is invalid.
 * Gap analysis D-10: Added for Sheets range operations.
 */
export function sanitizeRange(range: string): string | null {
  // Matches: Sheet1!A1:B2, A1:B2, A1, Sheet1!A1
  const rangeRegex =
    /^([^!]+!)?[A-Z]+\d+(:[A-Z]+\d+)?$/i;
  return rangeRegex.test(range.trim()) ? range.trim() : null;
}
