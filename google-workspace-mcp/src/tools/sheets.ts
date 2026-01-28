import { z } from "zod";
import { getGoogleServices } from "../auth/oauth.js";

/**
 * Sheets 도구 정의
 */
export const sheetsTools = {
  sheets_create: {
    description: "새 Google Sheets 스프레드시트를 생성합니다",
    schema: {
      title: z.string().describe("스프레드시트 제목"),
      sheetNames: z.array(z.string()).optional().describe("시트 이름 목록"),
      folderId: z.string().optional().describe("저장할 폴더 ID"),
    },
    handler: async ({ title, sheetNames, folderId }: { title: string; sheetNames?: string[]; folderId?: string }) => {
      const { sheets, drive } = await getGoogleServices();

      const requestBody: any = {
        properties: { title },
      };

      if (sheetNames && sheetNames.length > 0) {
        requestBody.sheets = sheetNames.map((name) => ({
          properties: { title: name },
        }));
      }

      const response = await sheets.spreadsheets.create({ requestBody });
      const spreadsheetId = response.data.spreadsheetId!;

      // 폴더로 이동
      if (folderId) {
        const file = await drive.files.get({
          fileId: spreadsheetId,
          fields: "parents",
        });
        await drive.files.update({
          fileId: spreadsheetId,
          addParents: folderId,
          removeParents: file.data.parents?.join(","),
        });
      }

      const file = await drive.files.get({
        fileId: spreadsheetId,
        fields: "webViewLink",
      });

      return {
        success: true,
        spreadsheetId,
        title,
        link: file.data.webViewLink,
        sheets: response.data.sheets?.map((s) => s.properties?.title),
        message: `스프레드시트 "${title}"이 생성되었습니다.`,
      };
    },
  },

  sheets_get_info: {
    description: "스프레드시트 정보를 조회합니다",
    schema: {
      spreadsheetId: z.string().describe("스프레드시트 ID"),
    },
    handler: async ({ spreadsheetId }: { spreadsheetId: string }) => {
      const { sheets } = await getGoogleServices();

      const response = await sheets.spreadsheets.get({
        spreadsheetId,
      });

      return {
        spreadsheetId,
        title: response.data.properties?.title,
        locale: response.data.properties?.locale,
        sheets: response.data.sheets?.map((s) => ({
          sheetId: s.properties?.sheetId,
          title: s.properties?.title,
          index: s.properties?.index,
          rowCount: s.properties?.gridProperties?.rowCount,
          columnCount: s.properties?.gridProperties?.columnCount,
        })),
      };
    },
  },

  sheets_read: {
    description: "스프레드시트 데이터를 읽습니다",
    schema: {
      spreadsheetId: z.string().describe("스프레드시트 ID"),
      range: z.string().describe("범위 (예: 'Sheet1!A1:D10' 또는 'A1:D10')"),
    },
    handler: async ({ spreadsheetId, range }: { spreadsheetId: string; range: string }) => {
      const { sheets } = await getGoogleServices();

      const response = await sheets.spreadsheets.values.get({
        spreadsheetId,
        range,
      });

      return {
        spreadsheetId,
        range: response.data.range,
        values: response.data.values || [],
        rowCount: response.data.values?.length || 0,
        columnCount: response.data.values?.[0]?.length || 0,
      };
    },
  },

  sheets_read_multiple: {
    description: "여러 범위의 데이터를 한 번에 읽습니다",
    schema: {
      spreadsheetId: z.string().describe("스프레드시트 ID"),
      ranges: z.array(z.string()).describe("범위 목록"),
    },
    handler: async ({ spreadsheetId, ranges }: { spreadsheetId: string; ranges: string[] }) => {
      const { sheets } = await getGoogleServices();

      const response = await sheets.spreadsheets.values.batchGet({
        spreadsheetId,
        ranges,
      });

      return {
        spreadsheetId,
        valueRanges: response.data.valueRanges?.map((vr) => ({
          range: vr.range,
          values: vr.values || [],
        })),
      };
    },
  },

  sheets_write: {
    description: "스프레드시트에 데이터를 씁니다",
    schema: {
      spreadsheetId: z.string().describe("스프레드시트 ID"),
      range: z.string().describe("시작 범위 (예: 'Sheet1!A1')"),
      values: z.array(z.array(z.any())).describe("2D 배열 데이터"),
    },
    handler: async ({ spreadsheetId, range, values }: {
      spreadsheetId: string;
      range: string;
      values: any[][];
    }) => {
      const { sheets } = await getGoogleServices();

      const response = await sheets.spreadsheets.values.update({
        spreadsheetId,
        range,
        valueInputOption: "USER_ENTERED",
        requestBody: { values },
      });

      return {
        success: true,
        updatedRange: response.data.updatedRange,
        updatedRows: response.data.updatedRows,
        updatedColumns: response.data.updatedColumns,
        updatedCells: response.data.updatedCells,
        message: `${response.data.updatedCells}개 셀이 업데이트되었습니다.`,
      };
    },
  },

  sheets_append: {
    description: "스프레드시트 끝에 데이터를 추가합니다",
    schema: {
      spreadsheetId: z.string().describe("스프레드시트 ID"),
      range: z.string().describe("시트 범위 (예: 'Sheet1')"),
      values: z.array(z.array(z.any())).describe("추가할 행 데이터"),
    },
    handler: async ({ spreadsheetId, range, values }: {
      spreadsheetId: string;
      range: string;
      values: any[][];
    }) => {
      const { sheets } = await getGoogleServices();

      const response = await sheets.spreadsheets.values.append({
        spreadsheetId,
        range,
        valueInputOption: "USER_ENTERED",
        insertDataOption: "INSERT_ROWS",
        requestBody: { values },
      });

      return {
        success: true,
        updatedRange: response.data.updates?.updatedRange,
        updatedRows: response.data.updates?.updatedRows,
        message: `${response.data.updates?.updatedRows}개 행이 추가되었습니다.`,
      };
    },
  },

  sheets_clear: {
    description: "스프레드시트 범위의 데이터를 삭제합니다",
    schema: {
      spreadsheetId: z.string().describe("스프레드시트 ID"),
      range: z.string().describe("삭제할 범위"),
    },
    handler: async ({ spreadsheetId, range }: { spreadsheetId: string; range: string }) => {
      const { sheets } = await getGoogleServices();

      await sheets.spreadsheets.values.clear({
        spreadsheetId,
        range,
      });

      return {
        success: true,
        message: `${range} 범위의 데이터가 삭제되었습니다.`,
      };
    },
  },

  sheets_add_sheet: {
    description: "새 시트를 추가합니다",
    schema: {
      spreadsheetId: z.string().describe("스프레드시트 ID"),
      title: z.string().describe("시트 이름"),
    },
    handler: async ({ spreadsheetId, title }: { spreadsheetId: string; title: string }) => {
      const { sheets } = await getGoogleServices();

      const response = await sheets.spreadsheets.batchUpdate({
        spreadsheetId,
        requestBody: {
          requests: [
            {
              addSheet: {
                properties: { title },
              },
            },
          ],
        },
      });

      const newSheet = response.data.replies?.[0]?.addSheet;

      return {
        success: true,
        sheetId: newSheet?.properties?.sheetId,
        title: newSheet?.properties?.title,
        message: `시트 "${title}"이 추가되었습니다.`,
      };
    },
  },

  sheets_delete_sheet: {
    description: "시트를 삭제합니다",
    schema: {
      spreadsheetId: z.string().describe("스프레드시트 ID"),
      sheetId: z.number().describe("시트 ID (시트 이름 아님)"),
    },
    handler: async ({ spreadsheetId, sheetId }: { spreadsheetId: string; sheetId: number }) => {
      const { sheets } = await getGoogleServices();

      await sheets.spreadsheets.batchUpdate({
        spreadsheetId,
        requestBody: {
          requests: [
            {
              deleteSheet: { sheetId },
            },
          ],
        },
      });

      return {
        success: true,
        message: "시트가 삭제되었습니다.",
      };
    },
  },

  sheets_rename_sheet: {
    description: "시트 이름을 변경합니다",
    schema: {
      spreadsheetId: z.string().describe("스프레드시트 ID"),
      sheetId: z.number().describe("시트 ID"),
      newTitle: z.string().describe("새 시트 이름"),
    },
    handler: async ({ spreadsheetId, sheetId, newTitle }: {
      spreadsheetId: string;
      sheetId: number;
      newTitle: string;
    }) => {
      const { sheets } = await getGoogleServices();

      await sheets.spreadsheets.batchUpdate({
        spreadsheetId,
        requestBody: {
          requests: [
            {
              updateSheetProperties: {
                properties: {
                  sheetId,
                  title: newTitle,
                },
                fields: "title",
              },
            },
          ],
        },
      });

      return {
        success: true,
        message: `시트 이름이 "${newTitle}"으로 변경되었습니다.`,
      };
    },
  },

  sheets_format_cells: {
    description: "셀 서식을 설정합니다 (배경색, 굵게 등)",
    schema: {
      spreadsheetId: z.string().describe("스프레드시트 ID"),
      sheetId: z.number().describe("시트 ID"),
      startRow: z.number().describe("시작 행 (0부터)"),
      endRow: z.number().describe("끝 행"),
      startColumn: z.number().describe("시작 열 (0부터)"),
      endColumn: z.number().describe("끝 열"),
      bold: z.boolean().optional().describe("굵게"),
      backgroundColor: z.string().optional().describe("배경색 (hex, 예: '#FF0000')"),
    },
    handler: async ({ spreadsheetId, sheetId, startRow, endRow, startColumn, endColumn, bold, backgroundColor }: {
      spreadsheetId: string;
      sheetId: number;
      startRow: number;
      endRow: number;
      startColumn: number;
      endColumn: number;
      bold?: boolean;
      backgroundColor?: string;
    }) => {
      const { sheets } = await getGoogleServices();

      const cellFormat: any = {};
      const fields: string[] = [];

      if (bold !== undefined) {
        cellFormat.textFormat = { bold };
        fields.push("userEnteredFormat.textFormat.bold");
      }

      if (backgroundColor) {
        const hex = backgroundColor.replace("#", "");
        const r = parseInt(hex.slice(0, 2), 16) / 255;
        const g = parseInt(hex.slice(2, 4), 16) / 255;
        const b = parseInt(hex.slice(4, 6), 16) / 255;
        cellFormat.backgroundColor = { red: r, green: g, blue: b };
        fields.push("userEnteredFormat.backgroundColor");
      }

      await sheets.spreadsheets.batchUpdate({
        spreadsheetId,
        requestBody: {
          requests: [
            {
              repeatCell: {
                range: {
                  sheetId,
                  startRowIndex: startRow,
                  endRowIndex: endRow,
                  startColumnIndex: startColumn,
                  endColumnIndex: endColumn,
                },
                cell: {
                  userEnteredFormat: cellFormat,
                },
                fields: fields.join(","),
              },
            },
          ],
        },
      });

      return {
        success: true,
        message: "셀 서식이 적용되었습니다.",
      };
    },
  },

  sheets_auto_resize: {
    description: "열 너비를 자동 조절합니다",
    schema: {
      spreadsheetId: z.string().describe("스프레드시트 ID"),
      sheetId: z.number().describe("시트 ID"),
      startColumn: z.number().optional().default(0).describe("시작 열"),
      endColumn: z.number().optional().default(26).describe("끝 열"),
    },
    handler: async ({ spreadsheetId, sheetId, startColumn, endColumn }: {
      spreadsheetId: string;
      sheetId: number;
      startColumn: number;
      endColumn: number;
    }) => {
      const { sheets } = await getGoogleServices();

      await sheets.spreadsheets.batchUpdate({
        spreadsheetId,
        requestBody: {
          requests: [
            {
              autoResizeDimensions: {
                dimensions: {
                  sheetId,
                  dimension: "COLUMNS",
                  startIndex: startColumn,
                  endIndex: endColumn,
                },
              },
            },
          ],
        },
      });

      return {
        success: true,
        message: "열 너비가 자동 조절되었습니다.",
      };
    },
  },
};
