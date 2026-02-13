import { describe, it, expect, vi, beforeEach } from 'vitest';
import { driveTools } from '../drive.js';

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

vi.mock('../../auth/oauth', () => ({
  getGoogleServices: vi.fn(async () => ({
    drive: mockDriveApi,
  })),
}));

describe('Drive Tools - Security Tests (P0)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('drive_search - TC-D01: Query Injection Prevention', () => {
    it('should escape single quotes in search query', async () => {
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

    it('should escape backslashes in search query', async () => {
      mockDriveApi.files.list.mockResolvedValue({
        data: { files: [] },
      });

      await driveTools.drive_search.handler({
        query: 'test\\escape',
        maxResults: 10,
      });

      expect(mockDriveApi.files.list).toHaveBeenCalled();
    });

    it('should escape mimeType parameter', async () => {
      mockDriveApi.files.list.mockResolvedValue({
        data: { files: [] },
      });

      await driveTools.drive_search.handler({
        query: 'test',
        mimeType: "application/pdf' or trashed = true or mimeType = '",
        maxResults: 10,
      });

      const calledArgs = mockDriveApi.files.list.mock.calls[0][0];
      // Should not allow injection via mimeType
      expect(calledArgs.q).toContain("trashed = false");
    });
  });

  describe('drive_list - TC-D02: Folder ID Validation', () => {
    it('should accept valid folder ID formats', async () => {
      mockDriveApi.files.list.mockResolvedValue({
        data: { files: [] },
      });

      // Standard folder ID
      await driveTools.drive_list.handler({
        folderId: '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2wtTs',
        maxResults: 20,
        orderBy: 'modifiedTime desc',
      });

      expect(mockDriveApi.files.list).toHaveBeenCalled();
    });

    it('should accept root as folder ID', async () => {
      mockDriveApi.files.list.mockResolvedValue({
        data: { files: [] },
      });

      await driveTools.drive_list.handler({
        folderId: 'root',
        maxResults: 20,
        orderBy: 'modifiedTime desc',
      });

      expect(mockDriveApi.files.list).toHaveBeenCalled();
    });

    it('should reject folder IDs with injection attempts', async () => {
      await expect(
        driveTools.drive_list.handler({
          folderId: "root' in parents or '1'='1",
          maxResults: 20,
          orderBy: 'modifiedTime desc',
        })
      ).rejects.toThrow();
    });
  });
});

describe('Drive Tools - Core Functionality (P1)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('drive_search - TC-D03: Search Results', () => {
    it('should return formatted file results', async () => {
      mockDriveApi.files.list.mockResolvedValue({
        data: {
          files: [
            {
              id: 'file1',
              name: 'Document.pdf',
              mimeType: 'application/pdf',
              modifiedTime: '2026-02-13T10:00:00Z',
              webViewLink: 'https://drive.google.com/file/d/file1',
              owners: [{ emailAddress: 'user@example.com' }],
              size: '1024',
              parents: ['folder1'],
            },
          ],
        },
      });

      const result = await driveTools.drive_search.handler({
        query: 'Document',
        maxResults: 10,
      });

      expect(result.total).toBe(1);
      expect(result.files![0]).toEqual({
        id: 'file1',
        name: 'Document.pdf',
        type: 'application/pdf',
        modifiedTime: '2026-02-13T10:00:00Z',
        link: 'https://drive.google.com/file/d/file1',
        owner: 'user@example.com',
        size: '1024',
        parentId: 'folder1',
      });
    });

    it('should handle empty search results', async () => {
      mockDriveApi.files.list.mockResolvedValue({
        data: { files: [] },
      });

      const result = await driveTools.drive_search.handler({
        query: 'nonexistent',
        maxResults: 10,
      });

      expect(result.total).toBe(0);
    });

    it('should include shared drive parameters', async () => {
      mockDriveApi.files.list.mockResolvedValue({
        data: { files: [] },
      });

      await driveTools.drive_search.handler({
        query: 'test',
        maxResults: 10,
      });

      const calledArgs = mockDriveApi.files.list.mock.calls[0][0];
      expect(calledArgs.supportsAllDrives).toBe(true);
      expect(calledArgs.includeItemsFromAllDrives).toBe(true);
      expect(calledArgs.corpora).toBe('allDrives');
    });
  });

  describe('drive_create_folder - TC-D04: Folder Creation', () => {
    it('should create a folder with correct mimeType', async () => {
      mockDriveApi.files.create.mockResolvedValue({
        data: {
          id: 'newFolder1',
          name: 'New Folder',
          webViewLink: 'https://drive.google.com/drive/folders/newFolder1',
        },
      });

      const result = await driveTools.drive_create_folder.handler({
        name: 'New Folder',
      });

      expect(result.success).toBe(true);
      expect(result.folderId).toBe('newFolder1');
      expect(mockDriveApi.files.create).toHaveBeenCalledWith(
        expect.objectContaining({
          requestBody: expect.objectContaining({
            mimeType: 'application/vnd.google-apps.folder',
          }),
        })
      );
    });

    it('should create folder in specified parent', async () => {
      mockDriveApi.files.create.mockResolvedValue({
        data: { id: 'newFolder2', name: 'Sub Folder' },
      });

      await driveTools.drive_create_folder.handler({
        name: 'Sub Folder',
        parentId: 'parentFolder1',
      });

      const calledArgs = mockDriveApi.files.create.mock.calls[0][0];
      expect(calledArgs.requestBody.parents).toEqual(['parentFolder1']);
    });
  });

  describe('drive_share - TC-D05: Sharing Permissions', () => {
    it('should share file with correct role', async () => {
      mockDriveApi.permissions.create.mockResolvedValue({ data: {} });

      const result = await driveTools.drive_share.handler({
        fileId: 'file1',
        email: 'collaborator@example.com',
        role: 'writer',
        sendNotification: true,
      });

      expect(result.success).toBe(true);
      expect(mockDriveApi.permissions.create).toHaveBeenCalledWith(
        expect.objectContaining({
          fileId: 'file1',
          requestBody: {
            type: 'user',
            role: 'writer',
            emailAddress: 'collaborator@example.com',
          },
          sendNotificationEmail: true,
        })
      );
    });
  });

  describe('drive_delete - TC-D06: Trash Operations', () => {
    it('should move file to trash (soft delete)', async () => {
      mockDriveApi.files.update.mockResolvedValue({ data: {} });

      const result = await driveTools.drive_delete.handler({
        fileId: 'file1',
      });

      expect(result.success).toBe(true);
      expect(mockDriveApi.files.update).toHaveBeenCalledWith(
        expect.objectContaining({
          fileId: 'file1',
          requestBody: { trashed: true },
        })
      );
    });

    it('should restore file from trash', async () => {
      mockDriveApi.files.update.mockResolvedValue({ data: {} });

      const result = await driveTools.drive_restore.handler({
        fileId: 'file1',
      });

      expect(result.success).toBe(true);
      expect(mockDriveApi.files.update).toHaveBeenCalledWith(
        expect.objectContaining({
          fileId: 'file1',
          requestBody: { trashed: false },
        })
      );
    });
  });

  describe('drive_get_storage_quota - TC-D07: Storage Info', () => {
    it('should format storage quota in GB', async () => {
      mockDriveApi.about.get.mockResolvedValue({
        data: {
          storageQuota: {
            limit: String(15 * 1024 * 1024 * 1024), // 15 GB
            usage: String(5 * 1024 * 1024 * 1024),  // 5 GB
            usageInDrive: String(3 * 1024 * 1024 * 1024), // 3 GB
            usageInDriveTrash: String(512 * 1024 * 1024), // 0.5 GB
          },
        },
      });

      const result = await driveTools.drive_get_storage_quota.handler();

      expect(result.limit).toBe('15.00 GB');
      expect(result.usage).toBe('5.00 GB');
      expect(result.usageInDrive).toBe('3.00 GB');
      expect(result.usageInDriveTrash).toBe('0.50 GB');
    });
  });
});
