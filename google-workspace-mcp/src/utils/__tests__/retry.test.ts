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
    const fn = vi
      .fn()
      .mockRejectedValueOnce({ code: "ECONNRESET" })
      .mockResolvedValue("recovered");

    const result = await withRetry(fn, { initialDelay: 10 });
    expect(result).toBe("recovered");
    expect(fn).toHaveBeenCalledTimes(2);
  });

  it("should throw on non-retryable error", async () => {
    const fn = vi
      .fn()
      .mockRejectedValue(new Error("Not Found"));

    await expect(
      withRetry(fn, { initialDelay: 10 })
    ).rejects.toThrow("Not Found");
    expect(fn).toHaveBeenCalledTimes(1);
  });

  it("should throw after max attempts", async () => {
    const fn = vi
      .fn()
      .mockRejectedValue({ response: { status: 429 } });

    await expect(
      withRetry(fn, { maxAttempts: 3, initialDelay: 10 })
    ).rejects.toEqual({ response: { status: 429 } });
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
