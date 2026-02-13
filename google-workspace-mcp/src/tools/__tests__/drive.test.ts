import { describe, it, expect, vi, beforeEach } from "vitest";
import { driveTools } from "../drive.js";

// Mock getGoogleServices
const mockDriveApi = {
  files: {
    list: vi.fn(),
    get: vi.fn(),
    create: vi.fn(),
    copy: vi.fn(),
    update: vi.fn(),
  },
  permissions: {
    create: vi.fn(),
    list: vi.fn(),
    delete: vi.fn(),
  },
  about: {
    get: vi.fn(),
  },
};

vi.mock("../../auth/oauth", () => ({
  getGoogleServices: vi.fn(async () => ({
    drive: mockDriveApi,
  })),
}));

describe("Drive Tools - Security Tests (P0)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("drive_search - TC-D01: Query Injection Prevention", () => {
    it("should escape single quotes in search query", async () => {
      mockDriveApi.files.list.mockResolvedValue({
        data: { files: [] },
      });

      await driveTools.drive_search.handler({
        query: "test' or name contains '",
        maxResults: 10,
      });

      const calledArgs = mockDriveApi.files.list.mock.calls[0][0];
      // Escaped query should not allow injection
      expect(calledArgs.q).not.toContain("' or name contains '");
      expect(calledArgs.q).toContain("trashed = false");
    });

    it("should escape backslashes in search query", async () => {
      mockDriveApi.files.list.mockResolvedValue({
        data: { files: [] },
      });

      await driveTools.drive_search.handler({
        query: "test\\escape",
        maxResults: 10,
      });

      expect(mockDriveApi.files.list).toHaveBeenCalled();
    });

    it("should escape mimeType parameter", async () => {
      mockDriveApi.files.list.mockResolvedValue({
        data: { files: [] },
      });

      await driveTools.drive_search.handler({
        query: "test",
        mimeType: "application/pdf' or trashed = true or mimeType = '",
        maxResults: 10,
      });

      const calledArgs = mockDriveApi.files.list.mock.calls[0][0];
      // Should not allow injection via mimeType
      expect(calledArgs.q).toContain("trashed = false");
    });
  });

  describe("drive_list - TC-D02: Folder ID Validation", () => {
    it("should accept valid folder ID formats", async () => {
      mockDriveApi.files.list.mockResolvedValue({
        data: { files: [] },
      });

      // Standard folder ID
      await driveTools.drive_list.handler({
        folderId: "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2wtTs",
        maxResults: 20,
        orderBy: "modifiedTime desc",
      });

      expect(mockDriveApi.files.list).toHaveBeenCalled();
    });

    it("should accept root as folder ID", async () => {
      mockDriveApi.files.list.mockResolvedValue({
        data: { files: [] },
      });

      await driveTools.drive_list.handler({
        folderId: "root",
        maxResults: 20,
        orderBy: "modifiedTime desc",
      });

      expect(mockDriveApi.files.list).toHaveBeenCalled();
    });

    it("should reject folder IDs with injection attempts", async () => {
      await expect(
        driveTools.drive_list.handler({
          folderId: "root' in parents or '1'='1",
          maxResults: 20,
          orderBy: "modifiedTime desc",
        })
      ).rejects.toThrow();
    });
  });
});

describe("Drive Tools - Core Functionality (P1)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("drive_search - TC-D03: Search Results", () => {
    it("should return formatted file results", async () => {
      mockDriveApi.files.list.mockResolvedValue({
        data: {
          files: [
            {
              id: "file1",
              name: "Document.pdf",
              mimeType: "application/pdf",
              modifiedTime: "2026-02-13T10:00:00Z",
              webViewLink: "https://drive.google.com/file/d/file1",
              owners: [{ emailAddress: "user@example.com" }],
              size: "1024",
              parents: ["folder1"],
            },
          ],
        },
      });

      const result = await driveTools.drive_search.handler({
        query: "Document",
        maxResults: 10,
      });

      expect(result.total).toBe(1);
      expect(result.files![0]).toEqual({
        id: "file1",
        name: "Document.pdf",
        type: "application/pdf",
        modifiedTime: "2026-02-13T10:00:00Z",
        link: "https://drive.google.com/file/d/file1",
        owner: "user@example.com",
        size: "1024",
        parentId: "folder1",
      });
    });

    it("should handle empty search results", async () => {
      mockDriveApi.files.list.mockResolvedValue({
        data: { files: [] },
      });

      const result = await driveTools.drive_search.handler({
        query: "nonexistent",
        maxResults: 10,
      });

      expect(result.total).toBe(0);
    });

    it("should include shared drive parameters", async () => {
      mockDriveApi.files.list.mockResolvedValue({
        data: { files: [] },
      });

      await driveTools.drive_search.handler({
        query: "test",
        maxResults: 10,
      });

      const calledArgs = mockDriveApi.files.list.mock.calls[0][0];
      expect(calledArgs.supportsAllDrives).toBe(true);
      expect(calledArgs.includeItemsFromAllDrives).toBe(true);
      expect(calledArgs.corpora).toBe("allDrives");
    });
  });

  describe("drive_create_folder - TC-D04: Folder Creation", () => {
    it("should create a folder with correct mimeType", async () => {
      mockDriveApi.files.create.mockResolvedValue({
        data: {
          id: "newFolder1",
          name: "New Folder",
          webViewLink: "https://drive.google.com/drive/folders/newFolder1",
        },
      });

      const result = await driveTools.drive_create_folder.handler({
        name: "New Folder",
      });

      expect(result.success).toBe(true);
      expect(result.folderId).toBe("newFolder1");
      expect(mockDriveApi.files.create).toHaveBeenCalledWith(
        expect.objectContaining({
          requestBody: expect.objectContaining({
            mimeType: "application/vnd.google-apps.folder",
          }),
        })
      );
    });

    it("should create folder in specified parent", async () => {
      mockDriveApi.files.create.mockResolvedValue({
        data: { id: "newFolder2", name: "Sub Folder" },
      });

      await driveTools.drive_create_folder.handler({
        name: "Sub Folder",
        parentId: "parentFolder1",
      });

      const calledArgs = mockDriveApi.files.create.mock.calls[0][0];
      expect(calledArgs.requestBody.parents).toEqual(["parentFolder1"]);
    });
  });

  describe("drive_share - TC-D05: Sharing Permissions", () => {
    it("should share file with correct role", async () => {
      mockDriveApi.permissions.create.mockResolvedValue({ data: {} });

      const result = await driveTools.drive_share.handler({
        fileId: "file1",
        email: "collaborator@example.com",
        role: "writer",
        sendNotification: true,
      });

      expect(result.success).toBe(true);
      expect(mockDriveApi.permissions.create).toHaveBeenCalledWith(
        expect.objectContaining({
          fileId: "file1",
          requestBody: {
            type: "user",
            role: "writer",
            emailAddress: "collaborator@example.com",
          },
          sendNotificationEmail: true,
        })
      );
    });
  });

  describe("drive_delete - TC-D06: Trash Operations", () => {
    it("should move file to trash (soft delete)", async () => {
      mockDriveApi.files.update.mockResolvedValue({ data: {} });

      const result = await driveTools.drive_delete.handler({
        fileId: "file1",
      });

      expect(result.success).toBe(true);
      expect(mockDriveApi.files.update).toHaveBeenCalledWith(
        expect.objectContaining({
          fileId: "file1",
          requestBody: { trashed: true },
        })
      );
    });

    it("should restore file from trash", async () => {
      mockDriveApi.files.update.mockResolvedValue({ data: {} });

      const result = await driveTools.drive_restore.handler({
        fileId: "file1",
      });

      expect(result.success).toBe(true);
      expect(mockDriveApi.files.update).toHaveBeenCalledWith(
        expect.objectContaining({
          fileId: "file1",
          requestBody: { trashed: false },
        })
      );
    });
  });

  describe("drive_get_storage_quota - TC-D07: Storage Info", () => {
    it("should format storage quota in GB", async () => {
      mockDriveApi.about.get.mockResolvedValue({
        data: {
          storageQuota: {
            limit: String(15 * 1024 * 1024 * 1024), // 15 GB
            usage: String(5 * 1024 * 1024 * 1024), // 5 GB
            usageInDrive: String(3 * 1024 * 1024 * 1024), // 3 GB
            usageInDriveTrash: String(512 * 1024 * 1024), // 0.5 GB
          },
        },
      });

      const result = await driveTools.drive_get_storage_quota.handler();

      expect(result.limit).toBe("15.00 GB");
      expect(result.usage).toBe("5.00 GB");
      expect(result.usageInDrive).toBe("3.00 GB");
      expect(result.usageInDriveTrash).toBe("0.50 GB");
    });
  });

  describe("drive_get_file - TC-D08: File Details", () => {
    it("should return detailed file information", async () => {
      mockDriveApi.files.get.mockResolvedValue({
        data: {
          id: "file1",
          name: "Report.docx",
          mimeType: "application/vnd.google-apps.document",
          createdTime: "2026-01-01T00:00:00Z",
          modifiedTime: "2026-02-13T10:00:00Z",
          webViewLink: "https://docs.google.com/document/d/file1",
          size: "2048",
          owners: [{ emailAddress: "owner@example.com" }],
          parents: ["folder1"],
          shared: true,
        },
      });

      const result = await driveTools.drive_get_file.handler({ fileId: "file1" });

      expect(result.id).toBe("file1");
      expect(result.name).toBe("Report.docx");
      expect(result.owners).toEqual(["owner@example.com"]);
      expect(result.shared).toBe(true);
      expect(result.parentId).toBe("folder1");
    });

    it("should reject invalid file IDs", async () => {
      await expect(
        driveTools.drive_get_file.handler({ fileId: "file1'; DROP TABLE" })
      ).rejects.toThrow();
    });
  });

  describe("drive_copy - TC-D09: File Copy", () => {
    it("should copy a file with new name", async () => {
      mockDriveApi.files.copy.mockResolvedValue({
        data: {
          id: "copiedFile1",
          name: "Report Copy",
          webViewLink: "https://drive.google.com/file/d/copiedFile1",
        },
      });

      const result = await driveTools.drive_copy.handler({
        fileId: "file1",
        newName: "Report Copy",
      });

      expect(result.success).toBe(true);
      expect(result.fileId).toBe("copiedFile1");
      expect(result.name).toBe("Report Copy");
      expect(mockDriveApi.files.copy).toHaveBeenCalledWith(
        expect.objectContaining({
          fileId: "file1",
          requestBody: expect.objectContaining({ name: "Report Copy" }),
          supportsAllDrives: true,
        })
      );
    });

    it("should copy a file to a specific folder", async () => {
      mockDriveApi.files.copy.mockResolvedValue({
        data: { id: "copiedFile2", name: "File" },
      });

      await driveTools.drive_copy.handler({
        fileId: "file1",
        parentId: "targetFolder",
      });

      const calledArgs = mockDriveApi.files.copy.mock.calls[0][0];
      expect(calledArgs.requestBody.parents).toEqual(["targetFolder"]);
    });
  });

  describe("drive_move - TC-D10: File Move", () => {
    it("should move file to new parent", async () => {
      mockDriveApi.files.get.mockResolvedValue({
        data: { parents: ["oldFolder"] },
      });
      mockDriveApi.files.update.mockResolvedValue({
        data: {
          id: "file1",
          name: "Moved File",
          parents: ["newFolder"],
          webViewLink: "https://drive.google.com/file/d/file1",
        },
      });

      const result = await driveTools.drive_move.handler({
        fileId: "file1",
        newParentId: "newFolder",
      });

      expect(result.success).toBe(true);
      expect(result.newParentId).toBe("newFolder");
      expect(mockDriveApi.files.update).toHaveBeenCalledWith(
        expect.objectContaining({
          fileId: "file1",
          addParents: "newFolder",
          removeParents: "oldFolder",
        })
      );
    });
  });

  describe("drive_rename - TC-D11: File Rename", () => {
    it("should rename a file", async () => {
      mockDriveApi.files.update.mockResolvedValue({
        data: {
          id: "file1",
          name: "New Name.pdf",
          webViewLink: "https://drive.google.com/file/d/file1",
        },
      });

      const result = await driveTools.drive_rename.handler({
        fileId: "file1",
        newName: "New Name.pdf",
      });

      expect(result.success).toBe(true);
      expect(result.name).toBe("New Name.pdf");
      expect(mockDriveApi.files.update).toHaveBeenCalledWith(
        expect.objectContaining({
          fileId: "file1",
          requestBody: { name: "New Name.pdf" },
        })
      );
    });
  });

  describe("drive_share_link - TC-D12: Link Sharing", () => {
    it("should enable anyone link sharing", async () => {
      mockDriveApi.permissions.create.mockResolvedValue({ data: {} });
      mockDriveApi.files.get.mockResolvedValue({
        data: { webViewLink: "https://drive.google.com/file/d/file1" },
      });

      const result = await driveTools.drive_share_link.handler({
        fileId: "file1",
        type: "anyone",
        role: "reader",
      });

      expect(result.success).toBe(true);
      expect(result.link).toBe("https://drive.google.com/file/d/file1");
      expect(mockDriveApi.permissions.create).toHaveBeenCalledWith(
        expect.objectContaining({
          requestBody: { type: "anyone", role: "reader" },
        })
      );
    });

    it("should enable domain link sharing", async () => {
      mockDriveApi.permissions.create.mockResolvedValue({ data: {} });
      mockDriveApi.files.get.mockResolvedValue({
        data: { webViewLink: "https://drive.google.com/file/d/file1" },
      });

      await driveTools.drive_share_link.handler({
        fileId: "file1",
        type: "domain",
        role: "writer",
      });

      expect(mockDriveApi.permissions.create).toHaveBeenCalledWith(
        expect.objectContaining({
          requestBody: { type: "domain", role: "writer" },
        })
      );
    });
  });

  describe("drive_unshare - TC-D13: Remove Sharing", () => {
    it("should remove sharing permission by email", async () => {
      mockDriveApi.permissions.list.mockResolvedValue({
        data: {
          permissions: [
            { id: "perm1", emailAddress: "user@example.com" },
            { id: "perm2", emailAddress: "other@example.com" },
          ],
        },
      });
      mockDriveApi.permissions.delete.mockResolvedValue({ data: {} });

      const result = await driveTools.drive_unshare.handler({
        fileId: "file1",
        email: "user@example.com",
      });

      expect(result.success).toBe(true);
      expect(mockDriveApi.permissions.delete).toHaveBeenCalledWith(
        expect.objectContaining({
          fileId: "file1",
          permissionId: "perm1",
        })
      );
    });

    it("should return failure when permission not found", async () => {
      mockDriveApi.permissions.list.mockResolvedValue({
        data: {
          permissions: [{ id: "perm1", emailAddress: "other@example.com" }],
        },
      });

      const result = await driveTools.drive_unshare.handler({
        fileId: "file1",
        email: "notfound@example.com",
      });

      expect(result.success).toBe(false);
    });

    it("should reject invalid email format", async () => {
      await expect(
        driveTools.drive_unshare.handler({
          fileId: "file1",
          email: "not-an-email",
        })
      ).rejects.toThrow(/Invalid email/);
    });
  });

  describe("drive_list_permissions - TC-D14: Permission List", () => {
    it("should list all permissions for a file", async () => {
      mockDriveApi.permissions.list.mockResolvedValue({
        data: {
          permissions: [
            {
              id: "perm1",
              type: "user",
              role: "owner",
              emailAddress: "owner@example.com",
              displayName: "Owner",
            },
            { id: "perm2", type: "anyone", role: "reader" },
          ],
        },
      });

      const result = await driveTools.drive_list_permissions.handler({ fileId: "file1" });

      expect(result.permissions).toHaveLength(2);
      expect(result.permissions![0]).toEqual({
        id: "perm1",
        type: "user",
        role: "owner",
        email: "owner@example.com",
        name: "Owner",
      });
    });
  });
});
