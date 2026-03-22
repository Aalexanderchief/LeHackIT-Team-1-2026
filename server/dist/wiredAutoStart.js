"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.startWiredAutoStart = startWiredAutoStart;
const node_child_process_1 = require("node:child_process");
const node_path_1 = __importDefault(require("node:path"));
const node_fs_1 = require("node:fs");
const DEFAULT_OPTIONS = {
    udpPort: Number(process.env.UDP_PORT ?? 55555),
    appId: process.env.ANDROID_APP_ID ?? "com.example.lehackit_mobile",
    pollIntervalMs: Number(process.env.ADB_POLL_MS ?? 3000)
};
function resolveAdbBinary() {
    const explicit = process.env.ADB_PATH;
    if (explicit && (0, node_fs_1.existsSync)(explicit)) {
        return explicit;
    }
    const sdkCandidates = [
        process.env.ANDROID_SDK_ROOT,
        process.env.ANDROID_HOME,
        node_path_1.default.join(process.env.USERPROFILE ?? "", "AppData", "Local", "Android", "sdk")
    ].filter((value) => Boolean(value && value.trim().length > 0));
    for (const sdkRoot of sdkCandidates) {
        const candidate = node_path_1.default.join(sdkRoot, "platform-tools", process.platform === "win32" ? "adb.exe" : "adb");
        if ((0, node_fs_1.existsSync)(candidate)) {
            return candidate;
        }
    }
    return "adb";
}
function runAdb(adbBinary, args) {
    return (0, node_child_process_1.execFileSync)(adbBinary, args, {
        encoding: "utf8",
        windowsHide: true,
        stdio: ["ignore", "pipe", "pipe"],
        timeout: 3000
    });
}
function parseConnectedDeviceIds(adbDevicesOutput) {
    return adbDevicesOutput
        .split(/\r?\n/)
        .map((line) => line.trim())
        .filter((line) => line.length > 0)
        .filter((line) => !line.startsWith("List of devices attached"))
        .map((line) => line.split(/\s+/))
        .filter((parts) => parts.length >= 2 && parts[1] === "device")
        .map((parts) => parts[0]);
}
function startWiredAutoStart(options = {}) {
    const config = {
        ...DEFAULT_OPTIONS,
        ...options
    };
    const adbBinary = resolveAdbBinary();
    let adbUnavailableLogged = false;
    let lastKnownDeviceIds = new Set();
    const ensureForDevice = (deviceId) => {
        try {
            runAdb(adbBinary, [
                "-s",
                deviceId,
                "reverse",
                `udp:${config.udpPort}`,
                `udp:${config.udpPort}`
            ]);
            console.info(`[wired] reverse ready for ${deviceId} udp:${config.udpPort} -> host`);
        }
        catch (error) {
            console.warn(`[wired] failed adb reverse for ${deviceId}: ${error instanceof Error ? error.message : "unknown"}`);
            return;
        }
        try {
            runAdb(adbBinary, [
                "-s",
                deviceId,
                "shell",
                "monkey",
                "-p",
                config.appId,
                "-c",
                "android.intent.category.LAUNCHER",
                "1"
            ]);
            console.info(`[wired] launched ${config.appId} on ${deviceId}`);
        }
        catch (error) {
            console.warn(`[wired] failed launch for ${deviceId}: ${error instanceof Error ? error.message : "unknown"}`);
        }
    };
    const poll = () => {
        let deviceIds = [];
        try {
            deviceIds = parseConnectedDeviceIds(runAdb(adbBinary, ["devices"]));
            adbUnavailableLogged = false;
        }
        catch {
            // ADB is optional. If not installed or not running, just skip wired mode.
            if (!adbUnavailableLogged) {
                console.warn(`[wired] adb unavailable (${adbBinary}). USB auto-start is paused.`);
                adbUnavailableLogged = true;
            }
            return;
        }
        const current = new Set(deviceIds);
        for (const deviceId of deviceIds) {
            if (!lastKnownDeviceIds.has(deviceId)) {
                ensureForDevice(deviceId);
            }
        }
        if (lastKnownDeviceIds.size > 0 && current.size === 0) {
            console.info("[wired] no USB Android devices detected");
        }
        lastKnownDeviceIds = current;
    };
    poll();
    const timer = setInterval(poll, config.pollIntervalMs);
    timer.unref();
    return () => clearInterval(timer);
}
