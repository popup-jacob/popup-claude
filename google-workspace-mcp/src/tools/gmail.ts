import { z } from "zod";
import { getGoogleServices } from "../auth/oauth.js";
import { sanitizeEmailHeader } from "../utils/sanitize.js";
import { withRetry } from "../utils/retry.js";
import { extractTextBody, extractAttachments } from "../utils/mime.js";
import { messages, msg } from "../utils/messages.js";

/**
 * Gmail tool definitions
 */
export const gmailTools = {
  gmail_search: {
    description: "Search emails in Gmail",
    schema: {
      query: z.string().describe("Search query (e.g. 'from:user@example.com', 'subject:meeting')"),
      maxResults: z.number().optional().default(10).describe("Maximum number of results"),
    },
    handler: async ({ query, maxResults }: { query: string; maxResults: number }) => {
      const { gmail } = await getGoogleServices();

      const response = await withRetry(() =>
        gmail.users.messages.list({
          userId: "me",
          q: query,
          maxResults,
        })
      );

      const msgs = response.data.messages || [];

      const details = await Promise.all(
        msgs.slice(0, 10).map(async (m) => {
          const detail = await withRetry(() =>
            gmail.users.messages.get({
              userId: "me",
              id: m.id!,
              format: "metadata",
              metadataHeaders: ["From", "Subject", "Date"],
            })
          );

          const headers = detail.data.payload?.headers || [];
          return {
            id: m.id,
            from: headers.find((h) => h.name === "From")?.value,
            subject: headers.find((h) => h.name === "Subject")?.value,
            date: headers.find((h) => h.name === "Date")?.value,
            snippet: detail.data.snippet,
          };
        })
      );

      return {
        total: msgs.length,
        messages: details,
      };
    },
  },

  gmail_read: {
    description: "Read the content of a specific email",
    schema: {
      messageId: z.string().describe("Email message ID"),
    },
    handler: async ({ messageId }: { messageId: string }) => {
      const { gmail } = await getGoogleServices();

      const response = await withRetry(() =>
        gmail.users.messages.get({
          userId: "me",
          id: messageId,
          format: "full",
        })
      );

      const headers = response.data.payload?.headers || [];

      // FR-S4-07: Use recursive MIME parser from mime.ts
      const body = response.data.payload
        ? extractTextBody(response.data.payload)
        : "";

      // FR-S4-07: Use recursive attachment extractor from mime.ts
      const attachments = response.data.payload
        ? extractAttachments(response.data.payload)
        : [];

      return {
        id: messageId,
        from: headers.find((h) => h.name === "From")?.value,
        to: headers.find((h) => h.name === "To")?.value,
        cc: headers.find((h) => h.name === "Cc")?.value,
        subject: headers.find((h) => h.name === "Subject")?.value,
        date: headers.find((h) => h.name === "Date")?.value,
        body: body.slice(0, 5000),
        attachments,
        labels: response.data.labelIds,
      };
    },
  },

  gmail_send: {
    description: "Send an email",
    schema: {
      to: z.string().describe("Recipient email address"),
      subject: z.string().describe("Subject"),
      body: z.string().describe("Body content"),
      cc: z.string().optional().describe("CC recipients"),
      bcc: z.string().optional().describe("BCC recipients"),
    },
    handler: async ({ to, subject, body, cc, bcc }: { to: string; subject: string; body: string; cc?: string; bcc?: string }) => {
      const { gmail } = await getGoogleServices();

      // FR-S1-10: Sanitize email headers to prevent CRLF injection
      const safeTo = sanitizeEmailHeader(to);
      const safeCc = cc ? sanitizeEmailHeader(cc) : undefined;
      const safeBcc = bcc ? sanitizeEmailHeader(bcc) : undefined;

      // Build RFC 2822 message: headers, blank line, body
      const hdrs = [
        `To: ${safeTo}`,
        ...(safeCc ? [`Cc: ${safeCc}`] : []),
        ...(safeBcc ? [`Bcc: ${safeBcc}`] : []),
        `Subject: =?UTF-8?B?${Buffer.from(subject).toString("base64")}?=`,
        "Content-Type: text/plain; charset=utf-8",
      ];
      const messageParts = hdrs.join("\n") + "\n\n" + body;

      const encodedMessage = Buffer.from(messageParts)
        .toString("base64")
        .replace(/\+/g, "-")
        .replace(/\//g, "_")
        .replace(/=+$/, "");

      const response = await withRetry(() =>
        gmail.users.messages.send({
          userId: "me",
          requestBody: {
            raw: encodedMessage,
          },
        })
      );

      return {
        success: true,
        messageId: response.data.id,
        message: msg(messages.gmail.emailSent, safeTo),
      };
    },
  },

  gmail_draft_create: {
    description: "Create an email draft (without sending)",
    schema: {
      to: z.string().describe("Recipient email address"),
      subject: z.string().describe("Subject"),
      body: z.string().describe("Body content"),
      cc: z.string().optional().describe("CC recipients"),
    },
    handler: async ({ to, subject, body, cc }: { to: string; subject: string; body: string; cc?: string }) => {
      const { gmail } = await getGoogleServices();

      // FR-S1-10: Sanitize email headers
      const safeTo = sanitizeEmailHeader(to);
      const safeCc = cc ? sanitizeEmailHeader(cc) : undefined;

      // Build RFC 2822 message: headers, blank line, body
      const hdrs = [
        `To: ${safeTo}`,
        ...(safeCc ? [`Cc: ${safeCc}`] : []),
        `Subject: =?UTF-8?B?${Buffer.from(subject).toString("base64")}?=`,
        "Content-Type: text/plain; charset=utf-8",
      ];
      const messageParts = hdrs.join("\n") + "\n\n" + body;

      const encodedMessage = Buffer.from(messageParts)
        .toString("base64")
        .replace(/\+/g, "-")
        .replace(/\//g, "_")
        .replace(/=+$/, "");

      const response = await withRetry(() =>
        gmail.users.drafts.create({
          userId: "me",
          requestBody: {
            message: {
              raw: encodedMessage,
            },
          },
        })
      );

      return {
        success: true,
        draftId: response.data.id,
        message: messages.gmail.draftSaved,
      };
    },
  },

  gmail_draft_list: {
    description: "List saved drafts",
    schema: {
      maxResults: z.number().optional().default(10).describe("Maximum number of results"),
    },
    handler: async ({ maxResults }: { maxResults: number }) => {
      const { gmail } = await getGoogleServices();

      const response = await withRetry(() =>
        gmail.users.drafts.list({
          userId: "me",
          maxResults,
        })
      );

      const drafts = response.data.drafts || [];

      const details = await Promise.all(
        drafts.slice(0, 10).map(async (draft) => {
          const detail = await withRetry(() =>
            gmail.users.drafts.get({
              userId: "me",
              id: draft.id!,
              format: "metadata",
            })
          );

          const hdrs = detail.data.message?.payload?.headers || [];
          return {
            draftId: draft.id,
            to: hdrs.find((h) => h.name === "To")?.value,
            subject: hdrs.find((h) => h.name === "Subject")?.value,
            snippet: detail.data.message?.snippet,
          };
        })
      );

      return {
        total: drafts.length,
        drafts: details,
      };
    },
  },

  gmail_draft_send: {
    description: "Send a saved draft",
    schema: {
      draftId: z.string().describe("Draft ID"),
    },
    handler: async ({ draftId }: { draftId: string }) => {
      const { gmail } = await getGoogleServices();

      const response = await withRetry(() =>
        gmail.users.drafts.send({
          userId: "me",
          requestBody: {
            id: draftId,
          },
        })
      );

      return {
        success: true,
        messageId: response.data.id,
        message: messages.gmail.draftSent,
      };
    },
  },

  gmail_draft_delete: {
    description: "Delete a draft",
    schema: {
      draftId: z.string().describe("Draft ID"),
    },
    handler: async ({ draftId }: { draftId: string }) => {
      const { gmail } = await getGoogleServices();

      await withRetry(() =>
        gmail.users.drafts.delete({
          userId: "me",
          id: draftId,
        })
      );

      return {
        success: true,
        message: messages.gmail.draftDeleted,
      };
    },
  },

  gmail_labels_list: {
    description: "List all labels",
    schema: {},
    handler: async () => {
      const { gmail } = await getGoogleServices();

      const response = await withRetry(() =>
        gmail.users.labels.list({
          userId: "me",
        })
      );

      const labels = response.data.labels || [];

      return {
        labels: labels.map((label) => ({
          id: label.id,
          name: label.name,
          type: label.type,
        })),
      };
    },
  },

  gmail_labels_add: {
    description: "Add labels to an email",
    schema: {
      messageId: z.string().describe("Email message ID"),
      labelIds: z.array(z.string()).describe("Label IDs to add"),
    },
    handler: async ({ messageId, labelIds }: { messageId: string; labelIds: string[] }) => {
      const { gmail } = await getGoogleServices();

      await withRetry(() =>
        gmail.users.messages.modify({
          userId: "me",
          id: messageId,
          requestBody: {
            addLabelIds: labelIds,
          },
        })
      );

      return {
        success: true,
        message: messages.gmail.labelAdded,
      };
    },
  },

  gmail_labels_remove: {
    description: "Remove labels from an email",
    schema: {
      messageId: z.string().describe("Email message ID"),
      labelIds: z.array(z.string()).describe("Label IDs to remove"),
    },
    handler: async ({ messageId, labelIds }: { messageId: string; labelIds: string[] }) => {
      const { gmail } = await getGoogleServices();

      await withRetry(() =>
        gmail.users.messages.modify({
          userId: "me",
          id: messageId,
          requestBody: {
            removeLabelIds: labelIds,
          },
        })
      );

      return {
        success: true,
        message: messages.gmail.labelRemoved,
      };
    },
  },

  gmail_attachment_get: {
    description: "Get email attachment data",
    schema: {
      messageId: z.string().describe("Email message ID"),
      attachmentId: z.string().describe("Attachment ID"),
    },
    handler: async ({ messageId, attachmentId }: { messageId: string; attachmentId: string }) => {
      const { gmail } = await getGoogleServices();

      const response = await withRetry(() =>
        gmail.users.messages.attachments.get({
          userId: "me",
          messageId,
          id: attachmentId,
        })
      );

      // FR-S4-08: Return full attachment data (base64 encoded)
      return {
        attachmentId,
        size: response.data.size,
        data: response.data.data,
        message: messages.gmail.attachmentFetched,
      };
    },
  },

  gmail_trash: {
    description: "Move an email to trash",
    schema: {
      messageId: z.string().describe("Email message ID"),
    },
    handler: async ({ messageId }: { messageId: string }) => {
      const { gmail } = await getGoogleServices();

      await withRetry(() =>
        gmail.users.messages.trash({
          userId: "me",
          id: messageId,
        })
      );

      return {
        success: true,
        message: messages.gmail.movedToTrash,
      };
    },
  },

  gmail_untrash: {
    description: "Restore an email from trash",
    schema: {
      messageId: z.string().describe("Email message ID"),
    },
    handler: async ({ messageId }: { messageId: string }) => {
      const { gmail } = await getGoogleServices();

      await withRetry(() =>
        gmail.users.messages.untrash({
          userId: "me",
          id: messageId,
        })
      );

      return {
        success: true,
        message: messages.gmail.restoredFromTrash,
      };
    },
  },

  gmail_mark_read: {
    description: "Mark an email as read",
    schema: {
      messageId: z.string().describe("Email message ID"),
    },
    handler: async ({ messageId }: { messageId: string }) => {
      const { gmail } = await getGoogleServices();

      await withRetry(() =>
        gmail.users.messages.modify({
          userId: "me",
          id: messageId,
          requestBody: {
            removeLabelIds: ["UNREAD"],
          },
        })
      );

      return {
        success: true,
        message: messages.gmail.markedRead,
      };
    },
  },

  gmail_mark_unread: {
    description: "Mark an email as unread",
    schema: {
      messageId: z.string().describe("Email message ID"),
    },
    handler: async ({ messageId }: { messageId: string }) => {
      const { gmail } = await getGoogleServices();

      await withRetry(() =>
        gmail.users.messages.modify({
          userId: "me",
          id: messageId,
          requestBody: {
            addLabelIds: ["UNREAD"],
          },
        })
      );

      return {
        success: true,
        message: messages.gmail.markedUnread,
      };
    },
  },
};
