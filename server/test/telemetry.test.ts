import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { Telemetry } from "../src/telemetry";

describe("Telemetry", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-03-22T00:00:00.000Z"));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("starts with zero packets", () => {
    const telemetry = new Telemetry();
    const snap = telemetry.snapshot();

    expect(snap.packets).toBe(0);
    expect(snap.packetsPerSecond).toBe(0);
    expect(snap.jitterMs).toBe(0);
  });

  it("counts packets and computes idle time", () => {
    const telemetry = new Telemetry();

    vi.advanceTimersByTime(100);
    telemetry.onPacket();

    vi.advanceTimersByTime(400);
    const snap = telemetry.snapshot();

    expect(snap.packets).toBe(1);
    expect(snap.idleMs).toBe(400);
    expect(snap.packetsPerSecond).toBeCloseTo(1 / 1, 5);
  });

  it("computes jitter from inter-arrival deltas", () => {
    const telemetry = new Telemetry();

    vi.advanceTimersByTime(100);
    telemetry.onPacket(); // first arrival: 100

    vi.advanceTimersByTime(120);
    telemetry.onPacket(); // second arrival: 120 (no jitter sample yet)

    vi.advanceTimersByTime(170);
    telemetry.onPacket(); // third arrival: 170 -> |170-120| = 50

    const snap = telemetry.snapshot();
    // Jitter is average over two deltas: |120-100|=20 and |170-120|=50 => 35.
    expect(snap.jitterMs).toBeCloseTo(35, 5);
  });
});
