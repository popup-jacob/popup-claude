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
