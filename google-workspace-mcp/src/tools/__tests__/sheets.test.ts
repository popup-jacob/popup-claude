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

/* ------------------------------------------------------------------ */
/*  TC-SHT-002 ~ TC-SHT-010: Sheets additional coverage tests        */
/* ------------------------------------------------------------------ */

describe("Sheets Tools - TC-SHT-003: sheets_get_info with multiple sheets", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should return all sheet metadata with index and grid properties", async () => {
    mockSheetsApi.spreadsheets.get.mockResolvedValue({
      data: {
        spreadsheetId: "infoSheet1",
        properties: {
          title: "Multi Sheet",
          locale: "en_US",
        },
        sheets: [
          {
            properties: {
              sheetId: 0,
              title: "Data",
              index: 0,
              gridProperties: { rowCount: 500, columnCount: 20 },
            },
          },
          {
            properties: {
              sheetId: 1,
              title: "Summary",
              index: 1,
              gridProperties: { rowCount: 100, columnCount: 5 },
            },
          },
          {
            properties: {
              sheetId: 2,
              title: "Charts",
              index: 2,
              gridProperties: { rowCount: 200, columnCount: 10 },
            },
          },
        ],
      },
    });

    const result = await sheetsTools.sheets_get_info.handler({
      spreadsheetId: "infoSheet1",
    });

    expect(result.spreadsheetId).toBe("infoSheet1");
    expect(result.title).toBe("Multi Sheet");
    expect(result.locale).toBe("en_US");
    expect(result.sheets).toHaveLength(3);
  });

  it("should handle spreadsheet with no sheets", async () => {
    mockSheetsApi.spreadsheets.get.mockResolvedValue({
      data: {
        spreadsheetId: "emptySheets",
        properties: { title: "Empty" },
        sheets: [],
      },
    });

    const result = await sheetsTools.sheets_get_info.handler({
      spreadsheetId: "emptySheets",
    });

    expect(result.spreadsheetId).toBe("emptySheets");
    expect(result.sheets).toEqual([]);
  });
});

describe("Sheets Tools - TC-SHT-005: sheets_read_multiple ranges", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should read multiple ranges in a single batchGet call", async () => {
    mockSheetsApi.spreadsheets.values.batchGet.mockResolvedValue({
      data: {
        valueRanges: [
          {
            range: "Sheet1!A1:B2",
            values: [
              ["Name", "Score"],
              ["Alice", "95"],
            ],
          },
          {
            range: "Sheet2!A1:A3",
            values: [["Total"], ["100"], ["200"]],
          },
        ],
      },
    });

    const result = await sheetsTools.sheets_read_multiple.handler({
      spreadsheetId: "multiSheet1",
      ranges: ["Sheet1!A1:B2", "Sheet2!A1:A3"],
    });

    expect(mockSheetsApi.spreadsheets.values.batchGet).toHaveBeenCalledWith({
      spreadsheetId: "multiSheet1",
      ranges: ["Sheet1!A1:B2", "Sheet2!A1:A3"],
    });

    expect(result.spreadsheetId).toBe("multiSheet1");
    expect(result.valueRanges).toHaveLength(2);
    expect(result.valueRanges![0].range).toBe("Sheet1!A1:B2");
    expect(result.valueRanges![0].values).toEqual([
      ["Name", "Score"],
      ["Alice", "95"],
    ]);
  });

  it("should handle empty values in some ranges", async () => {
    mockSheetsApi.spreadsheets.values.batchGet.mockResolvedValue({
      data: {
        valueRanges: [{ range: "Sheet1!A1:A5", values: [["Data1"]] }, { range: "Sheet1!C1:C5" }],
      },
    });

    const result = await sheetsTools.sheets_read_multiple.handler({
      spreadsheetId: "multiSheet2",
      ranges: ["Sheet1!A1:A5", "Sheet1!C1:C5"],
    });

    expect(result.valueRanges).toHaveLength(2);
    expect(result.valueRanges![0].values).toEqual([["Data1"]]);
    expect(result.valueRanges![1].values).toEqual([]);
  });
});

describe("Sheets Tools - TC-SHT-010: sheets_delete_sheet", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should delete a sheet by sheetId using batchUpdate", async () => {
    mockSheetsApi.spreadsheets.batchUpdate.mockResolvedValue({
      data: { replies: [{}] },
    });

    const result = await sheetsTools.sheets_delete_sheet.handler({
      spreadsheetId: "delSheet1",
      sheetId: 42,
    });

    expect(result.success).toBe(true);
    expect(mockSheetsApi.spreadsheets.batchUpdate).toHaveBeenCalledWith({
      spreadsheetId: "delSheet1",
      requestBody: {
        requests: [{ deleteSheet: { sheetId: 42 } }],
      },
    });
  });

  it("should return success message", async () => {
    mockSheetsApi.spreadsheets.batchUpdate.mockResolvedValue({
      data: { replies: [{}] },
    });

    const result = await sheetsTools.sheets_delete_sheet.handler({
      spreadsheetId: "delSheet2",
      sheetId: 0,
    });

    expect(result.success).toBe(true);
    expect(result.message).toBe("Sheet deleted.");
  });
});

/* ------------------------------------------------------------------ */
/*  sheets_rename_sheet / sheets_format_cells / sheets_auto_resize      */
/* ------------------------------------------------------------------ */

describe("Sheets Tools - sheets_rename_sheet", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should rename a sheet using updateSheetProperties", async () => {
    mockSheetsApi.spreadsheets.batchUpdate.mockResolvedValue({
      data: { replies: [{}] },
    });

    const result = await sheetsTools.sheets_rename_sheet.handler({
      spreadsheetId: "renameSheet1",
      sheetId: 0,
      newTitle: "Renamed Sheet",
    });

    expect(result.success).toBe(true);
    expect(result.message).toContain("Renamed Sheet");
    expect(mockSheetsApi.spreadsheets.batchUpdate).toHaveBeenCalledWith({
      spreadsheetId: "renameSheet1",
      requestBody: {
        requests: [
          {
            updateSheetProperties: {
              properties: {
                sheetId: 0,
                title: "Renamed Sheet",
              },
              fields: "title",
            },
          },
        ],
      },
    });
  });
});

describe("Sheets Tools - sheets_format_cells", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should format cells with bold only", async () => {
    mockSheetsApi.spreadsheets.batchUpdate.mockResolvedValue({
      data: { replies: [{}] },
    });

    const result = await sheetsTools.sheets_format_cells.handler({
      spreadsheetId: "fmtSheet1",
      sheetId: 0,
      startRow: 0,
      endRow: 1,
      startColumn: 0,
      endColumn: 3,
      bold: true,
    });

    expect(result.success).toBe(true);
    const call = mockSheetsApi.spreadsheets.batchUpdate.mock.calls[0][0];
    const repeatCell = call.requestBody.requests[0].repeatCell;
    expect(repeatCell.cell.userEnteredFormat.textFormat).toEqual({ bold: true });
    expect(repeatCell.fields).toBe("userEnteredFormat.textFormat.bold");
  });

  it("should format cells with backgroundColor only", async () => {
    mockSheetsApi.spreadsheets.batchUpdate.mockResolvedValue({
      data: { replies: [{}] },
    });

    const result = await sheetsTools.sheets_format_cells.handler({
      spreadsheetId: "fmtSheet2",
      sheetId: 0,
      startRow: 0,
      endRow: 5,
      startColumn: 0,
      endColumn: 5,
      backgroundColor: "#FF0000",
    });

    expect(result.success).toBe(true);
    const call = mockSheetsApi.spreadsheets.batchUpdate.mock.calls[0][0];
    const repeatCell = call.requestBody.requests[0].repeatCell;
    expect(repeatCell.cell.userEnteredFormat.backgroundColor).toEqual({
      red: 1,
      green: 0,
      blue: 0,
    });
    expect(repeatCell.fields).toBe("userEnteredFormat.backgroundColor");
  });

  it("should format cells with both bold and backgroundColor", async () => {
    mockSheetsApi.spreadsheets.batchUpdate.mockResolvedValue({
      data: { replies: [{}] },
    });

    const result = await sheetsTools.sheets_format_cells.handler({
      spreadsheetId: "fmtSheet3",
      sheetId: 1,
      startRow: 2,
      endRow: 4,
      startColumn: 1,
      endColumn: 3,
      bold: true,
      backgroundColor: "#00FF00",
    });

    expect(result.success).toBe(true);
    const call = mockSheetsApi.spreadsheets.batchUpdate.mock.calls[0][0];
    const repeatCell = call.requestBody.requests[0].repeatCell;
    expect(repeatCell.range.sheetId).toBe(1);
    expect(repeatCell.range.startRowIndex).toBe(2);
    expect(repeatCell.range.endRowIndex).toBe(4);
    expect(repeatCell.fields).toContain("userEnteredFormat.textFormat.bold");
    expect(repeatCell.fields).toContain("userEnteredFormat.backgroundColor");
  });
});

describe("Sheets Tools - sheets_auto_resize", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should auto-resize columns using autoResizeDimensions", async () => {
    mockSheetsApi.spreadsheets.batchUpdate.mockResolvedValue({
      data: { replies: [{}] },
    });

    const result = await sheetsTools.sheets_auto_resize.handler({
      spreadsheetId: "resizeSheet1",
      sheetId: 0,
      startColumn: 0,
      endColumn: 10,
    });

    expect(result.success).toBe(true);
    expect(result.message).toBe("Column widths auto-resized.");
    expect(mockSheetsApi.spreadsheets.batchUpdate).toHaveBeenCalledWith({
      spreadsheetId: "resizeSheet1",
      requestBody: {
        requests: [
          {
            autoResizeDimensions: {
              dimensions: {
                sheetId: 0,
                dimension: "COLUMNS",
                startIndex: 0,
                endIndex: 10,
              },
            },
          },
        ],
      },
    });
  });
});
