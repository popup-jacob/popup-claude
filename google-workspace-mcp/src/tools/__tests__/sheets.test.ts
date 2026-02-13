import { describe, it, expect, vi, beforeEach } from "vitest";
import { sheetsTools } from "../sheets.js";

// Mock getGoogleServices
const mockSheetsApi = {
  spreadsheets: {
    create: vi.fn(),
    get: vi.fn(),
    values: {
      get: vi.fn(),
      update: vi.fn(),
      append: vi.fn(),
      clear: vi.fn(),
      batchGet: vi.fn(),
    },
    batchUpdate: vi.fn(),
  },
};

const mockDriveApi = {
  files: {
    update: vi.fn(),
    get: vi.fn(),
  },
};

vi.mock("../../auth/oauth", () => ({
  getGoogleServices: vi.fn(async () => ({
    sheets: mockSheetsApi,
    drive: mockDriveApi,
  })),
}));

describe("Sheets Tools - Core Functionality", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("sheets_create - TC-SH01: Spreadsheet Creation", () => {
    it("should create a new spreadsheet with title only", async () => {
      mockSheetsApi.spreadsheets.create.mockResolvedValue({
        data: {
          spreadsheetId: "sheet123",
          properties: {
            title: "New Spreadsheet",
          },
        },
      });

      mockDriveApi.files.get.mockResolvedValue({
        data: {
          webViewLink: "https://docs.google.com/spreadsheets/d/sheet123",
        },
      });

      const result = await sheetsTools.sheets_create.handler({
        title: "New Spreadsheet",
      });

      expect(result.success).toBe(true);
      expect(result.spreadsheetId).toBe("sheet123");
      expect(mockSheetsApi.spreadsheets.create).toHaveBeenCalledWith({
        requestBody: {
          properties: {
            title: "New Spreadsheet",
          },
        },
      });
    });

    it("should create spreadsheet with custom sheet names", async () => {
      mockSheetsApi.spreadsheets.create.mockResolvedValue({
        data: {
          spreadsheetId: "sheet456",
          properties: {
            title: "Multi-Sheet Spreadsheet",
          },
        },
      });

      mockDriveApi.files.get.mockResolvedValue({
        data: {
          webViewLink: "https://docs.google.com/spreadsheets/d/sheet456",
        },
      });

      const result = await sheetsTools.sheets_create.handler({
        title: "Multi-Sheet Spreadsheet",
        sheetNames: ["Data", "Analysis", "Summary"],
      });

      expect(result.success).toBe(true);
      expect(mockSheetsApi.spreadsheets.create).toHaveBeenCalledWith(
        expect.objectContaining({
          requestBody: expect.objectContaining({
            sheets: expect.arrayContaining([
              expect.objectContaining({
                properties: expect.objectContaining({ title: "Data" }),
              }),
              expect.objectContaining({
                properties: expect.objectContaining({ title: "Analysis" }),
              }),
              expect.objectContaining({
                properties: expect.objectContaining({ title: "Summary" }),
              }),
            ]),
          }),
        })
      );
    });

    it("should move spreadsheet to folder if folderId is provided", async () => {
      mockSheetsApi.spreadsheets.create.mockResolvedValue({
        data: {
          spreadsheetId: "sheet789",
          properties: {
            title: "Spreadsheet in Folder",
          },
        },
      });

      mockDriveApi.files.get.mockResolvedValue({
        data: {
          parents: ["oldFolder"],
          webViewLink: "https://docs.google.com/spreadsheets/d/sheet789",
        },
      });

      mockDriveApi.files.update.mockResolvedValue({ data: {} });

      const result = await sheetsTools.sheets_create.handler({
        title: "Spreadsheet in Folder",
        folderId: "folder123",
      });

      expect(result.success).toBe(true);
      expect(mockDriveApi.files.update).toHaveBeenCalledWith(
        expect.objectContaining({
          fileId: "sheet789",
          addParents: "folder123",
        })
      );
    });
  });

  describe("sheets_read - TC-SH02: Reading Values", () => {
    it("should read values from a range", async () => {
      mockSheetsApi.spreadsheets.values.get.mockResolvedValue({
        data: {
          values: [
            ["Name", "Age", "City"],
            ["Alice", "30", "New York"],
            ["Bob", "25", "San Francisco"],
          ],
        },
      });

      const result = await sheetsTools.sheets_read.handler({
        spreadsheetId: "sheet123",
        range: "Sheet1!A1:C3",
      });

      expect(result.values).toHaveLength(3);
      expect(result.values![0]).toEqual(["Name", "Age", "City"]);
      expect(result.values![1]).toEqual(["Alice", "30", "New York"]);
    });

    it("should handle empty range", async () => {
      mockSheetsApi.spreadsheets.values.get.mockResolvedValue({
        data: {},
      });

      const result = await sheetsTools.sheets_read.handler({
        spreadsheetId: "sheet123",
        range: "Sheet1!A1:A10",
      });

      expect(result.values).toEqual([]);
    });
  });

  describe("sheets_write - TC-SH03: Writing Values", () => {
    it("should write values to a range", async () => {
      mockSheetsApi.spreadsheets.values.update.mockResolvedValue({
        data: {
          updatedCells: 6,
          updatedRows: 2,
        },
      });

      const result = await sheetsTools.sheets_write.handler({
        spreadsheetId: "sheet123",
        range: "Sheet1!A1:C2",
        values: [
          ["Header1", "Header2", "Header3"],
          ["Value1", "Value2", "Value3"],
        ],
      });

      expect(result.success).toBe(true);
      expect(mockSheetsApi.spreadsheets.values.update).toHaveBeenCalledWith({
        spreadsheetId: "sheet123",
        range: "Sheet1!A1:C2",
        valueInputOption: "USER_ENTERED",
        requestBody: {
          values: [
            ["Header1", "Header2", "Header3"],
            ["Value1", "Value2", "Value3"],
          ],
        },
      });
    });
  });

  describe("sheets_append - TC-SH04: Appending Values", () => {
    it("should append values to a sheet", async () => {
      mockSheetsApi.spreadsheets.values.append.mockResolvedValue({
        data: {
          updates: {
            updatedCells: 3,
            updatedRows: 1,
          },
        },
      });

      const result = await sheetsTools.sheets_append.handler({
        spreadsheetId: "sheet123",
        range: "Sheet1!A:C",
        values: [["NewRow1", "NewRow2", "NewRow3"]],
      });

      expect(result.success).toBe(true);
      expect(mockSheetsApi.spreadsheets.values.append).toHaveBeenCalledWith({
        spreadsheetId: "sheet123",
        range: "Sheet1!A:C",
        valueInputOption: "USER_ENTERED",
        insertDataOption: "INSERT_ROWS",
        requestBody: {
          values: [["NewRow1", "NewRow2", "NewRow3"]],
        },
      });
    });
  });

  describe("sheets_clear - TC-SH05: Clearing Values", () => {
    it("should clear values in a range", async () => {
      mockSheetsApi.spreadsheets.values.clear.mockResolvedValue({
        data: {},
      });

      const result = await sheetsTools.sheets_clear.handler({
        spreadsheetId: "sheet123",
        range: "Sheet1!A1:C10",
      });

      expect(result.success).toBe(true);
      expect(mockSheetsApi.spreadsheets.values.clear).toHaveBeenCalledWith({
        spreadsheetId: "sheet123",
        range: "Sheet1!A1:C10",
      });
    });
  });

  describe("sheets_add_sheet - TC-SH06: Adding Sheets", () => {
    it("should add a new sheet to spreadsheet", async () => {
      mockSheetsApi.spreadsheets.batchUpdate.mockResolvedValue({
        data: {
          replies: [
            {
              addSheet: {
                properties: {
                  sheetId: 123,
                  title: "New Sheet",
                },
              },
            },
          ],
        },
      });

      const result = await sheetsTools.sheets_add_sheet.handler({
        spreadsheetId: "sheet123",
        title: "New Sheet",
      });

      expect(result.success).toBe(true);
      expect(mockSheetsApi.spreadsheets.batchUpdate).toHaveBeenCalledWith({
        spreadsheetId: "sheet123",
        requestBody: {
          requests: [
            {
              addSheet: {
                properties: {
                  title: "New Sheet",
                },
              },
            },
          ],
        },
      });
    });
  });

  describe("sheets_get_info - TC-SH07: Getting Spreadsheet Info", () => {
    it("should return spreadsheet metadata", async () => {
      mockSheetsApi.spreadsheets.get.mockResolvedValue({
        data: {
          spreadsheetId: "sheet123",
          properties: {
            title: "My Spreadsheet",
          },
          sheets: [
            {
              properties: {
                sheetId: 0,
                title: "Sheet1",
                gridProperties: {
                  rowCount: 1000,
                  columnCount: 26,
                },
              },
            },
            {
              properties: {
                sheetId: 1,
                title: "Sheet2",
                gridProperties: {
                  rowCount: 500,
                  columnCount: 10,
                },
              },
            },
          ],
        },
      });

      const result = await sheetsTools.sheets_get_info.handler({
        spreadsheetId: "sheet123",
      });

      expect(result.spreadsheetId).toBe("sheet123");
      expect(result.title).toBe("My Spreadsheet");
      expect(result.sheets).toHaveLength(2);
      expect(result.sheets![0]).toEqual({
        sheetId: 0,
        title: "Sheet1",
        rowCount: 1000,
        columnCount: 26,
      });
    });
  });
});
