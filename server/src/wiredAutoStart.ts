import { execFileSync } from "node:child_process";
import path from "node:path";
import { existsSync } from "node:fs";

type WiredBridgeOptions = {
  udpPort: number;
  appId: string;
  pollIntervalMs: number;
};

const DEFAULT_OPTIONS: WiredBridgeOptions = {
  udpPort: Number(process.env.UDP_PORT ?? 55555),
  appId: process.env.ANDROID_APP_ID ?? "com.example.lehackit_mobile",
  pollIntervalMs: Number(process.env.ADB_POLL_MS ?? 3000)
};

function reverseSpecForAdb(port: number): string {
  // ADB reverse supports tcp/local socket specs, not udp.
  return `tcp:${port}`;
}

function resolveAdbBinary(): string {
  const explicit = process.env.ADB_PATH;
  if (explicit && existsSync(explicit)) {
    return explicit;
  }

  const sdkCandidates = [
    process.env.ANDROID_SDK_ROOT,
    process.env.ANDROID_HOME,
    path.join(process.env.USERPROFILE ?? "", "AppData", "Local", "Android", "sdk")
  ].filter((value): value is string => Boolean(value && value.trim().length > 0));

  for (const sdkRoot of sdkCandidates) {
    const candidate = path.join(sdkRoot, "platform-tools", process.platform === "win32" ? "adb.exe" : "adb");
    if (existsSync(candidate)) {
      return candidate;
    }
  }

  return "adb";
}

function runAdb(adbBinary: string, args: string[]): string {
  return execFileSync(adbBinary, args, {
    encoding: "utf8",
    windowsHide: true,
    stdio: ["ignore", "pipe", "pipe"],
    timeout: 3000
  });
}

function parseConnectedDeviceIds(adbDevicesOutput: string): string[] {
  return adbDevicesOutput
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0)
    .filter((line) => !line.startsWith("List of devices attached"))
    .map((line) => line.split(/\s+/))
    .filter((parts) => parts.length >= 2 && parts[1] === "device")
    .map((parts) => parts[0]);
}

export function startWiredAutoStart(
  options: Partial<WiredBridgeOptions> = {}
): () => void {
  const config: WiredBridgeOptions = {
    ...DEFAULT_OPTIONS,
    ...options
  };

  const adbBinary = resolveAdbBinary();
  let adbUnavailableLogged = false;

  let lastKnownDeviceIds = new Set<string>();

  const ensureForDevice = (deviceId: string): void => {
    const reverseSpec = reverseSpecForAdb(config.udpPort);

    try {
      runAdb(adbBinary, [
        "-s",
        deviceId,
        "reverse",
        reverseSpec,
        reverseSpec
      ]);
      console.info(
        `[wired] reverse ready for ${deviceId} ${reverseSpec} -> host`
      );
    } catch (error) {
      console.warn(
        `[wired] failed adb reverse for ${deviceId}: ${
          error instanceof Error ? error.message : "unknown"
        }`
      );
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
    } catch (error) {
      console.warn(
        `[wired] failed launch for ${deviceId}: ${
          error instanceof Error ? error.message : "unknown"
        }`
      );
    }
  };

  const poll = (): void => {
    let deviceIds: string[] = [];
    try {
      deviceIds = parseConnectedDeviceIds(runAdb(adbBinary, ["devices"]));
      adbUnavailableLogged = false;
    } catch {
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
