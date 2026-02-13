import { z } from "zod";
import { getGoogleServices } from "../auth/oauth.js";
import { withRetry } from "../utils/retry.js";
import { messages, msg } from "../utils/messages.js";

/**
 * Docs tool definitions
 */
export const docsTools = {
  docs_create: {
    description: "Create a new Google Docs document",
    schema: {
      title: z.string().describe("Document title"),
      content: z.string().optional().describe("Initial content"),
      folderId: z.string().optional().describe("Destination folder ID"),
    },
    handler: async ({
      title,
      content,
      folderId,
    }: {
      title: string;
      content?: string;
      folderId?: string;
    }) => {
      const { docs, drive } = await getGoogleServices();

      const response = await withRetry(() =>
        docs.documents.create({
          requestBody: {
            title,
          },
        })
      );

      const documentId = response.data.documentId!;

      if (content) {
        await withRetry(() =>
          docs.documents.batchUpdate({
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
          })
        );
      }

      if (folderId) {
        const file = await withRetry(() =>
          drive.files.get({
            fileId: documentId,
            fields: "parents",
          })
        );
        await withRetry(() =>
          drive.files.update({
            fileId: documentId,
            addParents: folderId,
            removeParents: file.data.parents?.join(","),
          })
        );
      }

      const file = await withRetry(() =>
        drive.files.get({
          fileId: documentId,
          fields: "webViewLink",
        })
      );

      return {
        success: true,
        documentId,
        title,
        link: file.data.webViewLink,
        message: msg(messages.docs.docCreated, title),
      };
    },
  },

  docs_read: {
    description: "Read the content of a Google Docs document",
    schema: {
      documentId: z.string().describe("Document ID"),
    },
    handler: async ({ documentId }: { documentId: string }) => {
      const { docs } = await getGoogleServices();

      const response = await withRetry(() =>
        docs.documents.get({
          documentId,
        })
      );

      // Extract document content
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
          content += "[table]\n";
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
    description: "Append content to the end of a Google Docs document",
    schema: {
      documentId: z.string().describe("Document ID"),
      content: z.string().describe("Content to append"),
    },
    handler: async ({ documentId, content }: { documentId: string; content: string }) => {
      const { docs } = await getGoogleServices();

      const doc = await withRetry(() => docs.documents.get({ documentId }));
      const body = doc.data.body?.content || [];
      const lastElement = body[body.length - 1];
      const endIndex = lastElement?.endIndex || 1;

      await withRetry(() =>
        docs.documents.batchUpdate({
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
        })
      );

      return {
        success: true,
        message: messages.docs.textAppended,
      };
    },
  },

  docs_prepend: {
    description: "Prepend content to the beginning of a Google Docs document",
    schema: {
      documentId: z.string().describe("Document ID"),
      content: z.string().describe("Content to prepend"),
    },
    handler: async ({ documentId, content }: { documentId: string; content: string }) => {
      const { docs } = await getGoogleServices();

      await withRetry(() =>
        docs.documents.batchUpdate({
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
        })
      );

      return {
        success: true,
        message: messages.docs.textInserted,
      };
    },
  },

  docs_replace_text: {
    description: "Find and replace text in a document",
    schema: {
      documentId: z.string().describe("Document ID"),
      searchText: z.string().describe("Text to find"),
      replaceText: z.string().describe("Replacement text"),
      matchCase: z.boolean().optional().default(false).describe("Case sensitive"),
    },
    handler: async ({
      documentId,
      searchText,
      replaceText,
      matchCase,
    }: {
      documentId: string;
      searchText: string;
      replaceText: string;
      matchCase: boolean;
    }) => {
      const { docs } = await getGoogleServices();

      const response = await withRetry(() =>
        docs.documents.batchUpdate({
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
        })
      );

      const occurrences = response.data.replies?.[0]?.replaceAllText?.occurrencesChanged || 0;

      return {
        success: true,
        occurrencesChanged: occurrences,
        message: messages.docs.contentReplaced,
      };
    },
  },

  docs_insert_heading: {
    description: "Add a heading to the document",
    schema: {
      documentId: z.string().describe("Document ID"),
      text: z.string().describe("Heading text"),
      level: z.number().min(1).max(6).default(1).describe("Heading level (1-6)"),
    },
    handler: async ({
      documentId,
      text,
      level,
    }: {
      documentId: string;
      text: string;
      level: number;
    }) => {
      const { docs } = await getGoogleServices();

      const doc = await withRetry(() => docs.documents.get({ documentId }));
      const body = doc.data.body?.content || [];
      const lastElement = body[body.length - 1];
      const endIndex = lastElement?.endIndex || 1;
      const insertIndex = Math.max(1, endIndex - 1);

      // FR-S3-07: Type assertion to string instead of any
      const headingType = `HEADING_${level}` as string;

      await withRetry(() =>
        docs.documents.batchUpdate({
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
        })
      );

      return {
        success: true,
        message: messages.docs.headerApplied,
      };
    },
  },

  docs_insert_table: {
    description: "Add a table to the document",
    schema: {
      documentId: z.string().describe("Document ID"),
      rows: z.number().min(1).max(20).describe("Number of rows"),
      columns: z.number().min(1).max(10).describe("Number of columns"),
    },
    handler: async ({
      documentId,
      rows,
      columns,
    }: {
      documentId: string;
      rows: number;
      columns: number;
    }) => {
      const { docs } = await getGoogleServices();

      const doc = await withRetry(() => docs.documents.get({ documentId }));
      const body = doc.data.body?.content || [];
      const lastElement = body[body.length - 1];
      const endIndex = lastElement?.endIndex || 1;

      await withRetry(() =>
        docs.documents.batchUpdate({
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
        })
      );

      return {
        success: true,
        message: `${rows}x${columns} table added.`,
      };
    },
  },

  docs_get_comments: {
    description: "List comments on a document",
    schema: {
      documentId: z.string().describe("Document ID"),
    },
    handler: async ({ documentId }: { documentId: string }) => {
      const { drive } = await getGoogleServices();

      const response = await withRetry(() =>
        drive.comments.list({
          fileId: documentId,
          fields: "comments(id, content, author, createdTime, resolved, replies)",
        })
      );

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
    description: "Add a comment to a document",
    schema: {
      documentId: z.string().describe("Document ID"),
      content: z.string().describe("Comment content"),
    },
    handler: async ({ documentId, content }: { documentId: string; content: string }) => {
      const { drive } = await getGoogleServices();

      const response = await withRetry(() =>
        drive.comments.create({
          fileId: documentId,
          requestBody: {
            content,
          },
          fields: "id, content, createdTime",
        })
      );

      return {
        success: true,
        commentId: response.data.id,
        message: "Comment added.",
      };
    },
  },
};
