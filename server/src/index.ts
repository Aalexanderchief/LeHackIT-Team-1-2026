import path from "node:path";
import { Worker } from "node:worker_threads";
import { FocusHookBridge } from "./focusHook";
import { startMdnsAdvertiser } from "./mdnsAdvertiser";
import { Telemetry } from "./telemetry";
import type { WorkerEvent } from "./types";
import { ViGEmBridge } from "./vigemBridge";

const UDP_PORT = Number(process.env.UDP_PORT ?? 55555);

const bridge = new ViGEmBridge();
bridge.connect();

const telemetry = new Telemetry();
const stopMdns = startMdnsAdvertiser(UDP_PORT);
const focusHook = new FocusHookBridge();
let packetCount = 0;
let lastInputLogAt = 0;

focusHook.on("layout", (event) => {
  console.info(
    `[layout] process=${event.processName} layout=${event.layout} type=${event.type}`
  );
});

focusHook.start();

const workerExt = path.extname(__filename) === ".ts" ? "ts" : "js";
const workerPath = path.resolve(__dirname, `udpWorker.${workerExt}`);
const udpWorker = new Worker(workerPath, {
  workerData: { port: UDP_PORT },
  execArgv: process.execArgv
});

udpWorker.on("message", (event: WorkerEvent) => {
  if (event.type === "READY") {
    console.info(`[udp] worker listening on ${event.port}`);
    return;
  }

  if (event.type === "ERROR") {
    console.error(`[udp] ${event.message}`);
    return;
  }

  if (event.type === "PACKET") {
    telemetry.onPacket();
    packetCount += 1;

    const now = Date.now();
    const hasInput =
      event.payload.lx !== 0 ||
      event.payload.ly !== 0 ||
      event.payload.rx !== 0 ||
      event.payload.ry !== 0 ||
      event.payload.leftTrigger !== 0 ||
      event.payload.rightTrigger !== 0 ||
      event.payload.a ||
      event.payload.b ||
      event.payload.x ||
      event.payload.y ||
      event.payload.start ||
      event.payload.back ||
      event.payload.leftShoulder ||
      event.payload.rightShoulder ||
      event.payload.leftThumb ||
      event.payload.rightThumb ||
      event.payload.guide ||
      event.payload.dpadUp ||
      event.payload.dpadDown ||
      event.payload.dpadLeft ||
      event.payload.dpadRight;

    if (packetCount <= 5 || hasInput || now - lastInputLogAt >= 1500) {
      console.info(
        `[input] #${packetCount} from=${event.remote} sticks=(${event.payload.lx.toFixed(3)},${event.payload.ly.toFixed(3)})/(${event.payload.rx.toFixed(3)},${event.payload.ry.toFixed(3)}) trig=(${event.payload.leftTrigger.toFixed(2)},${event.payload.rightTrigger.toFixed(2)}) buttons=a:${event.payload.a ? 1 : 0} b:${event.payload.b ? 1 : 0} x:${event.payload.x ? 1 : 0} y:${event.payload.y ? 1 : 0}`
      );
      lastInputLogAt = now;
    }

    bridge.updateInput(event.payload);
  }
});

udpWorker.on("error", (error) => {
  console.error("[worker] crash", error);
});

udpWorker.on("exit", (code) => {
  console.error(`[worker] exited with code ${code}`);
});

setInterval(() => {
  const snap = telemetry.snapshot();
  console.info(
    `[telemetry] pps=${snap.packetsPerSecond.toFixed(1)} packets=${snap.packets} idleMs=${snap.idleMs} jitterMs=${snap.jitterMs.toFixed(2)} drops=${snap.droppedPacketsEstimate}`
  );
}, 1000).unref();

function shutdown(signal: string): void {
  console.info(`[app] shutting down due to ${signal}`);
  stopMdns();
  bridge.disconnect();
  udpWorker.terminate().finally(() => process.exit(0));
}

process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));
