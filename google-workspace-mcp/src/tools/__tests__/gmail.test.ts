import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { gmailTools } from "../gmail.js";

// Mock getGoogleServices
const mockGmailApi = {
  users: {
    messages: {
      list: vi.fn(),
      get: vi.fn(),
      send: vi.fn(),
      modify: vi.fn(),
      trash: vi.fn(),
      untrash: vi.fn(),
      attachments: {
        get: vi.fn(),
      },
    },
    drafts: {
      list: vi.fn(),
      get: vi.fn(),
      create: vi.fn(),
      send: vi.fn(),
      delete: vi.fn(),
    },
    labels: {
      list: vi.fn(),
    },
  },
};

vi.mock("../../auth/oauth", () => ({
  getGoogleServices: vi.fn(async () => ({
    gmail: mockGmailApi,
  })),
}));

describe("Gmail Tools - Security Tests (P0)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe("gmail_send - TC-G01: Header Injection Prevention", () => {
    it("should prevent CRLF injection in subject field", async () => {
      const maliciousSubject = "Test Subject\r\nBcc: attacker@evil.com";

      mockGmailApi.users.messages.send.mockResolvedValue({
        data: { id: "msg123", labelIds: ["SENT"] },
      });

      const result = await gmailTools.gmail_send.handler({
        to: "user@example.com",
        subject: maliciousSubject,
        body: "Test body",
      });

      // Verify the email was sent
      expect(result.success).toBe(true);
      expect(mockGmailApi.users.messages.send).toHaveBeenCalled();

      // Get the raw message that was sent
      const sentMessage = mockGmailApi.users.messages.send.mock.calls[0][0];
      const rawEncoded = sentMessage.requestBody.raw;

      // Decode the base64url encoded message
      const decoded = Buffer.from(
        rawEncoded.replace(/-/g, "+").replace(/_/g, "/"),
        "base64"
      ).toString("utf-8");

      // Should NOT contain the injected Bcc header
      expect(decoded).not.toContain("Bcc: attacker@evil.com");

      // Should only have ONE blank line separating headers from body
      // (CRLF injection would create additional header sections)
      const doubleCRLF = decoded.match(/\r?\n\r?\n/g);
      expect(doubleCRLF?.length).toBe(1);
    });

    it("should prevent header injection via To field", async () => {
      const maliciousTo = "user@example.com\r\nCc: attacker@evil.com";

      // Note: This test expects input validation to reject malicious input
      // Current implementation does NOT validate - this is a KNOWN SECURITY GAP

      // TODO: Add email validation before sending
      // await expect(
      //   gmailTools.gmail_send.handler({
      //     to: maliciousTo,
      //     subject: 'Test',
      //     body: 'Test',
      //   })
      // ).rejects.toThrow(/Invalid email address/);

      // FR-S1-12: validateEmail now rejects CRLF-injected addresses before sanitization
      await expect(
        gmailTools.gmail_send.handler({
          to: maliciousTo,
          subject: "Test",
          body: "Test",
        })
      ).rejects.toThrow("Invalid 'to' email address format.");
    });

    it("should prevent header injection via Cc field", async () => {
      const maliciousCc = "user@example.com\r\nBcc: attacker@evil.com";

      // FR-S1-12: validateEmail now rejects CRLF-injected addresses
      await expect(
        gmailTools.gmail_send.handler({
          to: "recipient@example.com",
          cc: maliciousCc,
          subject: "Test",
          body: "Test",
        })
      ).rejects.toThrow("Invalid 'cc' email address format.");
    });
  });

  describe("gmail_send - TC-G02: Email Address Validation", () => {
    it("should accept valid email formats", async () => {
      const validEmails = [
        "user@example.com",
        "user.name@example.com",
        "user+tag@example.com",
        "user@sub.example.co.uk",
      ];

      mockGmailApi.users.messages.send.mockResolvedValue({
        data: { id: "msg123" },
      });

      for (const email of validEmails) {
        const result = await gmailTools.gmail_send.handler({
          to: email,
          subject: "Test",
          body: "Test",
        });

        expect(result.success).toBe(true);
      }

      expect(mockGmailApi.users.messages.send).toHaveBeenCalledTimes(validEmails.length);
    });

    // TODO: Add input validation for invalid emails
    // it('should reject invalid email formats', async () => {
    //   const invalidEmails = [
    //     'not-an-email',
    //     'missing@',
    //     '@nodomain.com',
    //     'spaces in@email.com',
    //     'semicolon;inject@test.com',
    //   ];

    //   for (const email of invalidEmails) {
    //     await expect(
    //       gmailTools.gmail_send.handler({
    //         to: email,
    //         subject: 'Test',
    //         body: 'Test',
    //       })
    //     ).rejects.toThrow(/Invalid email address/);
    //   }
    // });
  });
});

describe("Gmail Tools - Core Functionality (P1)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("gmail_read - TC-G03: MIME Parsing", () => {
    it("should parse multipart/alternative with text/plain", async () => {
      const mockMessage = {
        data: {
          id: "msg123",
          payload: {
            headers: [
              { name: "From", value: "sender@test.com" },
              { name: "Subject", value: "Test Subject" },
              { name: "Date", value: "Mon, 12 Feb 2026 10:00:00 +0900" },
            ],
            parts: [
              {
                mimeType: "text/plain",
                body: { data: Buffer.from("Plain text body").toString("base64") },
              },
              {
                mimeType: "text/html",
                body: { data: Buffer.from("<p>HTML body</p>").toString("base64") },
              },
            ],
          },
          labelIds: ["INBOX", "UNREAD"],
        },
      };

      mockGmailApi.users.messages.get.mockResolvedValue(mockMessage);

      const result = await gmailTools.gmail_read.handler({ messageId: "msg123" });

      expect(result.id).toBe("msg123");
      expect(result.from).toBe("sender@test.com");
      expect(result.subject).toBe("Test Subject");
      expect(result.body).toBe("Plain text body");
    });

    it("should handle single-part message without parts array", async () => {
      const mockMessage = {
        data: {
          id: "msg456",
          payload: {
            headers: [
              { name: "From", value: "sender@test.com" },
              { name: "Subject", value: "Simple Message" },
            ],
            body: { data: Buffer.from("Direct body content").toString("base64") },
          },
          labelIds: ["INBOX"],
        },
      };

      mockGmailApi.users.messages.get.mockResolvedValue(mockMessage);

      const result = await gmailTools.gmail_read.handler({ messageId: "msg456" });

      expect(result.body).toBe("Direct body content");
    });

    it("should prioritize text/plain over text/html in multipart", async () => {
      const mockMessage = {
        data: {
          id: "msg789",
          payload: {
            headers: [],
            parts: [
              {
                mimeType: "text/html",
                body: { data: Buffer.from("<p>HTML first</p>").toString("base64") },
              },
              {
                mimeType: "text/plain",
                body: { data: Buffer.from("Plain text second").toString("base64") },
              },
            ],
          },
          labelIds: [],
        },
      };

      mockGmailApi.users.messages.get.mockResolvedValue(mockMessage);

      const result = await gmailTools.gmail_read.handler({ messageId: "msg789" });

      // Should return plain text even though HTML came first
      expect(result.body).toBe("Plain text second");
    });
  });

  describe("gmail_read - TC-G04: Attachment Handling", () => {
    it("should truncate body to 5000 characters", async () => {
      const longBody = "A".repeat(10000);

      const mockMessage = {
        data: {
          id: "msg_long",
          payload: {
            headers: [],
            body: { data: Buffer.from(longBody).toString("base64") },
          },
          labelIds: [],
        },
      };

      mockGmailApi.users.messages.get.mockResolvedValue(mockMessage);

      const result = await gmailTools.gmail_read.handler({ messageId: "msg_long" });

      expect(result.body.length).toBe(5000);
      expect(result.body).toBe("A".repeat(5000));
    });

    it("should extract attachment metadata correctly", async () => {
      const mockMessage = {
        data: {
          id: "msg_attach",
          payload: {
            headers: [],
            parts: [
              {
                mimeType: "text/plain",
                body: { data: Buffer.from("Email with attachment").toString("base64") },
              },
              {
                filename: "document.pdf",
                mimeType: "application/pdf",
                body: { attachmentId: "att123", size: 50000 },
              },
              {
                filename: "image.png",
                mimeType: "image/png",
                body: { attachmentId: "att456", size: 25000 },
              },
            ],
          },
          labelIds: [],
        },
      };

      mockGmailApi.users.messages.get.mockResolvedValue(mockMessage);

      const result = await gmailTools.gmail_read.handler({ messageId: "msg_attach" });

      expect(result.attachments).toHaveLength(2);
      expect(result.attachments[0]).toEqual({
        filename: "document.pdf",
        mimeType: "application/pdf",
        attachmentId: "att123",
        size: 50000,
      });
      expect(result.attachments[1]).toEqual({
        filename: "image.png",
        mimeType: "image/png",
        attachmentId: "att456",
        size: 25000,
      });
    });

    it("should filter out parts without filename or attachmentId", async () => {
      const mockMessage = {
        data: {
          id: "msg_filter",
          payload: {
            headers: [],
            parts: [
              {
                filename: "valid.pdf",
                mimeType: "application/pdf",
                body: { attachmentId: "att1", size: 1000 },
              },
              {
                // No filename
                mimeType: "application/pdf",
                body: { attachmentId: "att2", size: 2000 },
              },
              {
                filename: "no-attachment-id.pdf",
                mimeType: "application/pdf",
                body: { size: 3000 }, // No attachmentId
              },
            ],
          },
          labelIds: [],
        },
      };

      mockGmailApi.users.messages.get.mockResolvedValue(mockMessage);

      const result = await gmailTools.gmail_read.handler({ messageId: "msg_filter" });

      // Only the first part should be in attachments
      expect(result.attachments).toHaveLength(1);
      expect(result.attachments[0].filename).toBe("valid.pdf");
    });
  });

  describe("gmail_search - TC-G05: Edge Cases", () => {
    it("should handle empty search results", async () => {
      mockGmailApi.users.messages.list.mockResolvedValue({
        data: {},
      });

      const result = await gmailTools.gmail_search.handler({
        query: "nonexistent_query",
        maxResults: 10,
      });

      expect(result.total).toBe(0);
      expect(result.messages).toEqual([]);
    });

    it("should respect maxResults parameter", async () => {
      const mockMessages = Array.from({ length: 20 }, (_, i) => ({ id: `msg${i}` }));

      mockGmailApi.users.messages.list.mockResolvedValue({
        data: { messages: mockMessages },
      });

      await gmailTools.gmail_search.handler({
        query: "test",
        maxResults: 5,
      });

      expect(mockGmailApi.users.messages.list).toHaveBeenCalledWith({
        userId: "me",
        q: "test",
        maxResults: 5,
      });
    });

    it("should limit detail fetch to first 10 messages", async () => {
      const mockMessages = Array.from({ length: 20 }, (_, i) => ({ id: `msg${i}` }));

      mockGmailApi.users.messages.list.mockResolvedValue({
        data: { messages: mockMessages },
      });

      mockGmailApi.users.messages.get.mockResolvedValue({
        data: {
          id: "msg",
          snippet: "test",
          payload: { headers: [] },
        },
      });

      await gmailTools.gmail_search.handler({
        query: "test",
        maxResults: 20,
      });

      // Should only fetch details for first 10
      expect(mockGmailApi.users.messages.get).toHaveBeenCalledTimes(10);
    });
  });

  describe("gmail_attachment_get - TC-A01: Full Attachment Data", () => {
    it("should return full attachment data without truncation", async () => {
      const largeData = "X".repeat(5000);

      mockGmailApi.users.messages.attachments.get.mockResolvedValue({
        data: {
          size: 5000,
          data: largeData,
        },
      });

      const result = await gmailTools.gmail_attachment_get.handler({
        messageId: "msg123",
        attachmentId: "att123",
      });

      // FR-S4-08: Full data returned, no truncation
      expect(result.data).toBeDefined();
      expect(result.data!.length).toBe(5000);
      expect(result.data).toBe(largeData);
    });
  });
});

describe("Gmail Tools - Label Operations (P1)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should list all labels", async () => {
    mockGmailApi.users.labels.list.mockResolvedValue({
      data: {
        labels: [
          { id: "INBOX", name: "INBOX", type: "system" },
          { id: "Label_1", name: "Work", type: "user" },
        ],
      },
    });

    const result = await gmailTools.gmail_labels_list.handler();

    expect(result.labels).toHaveLength(2);
    expect(result.labels[0]).toEqual({ id: "INBOX", name: "INBOX", type: "system" });
  });

  it("should add labels to message", async () => {
    mockGmailApi.users.messages.modify.mockResolvedValue({ data: {} });

    const result = await gmailTools.gmail_labels_add.handler({
      messageId: "msg123",
      labelIds: ["IMPORTANT", "Label_1"],
    });

    expect(result.success).toBe(true);
    expect(mockGmailApi.users.messages.modify).toHaveBeenCalledWith({
      userId: "me",
      id: "msg123",
      requestBody: {
        addLabelIds: ["IMPORTANT", "Label_1"],
      },
    });
  });

  it("should remove labels from message", async () => {
    mockGmailApi.users.messages.modify.mockResolvedValue({ data: {} });

    const result = await gmailTools.gmail_labels_remove.handler({
      messageId: "msg123",
      labelIds: ["SPAM"],
    });

    expect(result.success).toBe(true);
    expect(mockGmailApi.users.messages.modify).toHaveBeenCalledWith({
      userId: "me",
      id: "msg123",
      requestBody: {
        removeLabelIds: ["SPAM"],
      },
    });
  });
});

describe("Gmail Tools - Draft Operations (P1)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should list drafts", async () => {
    mockGmailApi.users.drafts.list.mockResolvedValue({
      data: {
        drafts: [{ id: "draft1" }, { id: "draft2" }],
      },
    });

    mockGmailApi.users.drafts.get.mockResolvedValue({
      data: {
        message: {
          payload: {
            headers: [
              { name: "To", value: "user@example.com" },
              { name: "Subject", value: "Draft Subject" },
            ],
          },
          snippet: "Draft preview...",
        },
      },
    });

    const result = await gmailTools.gmail_draft_list.handler({ maxResults: 10 });

    expect(result.total).toBe(2);
    expect(result.drafts).toHaveLength(2);
    expect(result.drafts[0].subject).toBe("Draft Subject");
  });

  it("should handle empty draft list", async () => {
    mockGmailApi.users.drafts.list.mockResolvedValue({
      data: {},
    });

    const result = await gmailTools.gmail_draft_list.handler({ maxResults: 10 });

    expect(result.total).toBe(0);
    expect(result.drafts).toEqual([]);
  });

  it("should create a draft", async () => {
    mockGmailApi.users.drafts.create.mockResolvedValue({
      data: { id: "draft123" },
    });

    const result = await gmailTools.gmail_draft_create.handler({
      to: "user@example.com",
      subject: "Draft Test",
      body: "Draft body",
    });

    expect(result.success).toBe(true);
    expect(result.draftId).toBe("draft123");
  });

  it("should send a draft", async () => {
    mockGmailApi.users.drafts.send.mockResolvedValue({
      data: { id: "sent123" },
    });

    const result = await gmailTools.gmail_draft_send.handler({ draftId: "draft1" });

    expect(result.success).toBe(true);
    expect(result.messageId).toBe("sent123");
  });

  it("should delete a draft", async () => {
    mockGmailApi.users.drafts.delete.mockResolvedValue({ data: {} });

    const result = await gmailTools.gmail_draft_delete.handler({ draftId: "draft1" });

    expect(result.success).toBe(true);
  });
});

describe("Gmail Tools - Trash & Read Status (P1)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should move email to trash", async () => {
    mockGmailApi.users.messages.trash.mockResolvedValue({ data: {} });

    const result = await gmailTools.gmail_trash.handler({ messageId: "msg123" });

    expect(result.success).toBe(true);
    expect(mockGmailApi.users.messages.trash).toHaveBeenCalledWith({
      userId: "me",
      id: "msg123",
    });
  });

  it("should restore email from trash", async () => {
    mockGmailApi.users.messages.untrash.mockResolvedValue({ data: {} });

    const result = await gmailTools.gmail_untrash.handler({ messageId: "msg123" });

    expect(result.success).toBe(true);
    expect(mockGmailApi.users.messages.untrash).toHaveBeenCalledWith({
      userId: "me",
      id: "msg123",
    });
  });

  it("should mark email as read", async () => {
    mockGmailApi.users.messages.modify.mockResolvedValue({ data: {} });

    const result = await gmailTools.gmail_mark_read.handler({ messageId: "msg123" });

    expect(result.success).toBe(true);
    expect(mockGmailApi.users.messages.modify).toHaveBeenCalledWith({
      userId: "me",
      id: "msg123",
      requestBody: {
        removeLabelIds: ["UNREAD"],
      },
    });
  });

  it("should mark email as unread", async () => {
    mockGmailApi.users.messages.modify.mockResolvedValue({ data: {} });

    const result = await gmailTools.gmail_mark_unread.handler({ messageId: "msg123" });

    expect(result.success).toBe(true);
    expect(mockGmailApi.users.messages.modify).toHaveBeenCalledWith({
      userId: "me",
      id: "msg123",
      requestBody: {
        addLabelIds: ["UNREAD"],
      },
    });
  });
});

/* ------------------------------------------------------------------ */
/*  TC-GML-007 ~ TC-GML-018: Gmail additional coverage tests          */
/* ------------------------------------------------------------------ */

describe("Gmail Tools - TC-GML-007: gmail_send with CC/BCC", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should include CC header in raw message when cc is provided", async () => {
    mockGmailApi.users.messages.send.mockResolvedValue({
      data: { id: "msg_cc", labelIds: ["SENT"] },
    });

    const result = await gmailTools.gmail_send.handler({
      to: "recipient@example.com",
      subject: "Test with CC",
      body: "Hello with CC",
      cc: "cc-user@example.com",
    });

    expect(result.success).toBe(true);
    expect(result.messageId).toBe("msg_cc");

    const sentMessage = mockGmailApi.users.messages.send.mock.calls[0][0];
    const rawEncoded = sentMessage.requestBody.raw;
    const decoded = Buffer.from(
      rawEncoded.replace(/-/g, "+").replace(/_/g, "/"),
      "base64"
    ).toString("utf-8");

    expect(decoded).toContain("Cc: cc-user@example.com");
  });

  it("should include BCC header in raw message when bcc is provided", async () => {
    mockGmailApi.users.messages.send.mockResolvedValue({
      data: { id: "msg_bcc", labelIds: ["SENT"] },
    });

    const result = await gmailTools.gmail_send.handler({
      to: "recipient@example.com",
      subject: "Test with BCC",
      body: "Hello with BCC",
      bcc: "bcc-user@example.com",
    });

    expect(result.success).toBe(true);

    const sentMessage = mockGmailApi.users.messages.send.mock.calls[0][0];
    const rawEncoded = sentMessage.requestBody.raw;
    const decoded = Buffer.from(
      rawEncoded.replace(/-/g, "+").replace(/_/g, "/"),
      "base64"
    ).toString("utf-8");

    expect(decoded).toContain("Bcc: bcc-user@example.com");
  });
});

describe("Gmail Tools - TC-GML-009: gmail_send base64url encoding", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should produce valid base64url encoding without + / or trailing =", async () => {
    mockGmailApi.users.messages.send.mockResolvedValue({
      data: { id: "msg_b64", labelIds: ["SENT"] },
    });

    await gmailTools.gmail_send.handler({
      to: "user@example.com",
      subject: "Base64url Test",
      body: "Body with special chars: +/= test data padding",
    });

    const sentMessage = mockGmailApi.users.messages.send.mock.calls[0][0];
    const rawEncoded = sentMessage.requestBody.raw;

    expect(rawEncoded).not.toMatch(/\+/);
    expect(rawEncoded).not.toMatch(/\//);
    expect(rawEncoded).not.toMatch(/=$/);
  });

  it("should pass raw message via requestBody.raw", async () => {
    mockGmailApi.users.messages.send.mockResolvedValue({
      data: { id: "msg_api", labelIds: ["SENT"] },
    });

    await gmailTools.gmail_send.handler({
      to: "user@example.com",
      subject: "API Format Test",
      body: "Body",
    });

    expect(mockGmailApi.users.messages.send).toHaveBeenCalledWith({
      userId: "me",
      requestBody: {
        raw: expect.any(String),
      },
    });
  });
});

describe("Gmail Tools - TC-GML-018: gmail_attachment_get data integrity", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should return attachment data and metadata", async () => {
    const attachData = "SGVsbG8gV29ybGQ";

    mockGmailApi.users.messages.attachments.get.mockResolvedValue({
      data: {
        size: 100,
        data: attachData,
      },
    });

    const result = await gmailTools.gmail_attachment_get.handler({
      messageId: "msg_att",
      attachmentId: "att_test",
    });

    expect(result.data).toBe(attachData);
    expect(result.size).toBe(100);
    expect(result.attachmentId).toBe("att_test");
  });

  it("should call the attachment API with correct parameters", async () => {
    mockGmailApi.users.messages.attachments.get.mockResolvedValue({
      data: { size: 10, data: "dGVzdA" },
    });

    await gmailTools.gmail_attachment_get.handler({
      messageId: "msg_params",
      attachmentId: "att_params",
    });

    expect(mockGmailApi.users.messages.attachments.get).toHaveBeenCalledWith({
      userId: "me",
      messageId: "msg_params",
      id: "att_params",
    });
  });
});
