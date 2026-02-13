/**
 * Exponential backoff retry utility for Google API calls.
 *
 * FR-S4-01: Rate Limiting with Exponential Backoff
 * Handles 429 (Too Many Requests), 500, 502, 503, 504 HTTP errors
 * and network errors (ECONNRESET, ETIMEDOUT, etc.)
 */

export interface RetryOptions {
  maxAttempts?: number; // Default: 3
  initialDelay?: number; // Default: 1000ms
  backoffFactor?: number; // Default: 2
  maxDelay?: number; // Default: 10000ms
  retryableErrors?: number[]; // Default: [429, 500, 502, 503, 504]
}

const NETWORK_ERRORS = [
  "ECONNRESET",
  "ETIMEDOUT",
  "ECONNREFUSED",
  "EPIPE",
  "EAI_AGAIN",
];

function isRetryableError(
  error: unknown,
  retryableStatuses: number[]
): boolean {
  // HTTP status code based retry
  const status = (error as Record<string, unknown> & { response?: { status?: number } })?.response?.status;
  if (status && retryableStatuses.includes(status)) return true;

  // Network error based retry
  const code = (error as Record<string, unknown> & { code?: string })?.code;
  if (code && NETWORK_ERRORS.includes(code)) return true;

  return false;
}

export async function withRetry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {}
): Promise<T> {
  const maxAttempts = options.maxAttempts ?? 3;
  const initialDelay = options.initialDelay ?? 1000;
  const backoffFactor = options.backoffFactor ?? 2;
  const retryableStatuses = options.retryableErrors ?? [
    429, 500, 502, 503, 504,
  ];
  let delay = initialDelay;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error: unknown) {
      if (
        !isRetryableError(error, retryableStatuses) ||
        attempt === maxAttempts
      ) {
        throw error;
      }

      const status =
        (error as Record<string, unknown> & { response?: { status?: number } })?.response?.status ||
        (error as Record<string, unknown> & { code?: string })?.code ||
        "unknown";
      console.warn(
        `[Retry] Attempt ${attempt}/${maxAttempts} failed (${status}). Retrying in ${delay}ms...`
      );
      await new Promise((r) => setTimeout(r, delay));
      delay = Math.min(delay * backoffFactor, options.maxDelay ?? 10000);
    }
  }
  throw new Error("Unreachable");
}
