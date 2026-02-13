/**
 * MIME parsing utilities for Gmail messages.
 *
 * FR-S4-07: Recursive MIME parsing for nested multipart emails.
 * FR-S4-08: Full attachment data retrieval (no 1000-char truncation).
 */

interface MimePart {
  mimeType?: string | null;
  body?: {
    data?: string | null;
    attachmentId?: string | null;
    size?: number | null;
  } | null;
  filename?: string | null;
  parts?: MimePart[] | null;
  headers?: Array<{ name?: string | null; value?: string | null }> | null;
}

export interface AttachmentInfo {
  filename: string;
  mimeType: string;
  attachmentId: string;
  size: number;
}

/**
 * Recursively extract the text/plain body from a MIME structure.
 *
 * Traverses nested multipart parts to find text/plain content,
 * which may be buried under multipart/mixed > multipart/alternative.
 */
export function extractTextBody(payload: MimePart): string {
  // Direct body data (non-multipart messages)
  if (payload.body?.data && payload.mimeType === "text/plain") {
    return Buffer.from(payload.body.data, "base64").toString("utf-8");
  }

  // Recurse into parts
  if (payload.parts) {
    for (const part of payload.parts) {
      if (part.mimeType === "text/plain" && part.body?.data) {
        return Buffer.from(part.body.data, "base64").toString("utf-8");
      }
      // Recurse into nested multipart
      if (part.parts) {
        const nested = extractTextBody(part);
        if (nested) return nested;
      }
    }

    // If no text/plain found, try text/html as fallback
    for (const part of payload.parts) {
      if (part.mimeType === "text/html" && part.body?.data) {
        return Buffer.from(part.body.data, "base64").toString("utf-8");
      }
      if (part.parts) {
        const nested = extractTextBody({
          ...part,
          mimeType: "text/html",
        });
        if (nested) return nested;
      }
    }
  }

  // Fallback: direct body data regardless of mimeType
  if (payload.body?.data) {
    return Buffer.from(payload.body.data, "base64").toString("utf-8");
  }

  return "";
}

/**
 * Recursively extract all attachments from a MIME structure.
 *
 * Traverses nested parts to find all parts with filename and attachmentId.
 */
export function extractAttachments(payload: MimePart): AttachmentInfo[] {
  const attachments: AttachmentInfo[] = [];

  function traverse(part: MimePart): void {
    if (part.filename && part.body?.attachmentId) {
      attachments.push({
        filename: part.filename,
        mimeType: part.mimeType || "application/octet-stream",
        attachmentId: part.body.attachmentId,
        size: part.body.size || 0,
      });
    }
    if (part.parts) {
      for (const child of part.parts) {
        traverse(child);
      }
    }
  }

  traverse(payload);
  return attachments;
}
