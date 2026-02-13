import { google } from "googleapis";
import type { gmail_v1 } from "googleapis";
import type { calendar_v3 } from "googleapis";
import type { drive_v3 } from "googleapis";
import type { docs_v1 } from "googleapis";
import type { sheets_v4 } from "googleapis";
import type { slides_v1 } from "googleapis";
import { OAuth2Client } from "google-auth-library";
import * as fs from "fs";
import * as path from "path";
import * as http from "http";
import * as crypto from "crypto";
import { URL } from "url";
import open from "open";

// Config file paths
const CONFIG_DIR =
  process.env.GOOGLE_CONFIG_DIR ||
  path.join(process.cwd(), ".google-workspace");
const CLIENT_SECRET_PATH = path.join(CONFIG_DIR, "client_secret.json");
const TOKEN_PATH = path.join(CONFIG_DIR, "token.json");

// OAuth callback port (dynamic via env var)
const OAUTH_PORT = parseInt(process.env.OAUTH_PORT || "3000", 10);

// ----- FR-S4-02: Dynamic OAuth Scope -----
const SCOPE_MAP: Record<string, string[]> = {
  gmail: ["https://www.googleapis.com/auth/gmail.modify"],
  calendar: ["https://www.googleapis.com/auth/calendar"],
  drive: ["https://www.googleapis.com/auth/drive"],
  docs: ["https://www.googleapis.com/auth/documents"],
  sheets: ["https://www.googleapis.com/auth/spreadsheets"],
  slides: ["https://www.googleapis.com/auth/presentations"],
};

function resolveScopes(): string[] {
  const envScopes = process.env.GOOGLE_SCOPES;
  if (!envScopes) return Object.values(SCOPE_MAP).flat();
  return envScopes
    .split(",")
    .map((s) => s.trim().toLowerCase())
    .flatMap((s) => SCOPE_MAP[s] || [s]);
}

const SCOPES = resolveScopes();

// ----- FR-S3-10: Security Event Logging -----
function logSecurityEvent(
  eventType: string,
  result: "success" | "failure",
  detail?: string
): void {
  const entry = {
    timestamp: new Date().toISOString(),
    event_type: eventType,
    result,
    detail: detail || "",
  };
  console.error(`[SECURITY] ${JSON.stringify(entry)}`);
}

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

// ----- FR-S4-04: Service Instance Caching -----
interface GoogleServices {
  gmail: gmail_v1.Gmail;
  calendar: calendar_v3.Calendar;
  drive: drive_v3.Drive;
  docs: docs_v1.Docs;
  sheets: sheets_v4.Sheets;
  slides: slides_v1.Slides;
}

interface ServiceCache {
  services: GoogleServices;
  createdAt: number;
}

const CACHE_TTL_MS = 50 * 60 * 1000; // 50 minutes
let serviceCache: ServiceCache | null = null;

// ----- FR-S4-06: Auth Mutex -----
let authInProgress: Promise<OAuth2Client> | null = null;

/**
 * Ensure config directory exists with restrictive permissions.
 *
 * The config directory contains:
 *   - client_secret.json (OAuth client credentials)
 *   - token.json (OAuth access/refresh tokens)
 *
 * Both are sensitive. The directory MUST be owner-only (mode 0700).
 *
 * FR-S1-08: Config Directory Permissions
 */
function ensureConfigDir(): void {
  if (!fs.existsSync(CONFIG_DIR)) {
    fs.mkdirSync(CONFIG_DIR, { recursive: true, mode: 0o700 });
  }

  // Defensive: fix permissions if directory already existed with weaker mode
  try {
    const stats = fs.statSync(CONFIG_DIR);
    const currentMode = stats.mode & 0o777;
    if (currentMode !== 0o700) {
      fs.chmodSync(CONFIG_DIR, 0o700);
      logSecurityEvent("config_dir_permission_fix", "success", `${CONFIG_DIR}: ${currentMode.toString(8)} -> 700`);
    }
  } catch {
    // chmodSync may fail on Windows -- acceptable since Windows uses ACLs
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
    `http://localhost:${OAUTH_PORT}/callback`
  );
}

/**
 * Load saved token with refresh_token validation.
 *
 * FR-S4-05: Token refresh_token Validity Check
 */
function loadToken(): TokenData | null {
  if (!fs.existsSync(TOKEN_PATH)) {
    return null;
  }

  const content = fs.readFileSync(TOKEN_PATH, "utf-8");
  const token: TokenData = JSON.parse(content);

  // FR-S4-05: Validate refresh_token exists
  if (!token.refresh_token) {
    logSecurityEvent("token_load", "failure", "Missing refresh_token -- re-authentication required");
    return null;
  }

  return token;
}

/**
 * Save token to disk with restrictive permissions.
 *
 * The token file contains OAuth access_token and refresh_token.
 * It MUST be readable only by the file owner (mode 0600).
 *
 * On Windows, Node.js ignores the mode parameter -- Windows ACLs
 * are inherited from the parent directory. For Docker-based usage
 * (the primary deployment model), Linux permissions apply.
 *
 * FR-S1-07: Token File Permissions
 */
function saveToken(token: TokenData): void {
  ensureConfigDir();
  fs.writeFileSync(TOKEN_PATH, JSON.stringify(token, null, 2), {
    mode: 0o600,
  });

  // Defensive: explicitly set permissions in case the file already existed
  // with different permissions from a previous version
  try {
    fs.chmodSync(TOKEN_PATH, 0o600);
    logSecurityEvent("token_save", "success", TOKEN_PATH);
  } catch {
    // chmodSync may fail on Windows -- acceptable since Windows
    // uses ACLs inherited from the parent directory
  }
}

/**
 * Handle OAuth callback from browser login.
 * Generates a cryptographic state token for CSRF protection (RFC 6749 Section 10.12).
 *
 * FR-S1-01: OAuth State Parameter (CSRF Prevention)
 */
async function getTokenFromBrowser(
  oauth2Client: OAuth2Client
): Promise<TokenData> {
  // Generate cryptographically random state parameter (32 bytes = 64 hex chars)
  const state = crypto.randomBytes(32).toString("hex");

  const authUrl = oauth2Client.generateAuthUrl({
    access_type: "offline",
    scope: SCOPES,
    prompt: "consent",
    state,
  });

  return new Promise((resolve, reject) => {
    // eslint-disable-next-line prefer-const
    let timeoutId: NodeJS.Timeout;

    const server = http.createServer(async (req, res) => {
      try {
        const url = new URL(
          req.url || "",
          `http://localhost:${OAUTH_PORT}`
        );

        if (url.pathname === "/callback") {
          // --- STATE VALIDATION (CSRF protection) ---
          const receivedState = url.searchParams.get("state");
          if (receivedState !== state) {
            res.writeHead(403, {
              "Content-Type": "text/html; charset=utf-8",
            });
            res.end(`
              <html>
                <head><title>Authentication Failed</title></head>
                <body style="font-family: sans-serif; text-align: center; padding: 50px;">
                  <h1>Authentication failed: Invalid state parameter</h1>
                  <p>This may indicate a CSRF attack. Please try again.</p>
                </body>
              </html>
            `);
            clearTimeout(timeoutId);
            server.close();
            logSecurityEvent("oauth_callback", "failure", "State mismatch -- possible CSRF attack");
            reject(
              new Error("OAuth state mismatch - possible CSRF attack")
            );
            return;
          }

          const code = url.searchParams.get("code");

          if (!code) {
            res.writeHead(400, {
              "Content-Type": "text/html; charset=utf-8",
            });
            res.end("<h1>Error: No authorization code received.</h1>");
            clearTimeout(timeoutId);
            server.close();
            reject(new Error("No authorization code received."));
            return;
          }

          const { tokens } = await oauth2Client.getToken(code);
          oauth2Client.setCredentials(tokens);

          res.writeHead(200, {
            "Content-Type": "text/html; charset=utf-8",
          });
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
          logSecurityEvent("oauth_callback", "success", "Token obtained via browser flow");
          resolve(tokens as TokenData);
        }
      } catch (error) {
        res.writeHead(500, {
          "Content-Type": "text/html; charset=utf-8",
        });
        res.end("<h1>An error occurred.</h1>");
        clearTimeout(timeoutId);
        server.close();
        reject(error);
      }
    });

    server.listen(OAUTH_PORT, () => {
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
 * Get authenticated OAuth2 client.
 *
 * FR-S4-06: Auth Mutex -- prevents concurrent auth requests via Promise-based lock.
 * FR-S4-05: Token refresh_token validation with 5-minute expiry buffer.
 */
export async function getAuthenticatedClient(): Promise<OAuth2Client> {
  // FR-S4-06: Prevent concurrent auth requests
  if (authInProgress) {
    return authInProgress;
  }

  const authPromise = (async () => {
    try {
      ensureConfigDir();

      const config = loadClientSecret();
      const oauth2Client = createOAuth2Client(config);

      // Check for saved token
      const token = loadToken();

      if (token) {
        oauth2Client.setCredentials(token);

        // FR-S4-05: Check token expiry with 5-minute buffer
        const expiryBuffer = 5 * 60 * 1000;
        if (
          token.expiry_date &&
          token.expiry_date < Date.now() + expiryBuffer
        ) {
          console.error("Token expired, refreshing...");
          logSecurityEvent("token_refresh", "success", "Token expiry approaching, refreshing");
          try {
            const { credentials } =
              await oauth2Client.refreshAccessToken();
            saveToken(credentials as TokenData);
            oauth2Client.setCredentials(credentials);
          } catch (_error) {
            logSecurityEvent("token_refresh", "failure", "Refresh failed, re-authenticating");
            console.error(
              "Token refresh failed, re-authenticating..."
            );
            const newToken =
              await getTokenFromBrowser(oauth2Client);
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
    } finally {
      authInProgress = null;
    }
  })();

  authInProgress = authPromise;
  return authPromise;
}

/**
 * Create Google API service instances with caching.
 *
 * FR-S4-04: Service Instance Caching -- singleton pattern with TTL.
 * Reuses service instances for up to 50 minutes, avoiding unnecessary
 * OAuth checks on every tool call (69+ handlers).
 */
export async function getGoogleServices(): Promise<GoogleServices> {
  if (serviceCache && Date.now() - serviceCache.createdAt < CACHE_TTL_MS) {
    return serviceCache.services;
  }

  const auth = await getAuthenticatedClient();
  const services: GoogleServices = {
    gmail: google.gmail({ version: "v1", auth }),
    calendar: google.calendar({ version: "v3", auth }),
    drive: google.drive({ version: "v3", auth }),
    docs: google.docs({ version: "v1", auth }),
    sheets: google.sheets({ version: "v4", auth }),
    slides: google.slides({ version: "v1", auth }),
  };

  serviceCache = { services, createdAt: Date.now() };
  return services;
}

/**
 * Clear the service cache. Exported for testing purposes.
 * FR-S4-04: Test utility
 */
export function clearServiceCache(): void {
  serviceCache = null;
}
