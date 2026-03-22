"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.clamp = clamp;
exports.normalizeToXInput = normalizeToXInput;
const XINPUT_MAX = 32767;
function clamp(value, min, max) {
    return Math.min(max, Math.max(min, value));
}
function normalizeToXInput(vector) {
    const lx = Math.round(clamp(vector.x, -1, 1) * XINPUT_MAX);
    const ly = Math.round(clamp(vector.y, -1, 1) * XINPUT_MAX);
    return { lx, ly };
}
