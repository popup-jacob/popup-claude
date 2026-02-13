import { z } from "zod";
import { getGoogleServices } from "../auth/oauth.js";
import { escapeDriveQuery, validateDriveId, validateEmail } from "../utils/sanitize.js";
import { withRetry } from "../utils/retry.js";
import { messages, msg } from "../utils/messages.js";

/**
 * Drive tools definition
 *
 * FR-S1-02: All user-supplied strings are escaped before interpolation
 *           into Drive API query language.
 */
export const driveTools = {
  drive_search: {
    description: "Search files in Google Drive",
    schema: {
      query: z.string().describe("Search query"),
      mimeType: z.string().optional().describe("File type filter"),
      maxResults: z.number().optional().default(10).describe("Maximum number of results"),
    },
    handler: async ({
      query,
      mimeType,
      maxResults,
    }: {
      query: string;
      mimeType?: string;
      maxResults: number;
    }) => {
      const { drive } = await getGoogleServices();

      // FR-S1-02: Escape user input to prevent Drive query injection
      let q = `name contains '${escapeDriveQuery(query)}' and trashed = false`;
      if (mimeType) {
        q += ` and mimeType = '${escapeDriveQuery(mimeType)}'`;
      }

      const response = await withRetry(() =>
        drive.files.list({
          q,
          pageSize: maxResults,
          fields: "files(id, name, mimeType, modifiedTime, webViewLink, owners, size, parents)",
          supportsAllDrives: true,
          includeItemsFromAllDrives: true,
          corpora: "allDrives",
        })
      );

      return {
        total: response.data.files?.length || 0,
        files: response.data.files?.map((file) => ({
          id: file.id,
          name: file.name,
          type: file.mimeType,
          modifiedTime: file.modifiedTime,
          link: file.webViewLink,
          owner: file.owners?.[0]?.emailAddress,
          size: file.size,
          parentId: file.parents?.[0],
        })),
      };
    },
  },

  drive_list: {
    description: "List files in a folder",
    schema: {
      folderId: z.string().optional().default("root").describe("Folder ID (default: root)"),
      maxResults: z.number().optional().default(20).describe("Maximum number of results"),
      orderBy: z.string().optional().default("modifiedTime desc").describe("Sort order"),
    },
    handler: async ({
      folderId,
      maxResults,
      orderBy,
    }: {
      folderId: string;
      maxResults: number;
      orderBy: string;
    }) => {
      // FR-S1-02: Validate folder ID format
      validateDriveId(folderId, "folderId");
      const { drive } = await getGoogleServices();

      const response = await withRetry(() =>
        drive.files.list({
          q: `'${escapeDriveQuery(folderId)}' in parents and trashed = false`,
          pageSize: maxResults,
          fields: "files(id, name, mimeType, modifiedTime, webViewLink, size)",
          orderBy,
          supportsAllDrives: true,
          includeItemsFromAllDrives: true,
          corpora: "allDrives",
        })
      );

      return {
        folderId,
        total: response.data.files?.length || 0,
        files: response.data.files?.map((file) => ({
          id: file.id,
          name: file.name,
          type: file.mimeType,
          modifiedTime: file.modifiedTime,
          link: file.webViewLink,
          size: file.size,
          isFolder: file.mimeType === "application/vnd.google-apps.folder",
        })),
      };
    },
  },

  drive_get_file: {
    description: "Get detailed file information",
    schema: {
      fileId: z.string().describe("File ID"),
    },
    handler: async ({ fileId }: { fileId: string }) => {
      validateDriveId(fileId, "fileId");
      const { drive } = await getGoogleServices();

      const response = await withRetry(() =>
        drive.files.get({
          fileId,
          fields:
            "id, name, mimeType, modifiedTime, createdTime, webViewLink, size, owners, parents, shared, permissions",
          supportsAllDrives: true,
        })
      );

      return {
        id: response.data.id,
        name: response.data.name,
        type: response.data.mimeType,
        createdTime: response.data.createdTime,
        modifiedTime: response.data.modifiedTime,
        link: response.data.webViewLink,
        size: response.data.size,
        owners: response.data.owners?.map((o) => o.emailAddress),
        parentId: response.data.parents?.[0],
        shared: response.data.shared,
      };
    },
  },

  drive_create_folder: {
    description: "Create a new folder",
    schema: {
      name: z.string().describe("Folder name"),
      parentId: z.string().optional().describe("Parent folder ID (default: root)"),
    },
    handler: async ({ name, parentId }: { name: string; parentId?: string }) => {
      if (parentId) validateDriveId(parentId, "parentId");
      const { drive } = await getGoogleServices();

      const response = await withRetry(() =>
        drive.files.create({
          requestBody: {
            name,
            mimeType: "application/vnd.google-apps.folder",
            parents: parentId ? [parentId] : undefined,
          },
          fields: "id, name, webViewLink",
          supportsAllDrives: true,
        })
      );

      return {
        success: true,
        folderId: response.data.id,
        name: response.data.name,
        link: response.data.webViewLink,
        message: msg(messages.drive.folderCreated, name),
      };
    },
  },

  drive_copy: {
    description: "Copy a file",
    schema: {
      fileId: z.string().describe("Source file ID"),
      newName: z.string().optional().describe("New file name"),
      parentId: z.string().optional().describe("Destination folder ID"),
    },
    handler: async ({
      fileId,
      newName,
      parentId,
    }: {
      fileId: string;
      newName?: string;
      parentId?: string;
    }) => {
      validateDriveId(fileId, "fileId");
      if (parentId) validateDriveId(parentId, "parentId");
      const { drive } = await getGoogleServices();

      const response = await withRetry(() =>
        drive.files.copy({
          fileId,
          requestBody: {
            name: newName,
            parents: parentId ? [parentId] : undefined,
          },
          fields: "id, name, webViewLink",
          supportsAllDrives: true,
        })
      );

      return {
        success: true,
        fileId: response.data.id,
        name: response.data.name,
        link: response.data.webViewLink,
        message: messages.drive.fileCopied,
      };
    },
  },

  drive_move: {
    description: "Move a file to another folder",
    schema: {
      fileId: z.string().describe("File ID"),
      newParentId: z.string().describe("Destination folder ID"),
    },
    handler: async ({ fileId, newParentId }: { fileId: string; newParentId: string }) => {
      validateDriveId(fileId, "fileId");
      validateDriveId(newParentId, "newParentId");
      const { drive } = await getGoogleServices();

      const file = await withRetry(() =>
        drive.files.get({
          fileId,
          fields: "parents",
          supportsAllDrives: true,
        })
      );

      const previousParents = file.data.parents?.join(",") || "";

      const response = await withRetry(() =>
        drive.files.update({
          fileId,
          addParents: newParentId,
          removeParents: previousParents,
          fields: "id, name, parents, webViewLink",
          supportsAllDrives: true,
        })
      );

      return {
        success: true,
        fileId: response.data.id,
        name: response.data.name,
        newParentId: response.data.parents?.[0],
        link: response.data.webViewLink,
        message: messages.drive.fileMoved,
      };
    },
  },

  drive_rename: {
    description: "Rename a file",
    schema: {
      fileId: z.string().describe("File ID"),
      newName: z.string().describe("New name"),
    },
    handler: async ({ fileId, newName }: { fileId: string; newName: string }) => {
      validateDriveId(fileId, "fileId");
      const { drive } = await getGoogleServices();

      const response = await withRetry(() =>
        drive.files.update({
          fileId,
          requestBody: {
            name: newName,
          },
          fields: "id, name, webViewLink",
          supportsAllDrives: true,
        })
      );

      return {
        success: true,
        fileId: response.data.id,
        name: response.data.name,
        link: response.data.webViewLink,
        message: msg(messages.drive.fileRenamed, newName),
      };
    },
  },

  drive_delete: {
    description: "Delete a file or folder (move to trash)",
    schema: {
      fileId: z.string().describe("File/folder ID"),
    },
    handler: async ({ fileId }: { fileId: string }) => {
      validateDriveId(fileId, "fileId");
      const { drive } = await getGoogleServices();

      await withRetry(() =>
        drive.files.update({
          fileId,
          requestBody: {
            trashed: true,
          },
          supportsAllDrives: true,
        })
      );

      return {
        success: true,
        message: messages.drive.fileDeleted,
      };
    },
  },

  drive_restore: {
    description: "Restore a file from trash",
    schema: {
      fileId: z.string().describe("File ID"),
    },
    handler: async ({ fileId }: { fileId: string }) => {
      validateDriveId(fileId, "fileId");
      const { drive } = await getGoogleServices();

      await withRetry(() =>
        drive.files.update({
          fileId,
          requestBody: {
            trashed: false,
          },
          supportsAllDrives: true,
        })
      );

      return {
        success: true,
        message: messages.drive.fileRestored,
      };
    },
  },

  drive_share: {
    description: "Share a file with another person",
    schema: {
      fileId: z.string().describe("File ID"),
      email: z.string().describe("Email address to share with"),
      role: z.enum(["reader", "writer", "commenter"]).default("reader").describe("Permission role"),
      sendNotification: z.boolean().optional().default(true).describe("Send notification email"),
    },
    handler: async ({
      fileId,
      email,
      role,
      sendNotification,
    }: {
      fileId: string;
      email: string;
      role: string;
      sendNotification: boolean;
    }) => {
      validateDriveId(fileId, "fileId");

      // FR-S1-12: Defensive email format validation
      if (!validateEmail(email)) {
        throw new Error(`Invalid email address format: ${email}`);
      }

      const { drive } = await getGoogleServices();

      await withRetry(() =>
        drive.permissions.create({
          fileId,
          requestBody: {
            type: "user",
            role,
            emailAddress: email,
          },
          sendNotificationEmail: sendNotification,
          supportsAllDrives: true,
        })
      );

      const roleText: Record<string, string> = {
        reader: "viewer",
        writer: "editor",
        commenter: "commenter",
      };

      return {
        success: true,
        message: msg(messages.drive.shared, email, roleText[role] || role),
      };
    },
  },

  drive_share_link: {
    description: "Enable link sharing for a file",
    schema: {
      fileId: z.string().describe("File ID"),
      type: z
        .enum(["anyone", "domain"])
        .default("anyone")
        .describe("Share scope (anyone: public, domain: organization)"),
      role: z.enum(["reader", "writer", "commenter"]).default("reader").describe("Permission role"),
    },
    handler: async ({ fileId, type, role }: { fileId: string; type: string; role: string }) => {
      validateDriveId(fileId, "fileId");
      const { drive } = await getGoogleServices();

      await withRetry(() =>
        drive.permissions.create({
          fileId,
          requestBody: {
            type: type === "anyone" ? "anyone" : "domain",
            role,
          },
          supportsAllDrives: true,
        })
      );

      const file = await withRetry(() =>
        drive.files.get({
          fileId,
          fields: "webViewLink",
          supportsAllDrives: true,
        })
      );

      return {
        success: true,
        link: file.data.webViewLink,
        message: messages.drive.linkShared,
      };
    },
  },

  drive_unshare: {
    description: "Remove sharing for a file",
    schema: {
      fileId: z.string().describe("File ID"),
      email: z.string().describe("Email address to unshare"),
    },
    handler: async ({ fileId, email }: { fileId: string; email: string }) => {
      validateDriveId(fileId, "fileId");

      // FR-S1-12: Defensive email format validation
      if (!validateEmail(email)) {
        throw new Error(`Invalid email address format: ${email}`);
      }

      const { drive } = await getGoogleServices();

      const permissions = await withRetry(() =>
        drive.permissions.list({
          fileId,
          fields: "permissions(id, emailAddress)",
          supportsAllDrives: true,
        })
      );

      const permission = permissions.data.permissions?.find((p) => p.emailAddress === email);

      if (!permission) {
        return {
          success: false,
          message: msg(messages.drive.permissionNotFound, email),
        };
      }

      await withRetry(() =>
        drive.permissions.delete({
          fileId,
          permissionId: permission.id!,
          supportsAllDrives: true,
        })
      );

      return {
        success: true,
        message: msg(messages.drive.unshared, email),
      };
    },
  },

  drive_list_permissions: {
    description: "List sharing permissions for a file",
    schema: {
      fileId: z.string().describe("File ID"),
    },
    handler: async ({ fileId }: { fileId: string }) => {
      validateDriveId(fileId, "fileId");
      const { drive } = await getGoogleServices();

      const response = await withRetry(() =>
        drive.permissions.list({
          fileId,
          fields: "permissions(id, type, role, emailAddress, displayName)",
          supportsAllDrives: true,
        })
      );

      return {
        permissions: response.data.permissions?.map((p) => ({
          id: p.id,
          type: p.type,
          role: p.role,
          email: p.emailAddress,
          name: p.displayName,
        })),
      };
    },
  },

  drive_get_storage_quota: {
    description: "Get Drive storage quota information",
    schema: {},
    handler: async () => {
      const { drive } = await getGoogleServices();

      const response = await withRetry(() =>
        drive.about.get({
          fields: "storageQuota",
        })
      );

      const quota = response.data.storageQuota;

      const formatBytes = (bytes: string) => {
        const b = parseInt(bytes);
        const gb = b / (1024 * 1024 * 1024);
        return `${gb.toFixed(2)} GB`;
      };

      return {
        limit: quota?.limit ? formatBytes(quota.limit) : "Unlimited",
        usage: formatBytes(quota?.usage || "0"),
        usageInDrive: formatBytes(quota?.usageInDrive || "0"),
        usageInDriveTrash: formatBytes(quota?.usageInDriveTrash || "0"),
      };
    },
  },
};
