import { describe, it, expect, vi } from "vitest";
import { withRetry } from "../retry.js";

describe("withRetry", () => {
  it("should return result on first success", async () => {
    const fn = vi.fn().mockResolvedValue("success");
    const result = await withRetry(fn);
    expect(result).toBe("success");
    expect(fn).toHaveBeenCalledTimes(1);
  });

  it("should retry on 429 status", async () => {
    const fn = vi
      .fn()
      .mockRejectedValueOnce({ response: { status: 429 } })
      .mockResolvedValue("retry success");

    const result = await withRetry(fn, { initialDelay: 10 });
    expect(result).toBe("retry success");
    expect(fn).toHaveBeenCalledTimes(2);
  });

  it("should retry on 503 status", async () => {
    const fn = vi
      .fn()
      .mockRejectedValueOnce({ response: { status: 503 } })
      .mockResolvedValue("ok");

    const result = await withRetry(fn, { initialDelay: 10 });
    expect(result).toBe("ok");
    expect(fn).toHaveBeenCalledTimes(2);
  });

  it("should retry on network errors", async () => {
    const fn = vi.fn().mockRejectedValueOnce({ code: "ECONNRESET" }).mockResolvedValue("recovered");

    const result = await withRetry(fn, { initialDelay: 10 });
    expect(result).toBe("recovered");
    expect(fn).toHaveBeenCalledTimes(2);
  });

  it("should throw on non-retryable error", async () => {
    const fn = vi.fn().mockRejectedValue(new Error("Not Found"));

    await expect(withRetry(fn, { initialDelay: 10 })).rejects.toThrow("Not Found");
    expect(fn).toHaveBeenCalledTimes(1);
  });

  it("should throw after max attempts", async () => {
    const fn = vi.fn().mockRejectedValue({ response: { status: 429 } });

    await expect(withRetry(fn, { maxAttempts: 3, initialDelay: 10 })).rejects.toEqual({
      response: { status: 429 },
    });
    expect(fn).toHaveBeenCalledTimes(3);
  });

  it("should respect maxDelay", async () => {
    const start = Date.now();
    const fn = vi
      .fn()
      .mockRejectedValueOnce({ response: { status: 500 } })
      .mockRejectedValueOnce({ response: { status: 500 } })
      .mockResolvedValue("ok");

    await withRetry(fn, {
      initialDelay: 10,
      backoffFactor: 100,
      maxDelay: 50,
    });
    const elapsed = Date.now() - start;
    // Should not exceed much beyond 60ms (10 + 50)
    expect(elapsed).toBeLessThan(200);
  });
});

/* ------------------------------------------------------------------ */
/*  TC-PER-002 ~ TC-PER-018: Retry & Performance additional tests     */
/* ------------------------------------------------------------------ */

describe("withRetry - retryable HTTP status codes", () => {
  it("TC-PER-002: should retry on 500 Internal Server Error", async () => {
    const fn = vi
      .fn()
      .mockRejectedValueOnce({ response: { status: 500 } })
      .mockResolvedValue("recovered from 500");

    const result = await withRetry(fn, { initialDelay: 10 });
    expect(result).toBe("recovered from 500");
    expect(fn).toHaveBeenCalledTimes(2);
  });

  it("TC-PER-003: should retry on 502 Bad Gateway", async () => {
    const fn = vi
      .fn()
      .mockRejectedValueOnce({ response: { status: 502 } })
      .mockResolvedValue("recovered from 502");

    const result = await withRetry(fn, { initialDelay: 10 });
    expect(result).toBe("recovered from 502");
    expect(fn).toHaveBeenCalledTimes(2);
  });

  it("TC-PER-004: should retry on 504 Gateway Timeout", async () => {
    const fn = vi
      .fn()
      .mockRejectedValueOnce({ response: { status: 504 } })
      .mockResolvedValue("recovered from 504");

    const result = await withRetry(fn, { initialDelay: 10 });
    expect(result).toBe("recovered from 504");
    expect(fn).toHaveBeenCalledTimes(2);
  });
});

describe("withRetry - non-retryable HTTP status codes", () => {
  it("TC-PER-005: should NOT retry on 403 Forbidden", async () => {
    const error = { response: { status: 403 }, message: "Forbidden" };
    const fn = vi.fn().mockRejectedValue(error);

    await expect(withRetry(fn, { initialDelay: 10 })).rejects.toEqual(error);
    expect(fn).toHaveBeenCalledTimes(1);
  });

  it("TC-PER-006: should NOT retry on 404 Not Found", async () => {
    const error = { response: { status: 404 }, message: "Not Found" };
    const fn = vi.fn().mockRejectedValue(error);

    await expect(withRetry(fn, { initialDelay: 10 })).rejects.toEqual(error);
    expect(fn).toHaveBeenCalledTimes(1);
  });
});

describe("withRetry - network error codes", () => {
  it("TC-PER-007: should retry on ECONNRESET", async () => {
    const fn = vi
      .fn()
      .mockRejectedValueOnce({ code: "ECONNRESET" })
      .mockResolvedValue("reconnected");

    const result = await withRetry(fn, { initialDelay: 10 });
    expect(result).toBe("reconnected");
    expect(fn).toHaveBeenCalledTimes(2);
  });

  it("TC-PER-008: should retry on ETIMEDOUT", async () => {
    const fn = vi
      .fn()
      .mockRejectedValueOnce({ code: "ETIMEDOUT" })
      .mockResolvedValue("reconnected");

    const result = await withRetry(fn, { initialDelay: 10 });
    expect(result).toBe("reconnected");
    expect(fn).toHaveBeenCalledTimes(2);
  });

  it("TC-PER-009: should retry on ECONNREFUSED", async () => {
    const fn = vi
      .fn()
      .mockRejectedValueOnce({ code: "ECONNREFUSED" })
      .mockResolvedValue("reconnected");

    const result = await withRetry(fn, { initialDelay: 10 });
    expect(result).toBe("reconnected");
    expect(fn).toHaveBeenCalledTimes(2);
  });
});

describe("withRetry - delay and backoff options", () => {
  it("TC-PER-011: should respect custom maxAttempts", async () => {
    const fn = vi.fn().mockRejectedValue({ response: { status: 503 } });

    await expect(withRetry(fn, { maxAttempts: 2, initialDelay: 10 })).rejects.toEqual({
      response: { status: 503 },
    });
    expect(fn).toHaveBeenCalledTimes(2);
  });
});

describe("withRetry - successful retry scenarios", () => {
  it("TC-PER-013: should succeed after failing twice then succeeding on 3rd attempt", async () => {
    const fn = vi
      .fn()
      .mockRejectedValueOnce({ response: { status: 500 } })
      .mockRejectedValueOnce({ response: { status: 502 } })
      .mockResolvedValue("third time is the charm");

    const result = await withRetry(fn, { maxAttempts: 3, initialDelay: 10 });
    expect(result).toBe("third time is the charm");
    expect(fn).toHaveBeenCalledTimes(3);
  });
});

describe("withRetry - error and result preservation", () => {
  it("TC-PER-015: should preserve the full error object including response body", async () => {
    const apiError = {
      response: {
        status: 500,
        data: { error: { message: "Internal failure", code: 500 } },
      },
      message: "Request failed with status 500",
    };
    const fn = vi.fn().mockRejectedValue(apiError);

    await expect(withRetry(fn, { maxAttempts: 2, initialDelay: 10 })).rejects.toEqual(apiError);
  });

  it("TC-PER-016: should return the resolved value from the wrapped function", async () => {
    const payload = { files: [{ id: "abc", name: "doc.txt" }], nextPageToken: "xyz" };
    const fn = vi.fn().mockResolvedValue(payload);

    const result = await withRetry(fn);
    expect(result).toEqual(payload);
    expect((result as typeof payload).files[0].id).toBe("abc");
  });
});

describe("withRetry - concurrency", () => {
  it("TC-PER-017: concurrent calls should operate independently", async () => {
    const fnA = vi
      .fn()
      .mockRejectedValueOnce({ response: { status: 503 } })
      .mockResolvedValue("resultA");

    const fnB = vi
      .fn()
      .mockRejectedValueOnce({ response: { status: 429 } })
      .mockRejectedValueOnce({ response: { status: 429 } })
      .mockResolvedValue("resultB");

    const fnC = vi.fn().mockResolvedValue("resultC");

    const [resultA, resultB, resultC] = await Promise.all([
      withRetry(fnA, { initialDelay: 10 }),
      withRetry(fnB, { maxAttempts: 3, initialDelay: 10 }),
      withRetry(fnC, { initialDelay: 10 }),
    ]);

    expect(resultA).toBe("resultA");
    expect(fnA).toHaveBeenCalledTimes(2);
    expect(resultB).toBe("resultB");
    expect(fnB).toHaveBeenCalledTimes(3);
    expect(resultC).toBe("resultC");
    expect(fnC).toHaveBeenCalledTimes(1);
  });

  it("TC-PER-018: should retry on 429 rate limit", async () => {
    const rateLimitError = {
      response: {
        status: 429,
        headers: { "retry-after": "2" },
        data: { error: { code: 429, message: "Rate Limit Exceeded" } },
      },
    };

    const fn = vi
      .fn()
      .mockRejectedValueOnce(rateLimitError)
      .mockResolvedValue("rate limit cleared");

    const result = await withRetry(fn, { initialDelay: 10 });
    expect(result).toBe("rate limit cleared");
    expect(fn).toHaveBeenCalledTimes(2);
  });
});
