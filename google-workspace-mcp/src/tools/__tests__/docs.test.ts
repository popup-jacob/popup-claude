import { describe, it, expect, vi, beforeEach } from "vitest";
import { docsTools } from "../docs.js";

// Mock getGoogleServices
const mockDocsApi = {
  documents: {
    create: vi.fn(),
    get: vi.fn(),
    batchUpdate: vi.fn(),
  },
};

const mockDriveApi = {
  files: {
    copy: vi.fn(),
    update: vi.fn(),
    get: vi.fn(),
  },
  comments: {
    list: vi.fn(),
    create: vi.fn(),
  },
};

vi.mock("../../auth/oauth", () => ({
  getGoogleServices: vi.fn(async () => ({
    docs: mockDocsApi,
    drive: mockDriveApi,
  })),
}));

describe("Docs Tools - Core Functionality", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("docs_create - TC-DC01: Document Creation", () => {
    it("should create a new document with title only", async () => {
      mockDocsApi.documents.create.mockResolvedValue({
        data: {
          documentId: "doc123",
          title: "New Document",
        },
      });

      mockDriveApi.files.get.mockResolvedValue({
        data: {
          webViewLink: "https://docs.google.com/document/d/doc123",
        },
      });

      const result = await docsTools.docs_create.handler({
        title: "New Document",
      });

      expect(result.success).toBe(true);
      expect(result.documentId).toBe("doc123");
      expect(mockDocsApi.documents.create).toHaveBeenCalledWith({
        requestBody: {
          title: "New Document",
        },
      });
    });

    it("should create document with initial content", async () => {
      mockDocsApi.documents.create.mockResolvedValue({
        data: {
          documentId: "doc456",
          title: "Document with Content",
        },
      });

      mockDocsApi.documents.batchUpdate.mockResolvedValue({ data: {} });

      mockDriveApi.files.get.mockResolvedValue({
        data: {
          webViewLink: "https://docs.google.com/document/d/doc456",
        },
      });

      const result = await docsTools.docs_create.handler({
        title: "Document with Content",
        content: "Initial paragraph content",
      });

      expect(result.success).toBe(true);
      expect(mockDocsApi.documents.create).toHaveBeenCalled();
      expect(mockDocsApi.documents.batchUpdate).toHaveBeenCalledWith({
        documentId: "doc456",
        requestBody: {
          requests: [
            {
              insertText: {
                text: "Initial paragraph content",
                location: { index: 1 },
              },
            },
          ],
        },
      });
    });

    it("should move document to folder if folderId is provided", async () => {
      mockDocsApi.documents.create.mockResolvedValue({
        data: {
          documentId: "doc789",
          title: "Document in Folder",
        },
      });

      mockDriveApi.files.get.mockResolvedValue({
        data: {
          parents: ["oldFolder"],
          webViewLink: "https://docs.google.com/document/d/doc789",
        },
      });

      mockDriveApi.files.update.mockResolvedValue({ data: {} });

      const result = await docsTools.docs_create.handler({
        title: "Document in Folder",
        folderId: "folder123",
      });

      expect(result.success).toBe(true);
      expect(mockDriveApi.files.update).toHaveBeenCalledWith(
        expect.objectContaining({
          fileId: "doc789",
          addParents: "folder123",
        })
      );
    });
  });

  describe("docs_read - TC-DC02: Document Reading", () => {
    it("should read document content and return text", async () => {
      mockDocsApi.documents.get.mockResolvedValue({
        data: {
          documentId: "doc123",
          title: "Test Document",
          body: {
            content: [
              {
                paragraph: {
                  elements: [{ textRun: { content: "First paragraph\n" } }],
                },
              },
              {
                paragraph: {
                  elements: [{ textRun: { content: "Second paragraph\n" } }],
                },
              },
            ],
          },
        },
      });

      const result = await docsTools.docs_read.handler({
        documentId: "doc123",
      });

      expect(result.documentId).toBe("doc123");
      expect(result.title).toBe("Test Document");
      expect(result.content).toContain("First paragraph");
      expect(result.content).toContain("Second paragraph");
    });

    it("should handle empty document", async () => {
      mockDocsApi.documents.get.mockResolvedValue({
        data: {
          documentId: "doc_empty",
          title: "Empty Document",
          body: {
            content: [],
          },
        },
      });

      const result = await docsTools.docs_read.handler({
        documentId: "doc_empty",
      });

      expect(result.documentId).toBe("doc_empty");
      expect(result.content).toBe("");
    });
  });

  describe("docs_append - TC-DC03: Content Appending", () => {
    it("should append content to end of document", async () => {
      mockDocsApi.documents.get.mockResolvedValue({
        data: {
          body: {
            content: [{ endIndex: 10 }, { endIndex: 50 }],
          },
        },
      });

      mockDocsApi.documents.batchUpdate.mockResolvedValue({ data: {} });

      const result = await docsTools.docs_append.handler({
        documentId: "doc123",
        content: "Appended content",
      });

      expect(result.success).toBe(true);
      expect(mockDocsApi.documents.batchUpdate).toHaveBeenCalled();
    });
  });

  describe("docs_prepend - TC-DC04: Content Prepending", () => {
    it("should prepend content to beginning of document", async () => {
      mockDocsApi.documents.batchUpdate.mockResolvedValue({ data: {} });

      const result = await docsTools.docs_prepend.handler({
        documentId: "doc123",
        content: "Prepended text",
      });

      expect(result.success).toBe(true);
      expect(mockDocsApi.documents.batchUpdate).toHaveBeenCalledWith({
        documentId: "doc123",
        requestBody: {
          requests: [
            {
              insertText: {
                text: "Prepended text\n",
                location: { index: 1 },
              },
            },
          ],
        },
      });
    });
  });

  describe("docs_replace_text - TC-DC05: Text Replacement", () => {
    it("should find and replace text", async () => {
      mockDocsApi.documents.batchUpdate.mockResolvedValue({
        data: {
          replies: [
            {
              replaceAllText: {
                occurrencesChanged: 3,
              },
            },
          ],
        },
      });

      const result = await docsTools.docs_replace_text.handler({
        documentId: "doc123",
        searchText: "old",
        replaceText: "new",
        matchCase: false,
      });

      expect(result.success).toBe(true);
      expect(result.occurrencesChanged).toBe(3);
      expect(mockDocsApi.documents.batchUpdate).toHaveBeenCalledWith({
        documentId: "doc123",
        requestBody: {
          requests: [
            {
              replaceAllText: {
                containsText: {
                  text: "old",
                  matchCase: false,
                },
                replaceText: "new",
              },
            },
          ],
        },
      });
    });
  });
});

/* ------------------------------------------------------------------ */
/*  TC-DOC-003 ~ TC-DOC-013: Docs additional coverage tests           */
/* ------------------------------------------------------------------ */

describe("Docs Tools - TC-DOC-005: docs_read with tables", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should output [table] marker for table elements", async () => {
    mockDocsApi.documents.get.mockResolvedValue({
      data: {
        documentId: "doc_table",
        title: "Doc With Table",
        body: {
          content: [
            {
              paragraph: {
                elements: [{ textRun: { content: "Before table\n" } }],
              },
            },
            {
              table: { rows: 2, columns: 2 },
            },
            {
              paragraph: {
                elements: [{ textRun: { content: "After table\n" } }],
              },
            },
          ],
        },
      },
    });

    const result = await docsTools.docs_read.handler({ documentId: "doc_table" });

    expect(result.documentId).toBe("doc_table");
    expect(result.title).toBe("Doc With Table");
    expect(result.content).toContain("Before table");
    expect(result.content).toContain("[table]");
    expect(result.content).toContain("After table");
  });
});

describe("Docs Tools - TC-DOC-009: docs_replace_text case-sensitive", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should pass matchCase=true for case-sensitive replacement", async () => {
    mockDocsApi.documents.batchUpdate.mockResolvedValue({
      data: {
        replies: [{ replaceAllText: { occurrencesChanged: 2 } }],
      },
    });

    const result = await docsTools.docs_replace_text.handler({
      documentId: "doc_case",
      searchText: "Hello",
      replaceText: "Hi",
      matchCase: true,
    });

    expect(result.success).toBe(true);
    expect(result.occurrencesChanged).toBe(2);
    expect(mockDocsApi.documents.batchUpdate).toHaveBeenCalledWith({
      documentId: "doc_case",
      requestBody: {
        requests: [
          {
            replaceAllText: {
              containsText: { text: "Hello", matchCase: true },
              replaceText: "Hi",
            },
          },
        ],
      },
    });
  });

  it("should handle zero occurrences changed", async () => {
    mockDocsApi.documents.batchUpdate.mockResolvedValue({
      data: {
        replies: [{ replaceAllText: { occurrencesChanged: 0 } }],
      },
    });

    const result = await docsTools.docs_replace_text.handler({
      documentId: "doc_zero",
      searchText: "NonExistent",
      replaceText: "Replacement",
      matchCase: true,
    });

    expect(result.success).toBe(true);
    expect(result.occurrencesChanged).toBe(0);
  });
});

describe("Docs Tools - TC-DOC-012: docs_read empty document edge cases", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should return empty content for document with only structural elements", async () => {
    mockDocsApi.documents.get.mockResolvedValue({
      data: {
        documentId: "doc_struct",
        title: "Structural Only",
        body: {
          content: [
            { sectionBreak: { sectionStyle: {} } },
          ],
        },
      },
    });

    const result = await docsTools.docs_read.handler({ documentId: "doc_struct" });

    expect(result.documentId).toBe("doc_struct");
    expect(result.content).toBe("");
  });

  it("should handle document with paragraph but no textRun elements", async () => {
    mockDocsApi.documents.get.mockResolvedValue({
      data: {
        documentId: "doc_no_text",
        title: "No Text",
        body: {
          content: [
            { paragraph: { elements: [] } },
          ],
        },
      },
    });

    const result = await docsTools.docs_read.handler({ documentId: "doc_no_text" });

    expect(result.documentId).toBe("doc_no_text");
    expect(result.content).toBe("");
  });
});

describe("Docs Tools - TC-DOC-013: docs_append content at end", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should append content using the last element endIndex", async () => {
    mockDocsApi.documents.get.mockResolvedValue({
      data: {
        body: {
          content: [{ endIndex: 5 }, { endIndex: 25 }, { endIndex: 50 }],
        },
      },
    });
    mockDocsApi.documents.batchUpdate.mockResolvedValue({ data: {} });

    const result = await docsTools.docs_append.handler({
      documentId: "doc_append",
      content: "Appended text",
    });

    expect(result.success).toBe(true);
    expect(mockDocsApi.documents.batchUpdate).toHaveBeenCalled();

    const batchCall = mockDocsApi.documents.batchUpdate.mock.calls[0][0];
    const insertReq = batchCall.requestBody.requests[0].insertText;
    expect(insertReq.text).toContain("Appended text");
  });
});

/* ------------------------------------------------------------------ */
/*  docs_insert_table / docs_get_comments / docs_add_comment           */
/* ------------------------------------------------------------------ */

describe("Docs Tools - docs_insert_table", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should insert a table at the end of the document", async () => {
    mockDocsApi.documents.get.mockResolvedValue({
      data: {
        body: {
          content: [{ endIndex: 5 }, { endIndex: 30 }],
        },
      },
    });
    mockDocsApi.documents.batchUpdate.mockResolvedValue({ data: {} });

    const result = await docsTools.docs_insert_table.handler({
      documentId: "doc_tbl",
      rows: 3,
      columns: 4,
    });

    expect(result.success).toBe(true);
    expect(result.message).toBe("3x4 table added.");

    const call = mockDocsApi.documents.batchUpdate.mock.calls[0][0];
    const insertTable = call.requestBody.requests[0].insertTable;
    expect(insertTable.rows).toBe(3);
    expect(insertTable.columns).toBe(4);
    expect(insertTable.location.index).toBe(29);
  });

  it("should default to index 1 when document body is empty", async () => {
    mockDocsApi.documents.get.mockResolvedValue({
      data: { body: { content: [] } },
    });
    mockDocsApi.documents.batchUpdate.mockResolvedValue({ data: {} });

    await docsTools.docs_insert_table.handler({
      documentId: "doc_tbl_empty",
      rows: 2,
      columns: 2,
    });

    const call = mockDocsApi.documents.batchUpdate.mock.calls[0][0];
    const insertTable = call.requestBody.requests[0].insertTable;
    expect(insertTable.location.index).toBeGreaterThanOrEqual(1);
  });
});

describe("Docs Tools - docs_get_comments", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should return formatted comments with replies", async () => {
    mockDriveApi.comments.list.mockResolvedValue({
      data: {
        comments: [
          {
            id: "c1",
            content: "Great work!",
            author: { displayName: "Alice" },
            createdTime: "2026-02-19T10:00:00Z",
            resolved: false,
            replies: [
              { content: "Thanks!", author: { displayName: "Bob" } },
            ],
          },
          {
            id: "c2",
            content: "Fix this",
            author: { displayName: "Charlie" },
            createdTime: "2026-02-19T11:00:00Z",
            resolved: true,
            replies: [],
          },
        ],
      },
    });

    const result = await docsTools.docs_get_comments.handler({
      documentId: "doc_comments",
    });

    expect(result.comments).toHaveLength(2);
    expect(result.comments![0].id).toBe("c1");
    expect(result.comments![0].content).toBe("Great work!");
    expect(result.comments![0].author).toBe("Alice");
    expect(result.comments![0].resolved).toBe(false);
    expect(result.comments![0].replies).toHaveLength(1);
    expect(result.comments![0].replies![0].content).toBe("Thanks!");
    expect(result.comments![1].resolved).toBe(true);
  });

  it("should handle document with no comments", async () => {
    mockDriveApi.comments.list.mockResolvedValue({
      data: { comments: [] },
    });

    const result = await docsTools.docs_get_comments.handler({
      documentId: "doc_no_comments",
    });

    expect(result.comments).toEqual([]);
  });
});

describe("Docs Tools - docs_add_comment", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should add a comment and return commentId", async () => {
    mockDriveApi.comments.create.mockResolvedValue({
      data: {
        id: "new_comment_1",
        content: "Review needed",
        createdTime: "2026-02-19T12:00:00Z",
      },
    });

    const result = await docsTools.docs_add_comment.handler({
      documentId: "doc_add_cmt",
      content: "Review needed",
    });

    expect(result.success).toBe(true);
    expect(result.commentId).toBe("new_comment_1");
    expect(result.message).toBe("Comment added.");

    expect(mockDriveApi.comments.create).toHaveBeenCalledWith({
      fileId: "doc_add_cmt",
      requestBody: { content: "Review needed" },
      fields: "id, content, createdTime",
    });
  });
});
