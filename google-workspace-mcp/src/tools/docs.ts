import { z } from "zod";
import { getGoogleServices } from "../auth/oauth.js";

/**
 * Docs 도구 정의
 */
export const docsTools = {
  docs_create: {
    description: "새 Google Docs 문서를 생성합니다",
    schema: {
      title: z.string().describe("문서 제목"),
      content: z.string().optional().describe("초기 내용"),
      folderId: z.string().optional().describe("저장할 폴더 ID"),
    },
    handler: async ({ title, content, folderId }: { title: string; content?: string; folderId?: string }) => {
      const { docs, drive } = await getGoogleServices();

      // 빈 문서 생성
      const response = await docs.documents.create({
        requestBody: {
          title,
        },
      });

      const documentId = response.data.documentId!;

      // 내용 추가
      if (content) {
        await docs.documents.batchUpdate({
          documentId,
          requestBody: {
            requests: [
              {
                insertText: {
                  location: { index: 1 },
                  text: content,
                },
              },
            ],
          },
        });
      }

      // 폴더로 이동
      if (folderId) {
        const file = await drive.files.get({
          fileId: documentId,
          fields: "parents",
        });
        await drive.files.update({
          fileId: documentId,
          addParents: folderId,
          removeParents: file.data.parents?.join(","),
        });
      }

      // 링크 가져오기
      const file = await drive.files.get({
        fileId: documentId,
        fields: "webViewLink",
      });

      return {
        success: true,
        documentId,
        title,
        link: file.data.webViewLink,
        message: `문서 "${title}"이 생성되었습니다.`,
      };
    },
  },

  docs_read: {
    description: "Google Docs 문서의 내용을 읽습니다",
    schema: {
      documentId: z.string().describe("문서 ID"),
    },
    handler: async ({ documentId }: { documentId: string }) => {
      const { docs } = await getGoogleServices();

      const response = await docs.documents.get({
        documentId,
      });

      // 문서 내용 추출
      let content = "";
      const body = response.data.body?.content || [];

      for (const element of body) {
        if (element.paragraph) {
          for (const elem of element.paragraph.elements || []) {
            if (elem.textRun?.content) {
              content += elem.textRun.content;
            }
          }
        }
        if (element.table) {
          content += "[표]\n";
        }
      }

      return {
        documentId,
        title: response.data.title,
        content: content.slice(0, 10000),
        revisionId: response.data.revisionId,
      };
    },
  },

  docs_append: {
    description: "Google Docs 문서 끝에 내용을 추가합니다",
    schema: {
      documentId: z.string().describe("문서 ID"),
      content: z.string().describe("추가할 내용"),
    },
    handler: async ({ documentId, content }: { documentId: string; content: string }) => {
      const { docs } = await getGoogleServices();

      // 문서 끝 위치 확인
      const doc = await docs.documents.get({ documentId });
      const body = doc.data.body?.content || [];
      const lastElement = body[body.length - 1];
      const endIndex = lastElement?.endIndex || 1;

      await docs.documents.batchUpdate({
        documentId,
        requestBody: {
          requests: [
            {
              insertText: {
                location: { index: Math.max(1, endIndex - 1) },
                text: "\n" + content,
              },
            },
          ],
        },
      });

      return {
        success: true,
        message: "문서에 내용이 추가되었습니다.",
      };
    },
  },

  docs_prepend: {
    description: "Google Docs 문서 앞에 내용을 추가합니다",
    schema: {
      documentId: z.string().describe("문서 ID"),
      content: z.string().describe("추가할 내용"),
    },
    handler: async ({ documentId, content }: { documentId: string; content: string }) => {
      const { docs } = await getGoogleServices();

      await docs.documents.batchUpdate({
        documentId,
        requestBody: {
          requests: [
            {
              insertText: {
                location: { index: 1 },
                text: content + "\n",
              },
            },
          ],
        },
      });

      return {
        success: true,
        message: "문서 앞에 내용이 추가되었습니다.",
      };
    },
  },

  docs_replace_text: {
    description: "문서에서 특정 텍스트를 찾아 바꿉니다",
    schema: {
      documentId: z.string().describe("문서 ID"),
      searchText: z.string().describe("찾을 텍스트"),
      replaceText: z.string().describe("바꿀 텍스트"),
      matchCase: z.boolean().optional().default(false).describe("대소문자 구분"),
    },
    handler: async ({ documentId, searchText, replaceText, matchCase }: {
      documentId: string;
      searchText: string;
      replaceText: string;
      matchCase: boolean;
    }) => {
      const { docs } = await getGoogleServices();

      const response = await docs.documents.batchUpdate({
        documentId,
        requestBody: {
          requests: [
            {
              replaceAllText: {
                containsText: {
                  text: searchText,
                  matchCase,
                },
                replaceText,
              },
            },
          ],
        },
      });

      const occurrences = response.data.replies?.[0]?.replaceAllText?.occurrencesChanged || 0;

      return {
        success: true,
        occurrencesChanged: occurrences,
        message: `${occurrences}개의 텍스트가 변경되었습니다.`,
      };
    },
  },

  docs_insert_heading: {
    description: "문서에 제목(헤딩)을 추가합니다",
    schema: {
      documentId: z.string().describe("문서 ID"),
      text: z.string().describe("제목 텍스트"),
      level: z.number().min(1).max(6).default(1).describe("제목 레벨 (1-6)"),
    },
    handler: async ({ documentId, text, level }: { documentId: string; text: string; level: number }) => {
      const { docs } = await getGoogleServices();

      const doc = await docs.documents.get({ documentId });
      const body = doc.data.body?.content || [];
      const lastElement = body[body.length - 1];
      const endIndex = lastElement?.endIndex || 1;
      const insertIndex = Math.max(1, endIndex - 1);

      const headingType = `HEADING_${level}` as any;

      await docs.documents.batchUpdate({
        documentId,
        requestBody: {
          requests: [
            {
              insertText: {
                location: { index: insertIndex },
                text: "\n" + text + "\n",
              },
            },
            {
              updateParagraphStyle: {
                range: {
                  startIndex: insertIndex + 1,
                  endIndex: insertIndex + 1 + text.length,
                },
                paragraphStyle: {
                  namedStyleType: headingType,
                },
                fields: "namedStyleType",
              },
            },
          ],
        },
      });

      return {
        success: true,
        message: `제목(H${level})이 추가되었습니다.`,
      };
    },
  },

  docs_insert_table: {
    description: "문서에 표를 추가합니다",
    schema: {
      documentId: z.string().describe("문서 ID"),
      rows: z.number().min(1).max(20).describe("행 수"),
      columns: z.number().min(1).max(10).describe("열 수"),
    },
    handler: async ({ documentId, rows, columns }: { documentId: string; rows: number; columns: number }) => {
      const { docs } = await getGoogleServices();

      const doc = await docs.documents.get({ documentId });
      const body = doc.data.body?.content || [];
      const lastElement = body[body.length - 1];
      const endIndex = lastElement?.endIndex || 1;

      await docs.documents.batchUpdate({
        documentId,
        requestBody: {
          requests: [
            {
              insertTable: {
                location: { index: Math.max(1, endIndex - 1) },
                rows,
                columns,
              },
            },
          ],
        },
      });

      return {
        success: true,
        message: `${rows}x${columns} 표가 추가되었습니다.`,
      };
    },
  },

  docs_get_comments: {
    description: "문서의 댓글을 조회합니다",
    schema: {
      documentId: z.string().describe("문서 ID"),
    },
    handler: async ({ documentId }: { documentId: string }) => {
      const { drive } = await getGoogleServices();

      const response = await drive.comments.list({
        fileId: documentId,
        fields: "comments(id, content, author, createdTime, resolved, replies)",
      });

      return {
        comments: response.data.comments?.map((c) => ({
          id: c.id,
          content: c.content,
          author: c.author?.displayName,
          createdTime: c.createdTime,
          resolved: c.resolved,
          replies: c.replies?.map((r) => ({
            content: r.content,
            author: r.author?.displayName,
          })),
        })),
      };
    },
  },

  docs_add_comment: {
    description: "문서에 댓글을 추가합니다",
    schema: {
      documentId: z.string().describe("문서 ID"),
      content: z.string().describe("댓글 내용"),
    },
    handler: async ({ documentId, content }: { documentId: string; content: string }) => {
      const { drive } = await getGoogleServices();

      const response = await drive.comments.create({
        fileId: documentId,
        requestBody: {
          content,
        },
        fields: "id, content, createdTime",
      });

      return {
        success: true,
        commentId: response.data.id,
        message: "댓글이 추가되었습니다.",
      };
    },
  },
};
