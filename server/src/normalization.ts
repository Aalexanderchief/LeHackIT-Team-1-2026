import type { StickVector, XInputStickAxes } from "./types";

const XINPUT_MAX = 32767;

export function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

export function normalizeToXInput(vector: StickVector): XInputStickAxes {
  const lx = Math.round(clamp(vector.x, -1, 1) * XINPUT_MAX);
  const ly = Math.round(clamp(vector.y, -1, 1) * XINPUT_MAX);

  return { lx, ly };
}
