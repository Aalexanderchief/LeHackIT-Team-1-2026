import { describe, expect, it } from "vitest";
import { resolveLayoutForProcess } from "../src/layoutRouter";

describe("resolveLayoutForProcess", () => {
  it("returns eldenring layout for executable name", () => {
    expect(resolveLayoutForProcess("eldenring.exe")).toBe("eldenring");
  });

  it("handles case-insensitive input", () => {
    expect(resolveLayoutForProcess("ELDENRING.EXE")).toBe("eldenring");
  });

  it("trims whitespace", () => {
    expect(resolveLayoutForProcess("  eldenring.exe  ")).toBe("eldenring");
  });

  it("falls back to default", () => {
    expect(resolveLayoutForProcess("some_other_game.exe")).toBe("default");
  });
});
