import { z } from "zod";
import { getGoogleServices } from "../auth/oauth.js";

/**
 * Drive 도구 정의
 */
export const driveTools = {
  drive_search: {
    description: "Google Drive에서 파일을 검색합니다",
    schema: {
      query: z.string().describe("검색어"),
      mimeType: z.string().optional().describe("파일 타입 필터"),
      maxResults: z.number().optional().default(10).describe("최대 결과 수"),
    },
    handler: async ({ query, mimeType, maxResults }: { query: string; mimeType?: string; maxResults: number }) => {
      const { drive } = await getGoogleServices();

      let q = `name contains '${query}' and trashed = false`;
      if (mimeType) {
        q += ` and mimeType = '${mimeType}'`;
      }

      const response = await drive.files.list({
        q,
        pageSize: maxResults,
        fields: "files(id, name, mimeType, modifiedTime, webViewLink, owners, size, parents)",
      });

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
    description: "폴더의 파일 목록을 조회합니다",
    schema: {
      folderId: z.string().optional().default("root").describe("폴더 ID (기본: root)"),
      maxResults: z.number().optional().default(20).describe("최대 결과 수"),
      orderBy: z.string().optional().default("modifiedTime desc").describe("정렬 기준"),
    },
    handler: async ({ folderId, maxResults, orderBy }: { folderId: string; maxResults: number; orderBy: string }) => {
      const { drive } = await getGoogleServices();

      const response = await drive.files.list({
        q: `'${folderId}' in parents and trashed = false`,
        pageSize: maxResults,
        fields: "files(id, name, mimeType, modifiedTime, webViewLink, size)",
        orderBy,
      });

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
    description: "파일 상세 정보를 조회합니다",
    schema: {
      fileId: z.string().describe("파일 ID"),
    },
    handler: async ({ fileId }: { fileId: string }) => {
      const { drive } = await getGoogleServices();

      const response = await drive.files.get({
        fileId,
        fields: "id, name, mimeType, modifiedTime, createdTime, webViewLink, size, owners, parents, shared, permissions",
      });

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
    description: "새 폴더를 생성합니다",
    schema: {
      name: z.string().describe("폴더 이름"),
      parentId: z.string().optional().describe("상위 폴더 ID (기본: root)"),
    },
    handler: async ({ name, parentId }: { name: string; parentId?: string }) => {
      const { drive } = await getGoogleServices();

      const response = await drive.files.create({
        requestBody: {
          name,
          mimeType: "application/vnd.google-apps.folder",
          parents: parentId ? [parentId] : undefined,
        },
        fields: "id, name, webViewLink",
      });

      return {
        success: true,
        folderId: response.data.id,
        name: response.data.name,
        link: response.data.webViewLink,
        message: `폴더 "${name}"이 생성되었습니다.`,
      };
    },
  },

  drive_copy: {
    description: "파일을 복사합니다",
    schema: {
      fileId: z.string().describe("원본 파일 ID"),
      newName: z.string().optional().describe("새 파일 이름"),
      parentId: z.string().optional().describe("복사할 위치 폴더 ID"),
    },
    handler: async ({ fileId, newName, parentId }: { fileId: string; newName?: string; parentId?: string }) => {
      const { drive } = await getGoogleServices();

      const response = await drive.files.copy({
        fileId,
        requestBody: {
          name: newName,
          parents: parentId ? [parentId] : undefined,
        },
        fields: "id, name, webViewLink",
      });

      return {
        success: true,
        fileId: response.data.id,
        name: response.data.name,
        link: response.data.webViewLink,
        message: "파일이 복사되었습니다.",
      };
    },
  },

  drive_move: {
    description: "파일을 다른 폴더로 이동합니다",
    schema: {
      fileId: z.string().describe("파일 ID"),
      newParentId: z.string().describe("이동할 폴더 ID"),
    },
    handler: async ({ fileId, newParentId }: { fileId: string; newParentId: string }) => {
      const { drive } = await getGoogleServices();

      // 현재 부모 폴더 확인
      const file = await drive.files.get({
        fileId,
        fields: "parents",
      });

      const previousParents = file.data.parents?.join(",") || "";

      const response = await drive.files.update({
        fileId,
        addParents: newParentId,
        removeParents: previousParents,
        fields: "id, name, parents, webViewLink",
      });

      return {
        success: true,
        fileId: response.data.id,
        name: response.data.name,
        newParentId: response.data.parents?.[0],
        link: response.data.webViewLink,
        message: "파일이 이동되었습니다.",
      };
    },
  },

  drive_rename: {
    description: "파일 이름을 변경합니다",
    schema: {
      fileId: z.string().describe("파일 ID"),
      newName: z.string().describe("새 이름"),
    },
    handler: async ({ fileId, newName }: { fileId: string; newName: string }) => {
      const { drive } = await getGoogleServices();

      const response = await drive.files.update({
        fileId,
        requestBody: {
          name: newName,
        },
        fields: "id, name, webViewLink",
      });

      return {
        success: true,
        fileId: response.data.id,
        name: response.data.name,
        link: response.data.webViewLink,
        message: `파일 이름이 "${newName}"으로 변경되었습니다.`,
      };
    },
  },

  drive_delete: {
    description: "파일 또는 폴더를 삭제합니다 (휴지통으로 이동)",
    schema: {
      fileId: z.string().describe("파일/폴더 ID"),
    },
    handler: async ({ fileId }: { fileId: string }) => {
      const { drive } = await getGoogleServices();

      await drive.files.update({
        fileId,
        requestBody: {
          trashed: true,
        },
      });

      return {
        success: true,
        message: "파일이 휴지통으로 이동되었습니다.",
      };
    },
  },

  drive_restore: {
    description: "휴지통에서 파일을 복원합니다",
    schema: {
      fileId: z.string().describe("파일 ID"),
    },
    handler: async ({ fileId }: { fileId: string }) => {
      const { drive } = await getGoogleServices();

      await drive.files.update({
        fileId,
        requestBody: {
          trashed: false,
        },
      });

      return {
        success: true,
        message: "파일이 복원되었습니다.",
      };
    },
  },

  drive_share: {
    description: "파일을 다른 사람과 공유합니다",
    schema: {
      fileId: z.string().describe("파일 ID"),
      email: z.string().describe("공유할 사람의 이메일"),
      role: z.enum(["reader", "writer", "commenter"]).default("reader").describe("권한"),
      sendNotification: z.boolean().optional().default(true).describe("알림 이메일 발송 여부"),
    },
    handler: async ({ fileId, email, role, sendNotification }: {
      fileId: string;
      email: string;
      role: string;
      sendNotification: boolean;
    }) => {
      const { drive } = await getGoogleServices();

      await drive.permissions.create({
        fileId,
        requestBody: {
          type: "user",
          role,
          emailAddress: email,
        },
        sendNotificationEmail: sendNotification,
      });

      const roleText = { reader: "보기", writer: "편집", commenter: "댓글" }[role];

      return {
        success: true,
        message: `${email}에게 ${roleText} 권한으로 공유되었습니다.`,
      };
    },
  },

  drive_share_link: {
    description: "링크로 공유 설정을 합니다",
    schema: {
      fileId: z.string().describe("파일 ID"),
      type: z.enum(["anyone", "domain"]).default("anyone").describe("공유 범위 (anyone: 전체, domain: 도메인)"),
      role: z.enum(["reader", "writer", "commenter"]).default("reader").describe("권한"),
    },
    handler: async ({ fileId, type, role }: { fileId: string; type: string; role: string }) => {
      const { drive } = await getGoogleServices();

      await drive.permissions.create({
        fileId,
        requestBody: {
          type: type === "anyone" ? "anyone" : "domain",
          role,
        },
      });

      const file = await drive.files.get({
        fileId,
        fields: "webViewLink",
      });

      return {
        success: true,
        link: file.data.webViewLink,
        message: "링크 공유가 설정되었습니다.",
      };
    },
  },

  drive_unshare: {
    description: "공유를 해제합니다",
    schema: {
      fileId: z.string().describe("파일 ID"),
      email: z.string().describe("공유 해제할 이메일"),
    },
    handler: async ({ fileId, email }: { fileId: string; email: string }) => {
      const { drive } = await getGoogleServices();

      // 권한 목록 조회
      const permissions = await drive.permissions.list({
        fileId,
        fields: "permissions(id, emailAddress)",
      });

      const permission = permissions.data.permissions?.find(
        (p) => p.emailAddress === email
      );

      if (!permission) {
        return {
          success: false,
          message: `${email}에 대한 공유 설정을 찾을 수 없습니다.`,
        };
      }

      await drive.permissions.delete({
        fileId,
        permissionId: permission.id!,
      });

      return {
        success: true,
        message: `${email}의 공유가 해제되었습니다.`,
      };
    },
  },

  drive_list_permissions: {
    description: "파일의 공유 권한 목록을 조회합니다",
    schema: {
      fileId: z.string().describe("파일 ID"),
    },
    handler: async ({ fileId }: { fileId: string }) => {
      const { drive } = await getGoogleServices();

      const response = await drive.permissions.list({
        fileId,
        fields: "permissions(id, type, role, emailAddress, displayName)",
      });

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
    description: "드라이브 저장 용량 정보를 조회합니다",
    schema: {},
    handler: async () => {
      const { drive } = await getGoogleServices();

      const response = await drive.about.get({
        fields: "storageQuota",
      });

      const quota = response.data.storageQuota;

      const formatBytes = (bytes: string) => {
        const b = parseInt(bytes);
        const gb = b / (1024 * 1024 * 1024);
        return `${gb.toFixed(2)} GB`;
      };

      return {
        limit: quota?.limit ? formatBytes(quota.limit) : "무제한",
        usage: formatBytes(quota?.usage || "0"),
        usageInDrive: formatBytes(quota?.usageInDrive || "0"),
        usageInDriveTrash: formatBytes(quota?.usageInDriveTrash || "0"),
      };
    },
  },
};
