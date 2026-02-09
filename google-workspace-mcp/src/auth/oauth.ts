import { google } from "googleapis";
import { OAuth2Client } from "google-auth-library";
import * as fs from "fs";
import * as path from "path";
import * as http from "http";
import { URL } from "url";
import open from "open";

// 설정 파일 경로
const CONFIG_DIR = process.env.GOOGLE_CONFIG_DIR || path.join(process.cwd(), ".google-workspace");
const CLIENT_SECRET_PATH = path.join(CONFIG_DIR, "client_secret.json");
const TOKEN_PATH = path.join(CONFIG_DIR, "token.json");

// Google API Scopes
const SCOPES = [
  "https://www.googleapis.com/auth/gmail.modify",
  "https://www.googleapis.com/auth/calendar",
  "https://www.googleapis.com/auth/drive",
  "https://www.googleapis.com/auth/documents",
  "https://www.googleapis.com/auth/spreadsheets",
  "https://www.googleapis.com/auth/presentations",
];

interface ClientSecretConfig {
  installed?: {
    client_id: string;
    client_secret: string;
    redirect_uris: string[];
  };
  web?: {
    client_id: string;
    client_secret: string;
    redirect_uris: string[];
  };
}

interface TokenData {
  access_token: string;
  refresh_token: string;
  scope: string;
  token_type: string;
  expiry_date: number;
}

/**
 * 설정 디렉토리 확인 및 생성
 */
function ensureConfigDir(): void {
  if (!fs.existsSync(CONFIG_DIR)) {
    fs.mkdirSync(CONFIG_DIR, { recursive: true });
  }
}

/**
 * client_secret.json 파일 로드
 */
function loadClientSecret(): ClientSecretConfig {
  if (!fs.existsSync(CLIENT_SECRET_PATH)) {
    throw new Error(
      `client_secret.json 파일이 없습니다.\n` +
      `1. Google Cloud Console에서 OAuth 2.0 클라이언트 ID를 생성하세요.\n` +
      `2. JSON 파일을 다운로드하세요.\n` +
      `3. ${CLIENT_SECRET_PATH}에 저장하세요.`
    );
  }

  const content = fs.readFileSync(CLIENT_SECRET_PATH, "utf-8");
  return JSON.parse(content);
}

/**
 * OAuth2 클라이언트 생성
 */
function createOAuth2Client(config: ClientSecretConfig): OAuth2Client {
  const credentials = config.installed || config.web;
  if (!credentials) {
    throw new Error("client_secret.json 형식이 올바르지 않습니다.");
  }

  return new google.auth.OAuth2(
    credentials.client_id,
    credentials.client_secret,
    "http://localhost:3000/callback"
  );
}

/**
 * 저장된 토큰 로드
 */
function loadToken(): TokenData | null {
  if (!fs.existsSync(TOKEN_PATH)) {
    return null;
  }

  const content = fs.readFileSync(TOKEN_PATH, "utf-8");
  return JSON.parse(content);
}

/**
 * 토큰 저장
 */
function saveToken(token: TokenData): void {
  ensureConfigDir();
  fs.writeFileSync(TOKEN_PATH, JSON.stringify(token, null, 2));
}

/**
 * 브라우저에서 로그인 후 콜백 처리
 */
async function getTokenFromBrowser(oauth2Client: OAuth2Client): Promise<TokenData> {
  const authUrl = oauth2Client.generateAuthUrl({
    access_type: "offline",
    scope: SCOPES,
    prompt: "consent",
  });

  return new Promise((resolve, reject) => {
    let timeoutId: NodeJS.Timeout;

    const server = http.createServer(async (req, res) => {
      try {
        const url = new URL(req.url || "", "http://localhost:3000");

        if (url.pathname === "/callback") {
          const code = url.searchParams.get("code");

          if (!code) {
            res.writeHead(400, { "Content-Type": "text/html; charset=utf-8" });
            res.end("<h1>오류: 인증 코드가 없습니다.</h1>");
            clearTimeout(timeoutId);
            reject(new Error("인증 코드가 없습니다."));
            return;
          }

          const { tokens } = await oauth2Client.getToken(code);
          oauth2Client.setCredentials(tokens);

          res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
          res.end(`
            <html>
              <head><title>인증 완료</title></head>
              <body style="font-family: sans-serif; text-align: center; padding: 50px;">
                <h1>Google 인증이 완료되었습니다!</h1>
                <p>이 창을 닫고 Claude로 돌아가세요.</p>
              </body>
            </html>
          `);

          clearTimeout(timeoutId);
          server.close();
          resolve(tokens as TokenData);
        }
      } catch (error) {
        res.writeHead(500, { "Content-Type": "text/html; charset=utf-8" });
        res.end("<h1>오류가 발생했습니다.</h1>");
        clearTimeout(timeoutId);
        reject(error);
      }
    });

    server.listen(3000, () => {
      console.error("\n========================================");
      console.error("Google 로그인이 필요합니다!");
      console.error("========================================");
      console.error("\n아래 URL을 브라우저에서 열어주세요:\n");
      console.error(authUrl);
      console.error("\n========================================\n");

      // Docker 외부에서는 자동으로 브라우저 열기 시도
      open(authUrl).catch(() => {
        // Docker 내부에서는 실패해도 무시 (URL이 이미 출력됨)
      });
    });

    // 5분 타임아웃
    timeoutId = setTimeout(() => {
      server.close();
      reject(new Error("로그인 타임아웃 (5분)"));
    }, 5 * 60 * 1000);
  });
}

/**
 * 인증된 OAuth2 클라이언트 가져오기
 */
export async function getAuthenticatedClient(): Promise<OAuth2Client> {
  ensureConfigDir();

  const config = loadClientSecret();
  const oauth2Client = createOAuth2Client(config);

  // 저장된 토큰 확인
  const token = loadToken();

  if (token) {
    oauth2Client.setCredentials(token);

    // 토큰 만료 확인 및 갱신
    if (token.expiry_date && token.expiry_date < Date.now()) {
      console.error("토큰이 만료되어 갱신합니다...");
      try {
        const { credentials } = await oauth2Client.refreshAccessToken();
        saveToken(credentials as TokenData);
        oauth2Client.setCredentials(credentials);
      } catch (error) {
        console.error("토큰 갱신 실패, 다시 로그인합니다...");
        const newToken = await getTokenFromBrowser(oauth2Client);
        saveToken(newToken);
      }
    }

    return oauth2Client;
  }

  // 새로 로그인
  console.error("Google 로그인이 필요합니다...");
  const newToken = await getTokenFromBrowser(oauth2Client);
  saveToken(newToken);

  return oauth2Client;
}

/**
 * Google API 서비스 인스턴스 생성
 */
export async function getGoogleServices() {
  const auth = await getAuthenticatedClient();

  return {
    gmail: google.gmail({ version: "v1", auth }),
    calendar: google.calendar({ version: "v3", auth }),
    drive: google.drive({ version: "v3", auth }),
    docs: google.docs({ version: "v1", auth }),
    sheets: google.sheets({ version: "v4", auth }),
    slides: google.slides({ version: "v1", auth }),
  };
}
