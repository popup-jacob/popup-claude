import { describe, it, expect } from "vitest";
import { extractTextBody, extractAttachments } from "../mime.js";

describe("MIME utilities", () => {
  describe("extractTextBody", () => {
    it("should extract text/plain from top-level body", () => {
      const payload = {
        mimeType: "text/plain",
        body: {
          data: Buffer.from("Hello World").toString("base64"),
        },
      };
      expect(extractTextBody(payload)).toBe("Hello World");
    });

    it("should extract text/plain from parts", () => {
      const payload = {
        mimeType: "multipart/alternative",
        parts: [
          {
            mimeType: "text/plain",
            body: {
              data: Buffer.from("Plain text body").toString("base64"),
            },
          },
          {
            mimeType: "text/html",
            body: {
              data: Buffer.from("<p>HTML body</p>").toString("base64"),
            },
          },
        ],
      };
      expect(extractTextBody(payload)).toBe("Plain text body");
    });

    it("should handle nested multipart (multipart/mixed > multipart/alternative)", () => {
      const payload = {
        mimeType: "multipart/mixed",
        parts: [
          {
            mimeType: "multipart/alternative",
            parts: [
              {
                mimeType: "text/plain",
                body: {
                  data: Buffer.from("Nested plain text").toString("base64"),
                },
              },
            ],
          },
          {
            mimeType: "application/pdf",
            filename: "doc.pdf",
            body: {
              attachmentId: "att123",
              size: 1024,
            },
          },
        ],
      };
      expect(extractTextBody(payload)).toBe("Nested plain text");
    });

    it("should fallback to text/html if no text/plain", () => {
      const payload = {
        mimeType: "multipart/alternative",
        parts: [
          {
            mimeType: "text/html",
            body: {
              data: Buffer.from("<p>HTML only</p>").toString("base64"),
            },
          },
        ],
      };
      expect(extractTextBody(payload)).toBe("<p>HTML only</p>");
    });

    it("should return empty string for no body", () => {
      const payload = {
        mimeType: "multipart/mixed",
        parts: [],
      };
      expect(extractTextBody(payload)).toBe("");
    });
  });

  describe("extractAttachments", () => {
    it("should extract attachments from flat structure", () => {
      const payload = {
        mimeType: "multipart/mixed",
        parts: [
          {
            mimeType: "text/plain",
            body: { data: Buffer.from("body").toString("base64") },
          },
          {
            mimeType: "application/pdf",
            filename: "report.pdf",
            body: { attachmentId: "att1", size: 2048 },
          },
        ],
      };
      const attachments = extractAttachments(payload);
      expect(attachments).toHaveLength(1);
      expect(attachments[0].filename).toBe("report.pdf");
      expect(attachments[0].attachmentId).toBe("att1");
    });

    it("should extract nested attachments", () => {
      const payload = {
        mimeType: "multipart/mixed",
        parts: [
          {
            mimeType: "multipart/alternative",
            parts: [{ mimeType: "text/plain", body: { data: "dGVzdA==" } }],
          },
          {
            mimeType: "image/png",
            filename: "image.png",
            body: { attachmentId: "att2", size: 4096 },
          },
          {
            mimeType: "multipart/related",
            parts: [
              {
                mimeType: "image/jpeg",
                filename: "photo.jpg",
                body: { attachmentId: "att3", size: 8192 },
              },
            ],
          },
        ],
      };
      const attachments = extractAttachments(payload);
      expect(attachments).toHaveLength(2);
      expect(attachments.map((a) => a.filename)).toEqual(["image.png", "photo.jpg"]);
    });

    it("should return empty array when no attachments", () => {
      const payload = {
        mimeType: "text/plain",
        body: { data: "dGVzdA==" },
      };
      expect(extractAttachments(payload)).toEqual([]);
    });
  });
});
