import { z } from "zod";
import { getGoogleServices } from "../auth/oauth.js";
import { withRetry } from "../utils/retry.js";
import { messages, msg } from "../utils/messages.js";

/**
 * Sheets tool definitions
 */
export const sheetsTools = {
  sheets_create: {
    description: "Create a new Google Sheets spreadsheet",
    schema: {
      title: z.string().describe("Spreadsheet title"),
      sheetNames: z.array(z.string()).optional().describe("Sheet name list"),
      folderId: z.string().optional().describe("Destination folder ID"),
    },
    handler: async ({
      title,
      sheetNames,
      folderId,
    }: {
      title: string;
      sheetNames?: string[];
      folderId?: string;
    }) => {
      const { sheets, drive } = await getGoogleServices();

      // FR-S3-07: Typed request body instead of any
      const requestBody: Record<string, unknown> = {
        properties: { title },
      };

      if (sheetNames && sheetNames.length > 0) {
        requestBody.sheets = sheetNames.map((name) => ({
          properties: { title: name },
        }));
      }

      const response = await withRetry(() => sheets.spreadsheets.create({ requestBody }));
      const spreadsheetId = response.data.spreadsheetId!;

      if (folderId) {
        const file = await withRetry(() =>
          drive.files.get({ fileId: spreadsheetId, fields: "parents" })
        );
        await withRetry(() =>
          drive.files.update({
            fileId: spreadsheetId,
            addParents: folderId,
            removeParents: file.data.parents?.join(","),
          })
        );
      }

      const file = await withRetry(() =>
        drive.files.get({ fileId: spreadsheetId, fields: "webViewLink" })
      );

      return {
        success: true,
        spreadsheetId,
        title,
        link: file.data.webViewLink,
        sheets: response.data.sheets?.map((s) => s.properties?.title),
        message: msg(messages.sheets.spreadsheetCreated, title),
      };
    },
  },

  sheets_get_info: {
    description: "Get spreadsheet information",
    schema: {
      spreadsheetId: z.string().describe("Spreadsheet ID"),
    },
    handler: async ({ spreadsheetId }: { spreadsheetId: string }) => {
      const { sheets } = await getGoogleServices();

      const response = await withRetry(() => sheets.spreadsheets.get({ spreadsheetId }));

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
    description: "Read spreadsheet data",
    schema: {
      spreadsheetId: z.string().describe("Spreadsheet ID"),
      range: z.string().describe("Range (e.g. 'Sheet1!A1:D10' or 'A1:D10')"),
    },
    handler: async ({ spreadsheetId, range }: { spreadsheetId: string; range: string }) => {
      const { sheets } = await getGoogleServices();

      const response = await withRetry(() =>
        sheets.spreadsheets.values.get({ spreadsheetId, range })
      );

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
    description: "Read data from multiple ranges at once",
    schema: {
      spreadsheetId: z.string().describe("Spreadsheet ID"),
      ranges: z.array(z.string()).describe("Range list"),
    },
    handler: async ({ spreadsheetId, ranges }: { spreadsheetId: string; ranges: string[] }) => {
      const { sheets } = await getGoogleServices();

      const response = await withRetry(() =>
        sheets.spreadsheets.values.batchGet({ spreadsheetId, ranges })
      );

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
    description: "Write data to a spreadsheet",
    schema: {
      spreadsheetId: z.string().describe("Spreadsheet ID"),
      range: z.string().describe("Start range (e.g. 'Sheet1!A1')"),
      values: z.array(z.array(z.any())).describe("2D array data"),
    },
    handler: async ({
      spreadsheetId,
      range,
      values,
    }: {
      spreadsheetId: string;
      range: string;
      values: unknown[][];
    }) => {
      const { sheets } = await getGoogleServices();

      const response = await withRetry(() =>
        sheets.spreadsheets.values.update({
          spreadsheetId,
          range,
          valueInputOption: "USER_ENTERED",
          requestBody: { values },
        })
      );

      return {
        success: true,
        updatedRange: response.data.updatedRange,
        updatedRows: response.data.updatedRows,
        updatedColumns: response.data.updatedColumns,
        updatedCells: response.data.updatedCells,
        message: `${response.data.updatedCells} cells updated.`,
      };
    },
  },

  sheets_append: {
    description: "Append data to the end of a spreadsheet",
    schema: {
      spreadsheetId: z.string().describe("Spreadsheet ID"),
      range: z.string().describe("Sheet range (e.g. 'Sheet1')"),
      values: z.array(z.array(z.any())).describe("Row data to append"),
    },
    handler: async ({
      spreadsheetId,
      range,
      values,
    }: {
      spreadsheetId: string;
      range: string;
      values: unknown[][];
    }) => {
      const { sheets } = await getGoogleServices();

      const response = await withRetry(() =>
        sheets.spreadsheets.values.append({
          spreadsheetId,
          range,
          valueInputOption: "USER_ENTERED",
          insertDataOption: "INSERT_ROWS",
          requestBody: { values },
        })
      );

      return {
        success: true,
        updatedRange: response.data.updates?.updatedRange,
        updatedRows: response.data.updates?.updatedRows,
        message: `${response.data.updates?.updatedRows} rows appended.`,
      };
    },
  },

  sheets_clear: {
    description: "Clear data in a spreadsheet range",
    schema: {
      spreadsheetId: z.string().describe("Spreadsheet ID"),
      range: z.string().describe("Range to clear"),
    },
    handler: async ({ spreadsheetId, range }: { spreadsheetId: string; range: string }) => {
      const { sheets } = await getGoogleServices();

      await withRetry(() => sheets.spreadsheets.values.clear({ spreadsheetId, range }));

      return {
        success: true,
        message: `Data in range ${range} cleared.`,
      };
    },
  },

  sheets_add_sheet: {
    description: "Add a new sheet",
    schema: {
      spreadsheetId: z.string().describe("Spreadsheet ID"),
      title: z.string().describe("Sheet name"),
    },
    handler: async ({ spreadsheetId, title }: { spreadsheetId: string; title: string }) => {
      const { sheets } = await getGoogleServices();

      const response = await withRetry(() =>
        sheets.spreadsheets.batchUpdate({
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
        })
      );

      const newSheet = response.data.replies?.[0]?.addSheet;

      return {
        success: true,
        sheetId: newSheet?.properties?.sheetId,
        title: newSheet?.properties?.title,
        message: `Sheet "${title}" added.`,
      };
    },
  },

  sheets_delete_sheet: {
    description: "Delete a sheet",
    schema: {
      spreadsheetId: z.string().describe("Spreadsheet ID"),
      sheetId: z.number().describe("Sheet ID (not sheet name)"),
    },
    handler: async ({ spreadsheetId, sheetId }: { spreadsheetId: string; sheetId: number }) => {
      const { sheets } = await getGoogleServices();

      await withRetry(() =>
        sheets.spreadsheets.batchUpdate({
          spreadsheetId,
          requestBody: {
            requests: [
              {
                deleteSheet: { sheetId },
              },
            ],
          },
        })
      );

      return {
        success: true,
        message: "Sheet deleted.",
      };
    },
  },

  sheets_rename_sheet: {
    description: "Rename a sheet",
    schema: {
      spreadsheetId: z.string().describe("Spreadsheet ID"),
      sheetId: z.number().describe("Sheet ID"),
      newTitle: z.string().describe("New sheet name"),
    },
    handler: async ({
      spreadsheetId,
      sheetId,
      newTitle,
    }: {
      spreadsheetId: string;
      sheetId: number;
      newTitle: string;
    }) => {
      const { sheets } = await getGoogleServices();

      await withRetry(() =>
        sheets.spreadsheets.batchUpdate({
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
        })
      );

      return {
        success: true,
        message: `Sheet renamed to "${newTitle}".`,
      };
    },
  },

  sheets_format_cells: {
    description: "Format cells (background color, bold, etc.)",
    schema: {
      spreadsheetId: z.string().describe("Spreadsheet ID"),
      sheetId: z.number().describe("Sheet ID"),
      startRow: z.number().describe("Start row (0-based)"),
      endRow: z.number().describe("End row"),
      startColumn: z.number().describe("Start column (0-based)"),
      endColumn: z.number().describe("End column"),
      bold: z.boolean().optional().describe("Bold"),
      backgroundColor: z.string().optional().describe("Background color (hex, e.g. '#FF0000')"),
    },
    handler: async ({
      spreadsheetId,
      sheetId,
      startRow,
      endRow,
      startColumn,
      endColumn,
      bold,
      backgroundColor,
    }: {
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

      // FR-S3-07: Typed format object instead of any
      const cellFormat: Record<string, unknown> = {};
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

      await withRetry(() =>
        sheets.spreadsheets.batchUpdate({
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
        })
      );

      return {
        success: true,
        message: messages.sheets.formatApplied,
      };
    },
  },

  sheets_auto_resize: {
    description: "Auto-resize column widths",
    schema: {
      spreadsheetId: z.string().describe("Spreadsheet ID"),
      sheetId: z.number().describe("Sheet ID"),
      startColumn: z.number().optional().default(0).describe("Start column"),
      endColumn: z.number().optional().default(26).describe("End column"),
    },
    handler: async ({
      spreadsheetId,
      sheetId,
      startColumn,
      endColumn,
    }: {
      spreadsheetId: string;
      sheetId: number;
      startColumn: number;
      endColumn: number;
    }) => {
      const { sheets } = await getGoogleServices();

      await withRetry(() =>
        sheets.spreadsheets.batchUpdate({
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
        })
      );

      return {
        success: true,
        message: "Column widths auto-resized.",
      };
    },
  },
};
