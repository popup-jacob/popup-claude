import { z } from "zod";
import { getGoogleServices } from "../auth/oauth.js";

/**
 * Gmail 도구 정의
 */
export const gmailTools = {
  gmail_search: {
    description: "Gmail에서 이메일을 검색합니다",
    schema: {
      query: z.string().describe("검색 쿼리 (예: 'from:example@gmail.com', 'subject:회의')"),
      maxResults: z.number().optional().default(10).describe("최대 결과 수"),
    },
    handler: async ({ query, maxResults }: { query: string; maxResults: number }) => {
      const { gmail } = await getGoogleServices();

      const response = await gmail.users.messages.list({
        userId: "me",
        q: query,
        maxResults,
      });

      const messages = response.data.messages || [];

      const details = await Promise.all(
        messages.slice(0, 10).map(async (msg) => {
          const detail = await gmail.users.messages.get({
            userId: "me",
            id: msg.id!,
            format: "metadata",
            metadataHeaders: ["From", "Subject", "Date"],
          });

          const headers = detail.data.payload?.headers || [];
          return {
            id: msg.id,
            from: headers.find((h) => h.name === "From")?.value,
            subject: headers.find((h) => h.name === "Subject")?.value,
            date: headers.find((h) => h.name === "Date")?.value,
            snippet: detail.data.snippet,
          };
        })
      );

      return {
        total: messages.length,
        messages: details,
      };
    },
  },

  gmail_read: {
    description: "특정 이메일의 내용을 읽습니다",
    schema: {
      messageId: z.string().describe("이메일 ID"),
    },
    handler: async ({ messageId }: { messageId: string }) => {
      const { gmail } = await getGoogleServices();

      const response = await gmail.users.messages.get({
        userId: "me",
        id: messageId,
        format: "full",
      });

      const headers = response.data.payload?.headers || [];
      const parts = response.data.payload?.parts || [];

      let body = "";
      const textPart = parts.find((p) => p.mimeType === "text/plain");
      if (textPart?.body?.data) {
        body = Buffer.from(textPart.body.data, "base64").toString("utf-8");
      } else if (response.data.payload?.body?.data) {
        body = Buffer.from(response.data.payload.body.data, "base64").toString("utf-8");
      }

      // 첨부파일 목록
      const attachments = parts
        .filter((p) => p.filename && p.body?.attachmentId)
        .map((p) => ({
          filename: p.filename,
          mimeType: p.mimeType,
          attachmentId: p.body?.attachmentId,
          size: p.body?.size,
        }));

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
    description: "이메일을 발송합니다",
    schema: {
      to: z.string().describe("받는 사람 이메일"),
      subject: z.string().describe("제목"),
      body: z.string().describe("본문 내용"),
      cc: z.string().optional().describe("참조 (CC)"),
      bcc: z.string().optional().describe("숨은 참조 (BCC)"),
    },
    handler: async ({ to, subject, body, cc, bcc }: { to: string; subject: string; body: string; cc?: string; bcc?: string }) => {
      const { gmail } = await getGoogleServices();

      const messageParts = [
        `To: ${to}`,
        cc ? `Cc: ${cc}` : "",
        bcc ? `Bcc: ${bcc}` : "",
        `Subject: =?UTF-8?B?${Buffer.from(subject).toString("base64")}?=`,
        "Content-Type: text/plain; charset=utf-8",
        "",
        body,
      ].filter(Boolean).join("\n");

      const encodedMessage = Buffer.from(messageParts)
        .toString("base64")
        .replace(/\+/g, "-")
        .replace(/\//g, "_")
        .replace(/=+$/, "");

      const response = await gmail.users.messages.send({
        userId: "me",
        requestBody: {
          raw: encodedMessage,
        },
      });

      return {
        success: true,
        messageId: response.data.id,
        message: `이메일이 ${to}에게 발송되었습니다.`,
      };
    },
  },

  gmail_draft_create: {
    description: "이메일 초안을 작성합니다 (발송하지 않음)",
    schema: {
      to: z.string().describe("받는 사람 이메일"),
      subject: z.string().describe("제목"),
      body: z.string().describe("본문 내용"),
      cc: z.string().optional().describe("참조 (CC)"),
    },
    handler: async ({ to, subject, body, cc }: { to: string; subject: string; body: string; cc?: string }) => {
      const { gmail } = await getGoogleServices();

      const messageParts = [
        `To: ${to}`,
        cc ? `Cc: ${cc}` : "",
        `Subject: =?UTF-8?B?${Buffer.from(subject).toString("base64")}?=`,
        "Content-Type: text/plain; charset=utf-8",
        "",
        body,
      ].filter(Boolean).join("\n");

      const encodedMessage = Buffer.from(messageParts)
        .toString("base64")
        .replace(/\+/g, "-")
        .replace(/\//g, "_")
        .replace(/=+$/, "");

      const response = await gmail.users.drafts.create({
        userId: "me",
        requestBody: {
          message: {
            raw: encodedMessage,
          },
        },
      });

      return {
        success: true,
        draftId: response.data.id,
        message: "초안이 저장되었습니다.",
      };
    },
  },

  gmail_draft_list: {
    description: "저장된 초안 목록을 조회합니다",
    schema: {
      maxResults: z.number().optional().default(10).describe("최대 결과 수"),
    },
    handler: async ({ maxResults }: { maxResults: number }) => {
      const { gmail } = await getGoogleServices();

      const response = await gmail.users.drafts.list({
        userId: "me",
        maxResults,
      });

      const drafts = response.data.drafts || [];

      const details = await Promise.all(
        drafts.slice(0, 10).map(async (draft) => {
          const detail = await gmail.users.drafts.get({
            userId: "me",
            id: draft.id!,
            format: "metadata",
          });

          const headers = detail.data.message?.payload?.headers || [];
          return {
            draftId: draft.id,
            to: headers.find((h) => h.name === "To")?.value,
            subject: headers.find((h) => h.name === "Subject")?.value,
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
    description: "저장된 초안을 발송합니다",
    schema: {
      draftId: z.string().describe("초안 ID"),
    },
    handler: async ({ draftId }: { draftId: string }) => {
      const { gmail } = await getGoogleServices();

      const response = await gmail.users.drafts.send({
        userId: "me",
        requestBody: {
          id: draftId,
        },
      });

      return {
        success: true,
        messageId: response.data.id,
        message: "초안이 발송되었습니다.",
      };
    },
  },

  gmail_draft_delete: {
    description: "초안을 삭제합니다",
    schema: {
      draftId: z.string().describe("초안 ID"),
    },
    handler: async ({ draftId }: { draftId: string }) => {
      const { gmail } = await getGoogleServices();

      await gmail.users.drafts.delete({
        userId: "me",
        id: draftId,
      });

      return {
        success: true,
        message: "초안이 삭제되었습니다.",
      };
    },
  },

  gmail_labels_list: {
    description: "라벨 목록을 조회합니다",
    schema: {},
    handler: async () => {
      const { gmail } = await getGoogleServices();

      const response = await gmail.users.labels.list({
        userId: "me",
      });

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
    description: "이메일에 라벨을 추가합니다",
    schema: {
      messageId: z.string().describe("이메일 ID"),
      labelIds: z.array(z.string()).describe("추가할 라벨 ID 목록"),
    },
    handler: async ({ messageId, labelIds }: { messageId: string; labelIds: string[] }) => {
      const { gmail } = await getGoogleServices();

      await gmail.users.messages.modify({
        userId: "me",
        id: messageId,
        requestBody: {
          addLabelIds: labelIds,
        },
      });

      return {
        success: true,
        message: "라벨이 추가되었습니다.",
      };
    },
  },

  gmail_labels_remove: {
    description: "이메일에서 라벨을 제거합니다",
    schema: {
      messageId: z.string().describe("이메일 ID"),
      labelIds: z.array(z.string()).describe("제거할 라벨 ID 목록"),
    },
    handler: async ({ messageId, labelIds }: { messageId: string; labelIds: string[] }) => {
      const { gmail } = await getGoogleServices();

      await gmail.users.messages.modify({
        userId: "me",
        id: messageId,
        requestBody: {
          removeLabelIds: labelIds,
        },
      });

      return {
        success: true,
        message: "라벨이 제거되었습니다.",
      };
    },
  },

  gmail_attachment_get: {
    description: "이메일 첨부파일 정보를 가져옵니다",
    schema: {
      messageId: z.string().describe("이메일 ID"),
      attachmentId: z.string().describe("첨부파일 ID"),
    },
    handler: async ({ messageId, attachmentId }: { messageId: string; attachmentId: string }) => {
      const { gmail } = await getGoogleServices();

      const response = await gmail.users.messages.attachments.get({
        userId: "me",
        messageId,
        id: attachmentId,
      });

      return {
        attachmentId,
        size: response.data.size,
        data: response.data.data?.slice(0, 1000) + "...", // 미리보기만
        message: "첨부파일 데이터를 가져왔습니다. (base64 인코딩)",
      };
    },
  },

  gmail_trash: {
    description: "이메일을 휴지통으로 이동합니다",
    schema: {
      messageId: z.string().describe("이메일 ID"),
    },
    handler: async ({ messageId }: { messageId: string }) => {
      const { gmail } = await getGoogleServices();

      await gmail.users.messages.trash({
        userId: "me",
        id: messageId,
      });

      return {
        success: true,
        message: "이메일이 휴지통으로 이동되었습니다.",
      };
    },
  },

  gmail_untrash: {
    description: "이메일을 휴지통에서 복원합니다",
    schema: {
      messageId: z.string().describe("이메일 ID"),
    },
    handler: async ({ messageId }: { messageId: string }) => {
      const { gmail } = await getGoogleServices();

      await gmail.users.messages.untrash({
        userId: "me",
        id: messageId,
      });

      return {
        success: true,
        message: "이메일이 복원되었습니다.",
      };
    },
  },

  gmail_mark_read: {
    description: "이메일을 읽음으로 표시합니다",
    schema: {
      messageId: z.string().describe("이메일 ID"),
    },
    handler: async ({ messageId }: { messageId: string }) => {
      const { gmail } = await getGoogleServices();

      await gmail.users.messages.modify({
        userId: "me",
        id: messageId,
        requestBody: {
          removeLabelIds: ["UNREAD"],
        },
      });

      return {
        success: true,
        message: "읽음으로 표시되었습니다.",
      };
    },
  },

  gmail_mark_unread: {
    description: "이메일을 읽지 않음으로 표시합니다",
    schema: {
      messageId: z.string().describe("이메일 ID"),
    },
    handler: async ({ messageId }: { messageId: string }) => {
      const { gmail } = await getGoogleServices();

      await gmail.users.messages.modify({
        userId: "me",
        id: messageId,
        requestBody: {
          addLabelIds: ["UNREAD"],
        },
      });

      return {
        success: true,
        message: "읽지 않음으로 표시되었습니다.",
      };
    },
  },
};
