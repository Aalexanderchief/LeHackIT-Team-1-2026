import { describe, expect, it } from "vitest";
import { clamp, normalizeToXInput } from "../src/normalization";

describe("clamp", () => {
  it("keeps value inside range", () => {
    expect(clamp(0.5, -1, 1)).toBe(0.5);
  });

  it("clamps above max", () => {
    expect(clamp(10, -1, 1)).toBe(1);
  });

  it("clamps below min", () => {
    expect(clamp(-3, -1, 1)).toBe(-1);
  });
});

describe("normalizeToXInput", () => {
  it("maps center to zero", () => {
    expect(normalizeToXInput({ x: 0, y: 0 })).toEqual({ lx: 0, ly: 0 });
  });

  it("maps full positive range", () => {
    expect(normalizeToXInput({ x: 1, y: 1 })).toEqual({ lx: 32767, ly: 32767 });
  });

  it("maps full negative range", () => {
    expect(normalizeToXInput({ x: -1, y: -1 })).toEqual({ lx: -32767, ly: -32767 });
  });

  it("clamps overflow values", () => {
    expect(normalizeToXInput({ x: 5, y: -9 })).toEqual({ lx: 32767, ly: -32767 });
  });
});
