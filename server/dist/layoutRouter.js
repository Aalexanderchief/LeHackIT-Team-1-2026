"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.resolveLayoutForProcess = resolveLayoutForProcess;
function resolveLayoutForProcess(processName) {
    const normalized = processName.trim().toLowerCase();
    if (normalized === "eldenring.exe") {
        return "eldenring";
    }
    return "default";
}
