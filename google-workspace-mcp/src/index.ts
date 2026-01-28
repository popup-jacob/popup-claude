import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

import { gmailTools } from "./tools/gmail.js";
import { calendarTools } from "./tools/calendar.js";
import { driveTools } from "./tools/drive.js";
import { docsTools } from "./tools/docs.js";
import { sheetsTools } from "./tools/sheets.js";
import { slidesTools } from "./tools/slides.js";

const server = new McpServer({
  name: "google-workspace-mcp",
  version: "0.1.0",
});

// 모든 도구 등록
const allTools = {
  ...gmailTools,
  ...calendarTools,
  ...driveTools,
  ...docsTools,
  ...sheetsTools,
  ...slidesTools,
};

// 도구 등록
for (const [name, tool] of Object.entries(allTools)) {
  server.tool(
    name,
    tool.description,
    tool.schema,
    async (params: any) => {
      try {
        const result = await tool.handler(params);
        return {
          content: [
            {
              type: "text" as const,
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      } catch (error: any) {
        return {
          content: [
            {
              type: "text" as const,
              text: `오류: ${error.message}`,
            },
          ],
          isError: true,
        };
      }
    }
  );
}

// 서버 시작
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Google Workspace MCP Server running on stdio");
}

main().catch((error) => {
  console.error("서버 시작 실패:", error);
  process.exit(1);
});
