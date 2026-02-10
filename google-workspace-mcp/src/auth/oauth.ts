import { google } from "googleapis";
import { OAuth2Client } from "google-auth-library";
import * as fs from "fs";
import * as path from "path";
import * as http from "http";
import { URL } from "url";
import open from "open";

// Config file paths
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
 * Ensure config directory exists
 */
function ensureConfigDir(): void {
  if (!fs.existsSync(CONFIG_DIR)) {
    fs.mkdirSync(CONFIG_DIR, { recursive: true });
  }
}

/**
 * Load client_secret.json
 */
function loadClientSecret(): ClientSecretConfig {
  if (!fs.existsSync(CLIENT_SECRET_PATH)) {
    throw new Error(
      `client_secret.json not found.\n` +
      `1. Create an OAuth 2.0 Client ID in Google Cloud Console.\n` +
      `2. Download the JSON file.\n` +
      `3. Save it to ${CLIENT_SECRET_PATH}.`
    );
  }

  const content = fs.readFileSync(CLIENT_SECRET_PATH, "utf-8");
  return JSON.parse(content);
}

/**
 * Create OAuth2 client
 */
function createOAuth2Client(config: ClientSecretConfig): OAuth2Client {
  const credentials = config.installed || config.web;
  if (!credentials) {
    throw new Error("Invalid client_secret.json format.");
  }

  return new google.auth.OAuth2(
    credentials.client_id,
    credentials.client_secret,
    "http://localhost:3000/callback"
  );
}

/**
 * Load saved token
 */
function loadToken(): TokenData | null {
  if (!fs.existsSync(TOKEN_PATH)) {
    return null;
  }

  const content = fs.readFileSync(TOKEN_PATH, "utf-8");
  return JSON.parse(content);
}

/**
 * Save token
 */
function saveToken(token: TokenData): void {
  ensureConfigDir();
  fs.writeFileSync(TOKEN_PATH, JSON.stringify(token, null, 2));
}

/**
 * Handle OAuth callback from browser login
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
            res.end("<h1>Error: No authorization code received.</h1>");
            clearTimeout(timeoutId);
            reject(new Error("No authorization code received."));
            return;
          }

          const { tokens } = await oauth2Client.getToken(code);
          oauth2Client.setCredentials(tokens);

          res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
          res.end(`
            <html>
              <head><title>Authentication Complete</title></head>
              <body style="font-family: sans-serif; text-align: center; padding: 50px;">
                <h1>Google authentication complete!</h1>
                <p>You can close this window and return to Claude.</p>
              </body>
            </html>
          `);

          clearTimeout(timeoutId);
          server.close();
          resolve(tokens as TokenData);
        }
      } catch (error) {
        res.writeHead(500, { "Content-Type": "text/html; charset=utf-8" });
        res.end("<h1>An error occurred.</h1>");
        clearTimeout(timeoutId);
        reject(error);
      }
    });

    server.listen(3000, () => {
      console.error("\n========================================");
      console.error("Google Login Required!");
      console.error("========================================");
      console.error("\nOpen the following URL in your browser:\n");
      console.error(authUrl);
      console.error("\n========================================\n");

      // Try to open browser automatically (fails silently inside Docker)
      open(authUrl).catch(() => {});
    });

    // 5 minute timeout
    timeoutId = setTimeout(() => {
      server.close();
      reject(new Error("Login timeout (5 minutes)"));
    }, 5 * 60 * 1000);
  });
}

/**
 * Get authenticated OAuth2 client
 */
export async function getAuthenticatedClient(): Promise<OAuth2Client> {
  ensureConfigDir();

  const config = loadClientSecret();
  const oauth2Client = createOAuth2Client(config);

  // Check for saved token
  const token = loadToken();

  if (token) {
    oauth2Client.setCredentials(token);

    // Check token expiry and refresh
    if (token.expiry_date && token.expiry_date < Date.now()) {
      console.error("Token expired, refreshing...");
      try {
        const { credentials } = await oauth2Client.refreshAccessToken();
        saveToken(credentials as TokenData);
        oauth2Client.setCredentials(credentials);
      } catch (error) {
        console.error("Token refresh failed, re-authenticating...");
        const newToken = await getTokenFromBrowser(oauth2Client);
        saveToken(newToken);
      }
    }

    return oauth2Client;
  }

  // New login required
  console.error("Google login required...");
  const newToken = await getTokenFromBrowser(oauth2Client);
  saveToken(newToken);

  return oauth2Client;
}

/**
 * Create Google API service instances
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
