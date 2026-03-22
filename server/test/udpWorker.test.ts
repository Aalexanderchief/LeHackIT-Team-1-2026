import dgram from "node:dgram";
import path from "node:path";
import protobuf from "protobufjs";
import { Worker } from "node:worker_threads";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import type { WorkerEvent } from "../src/types";

type WorkerMessageWait = {
  worker: Worker;
  timeoutMs?: number;
};

async function waitForEvent(
  options: WorkerMessageWait,
  predicate: (event: WorkerEvent) => boolean
): Promise<WorkerEvent> {
  const timeoutMs = options.timeoutMs ?? 2500;

  return await new Promise<WorkerEvent>((resolve, reject) => {
    const timer = setTimeout(() => {
      cleanup();
      reject(new Error("Timed out waiting for worker event"));
    }, timeoutMs);

    const onMessage = (event: WorkerEvent): void => {
      if (!predicate(event)) {
        return;
      }
      cleanup();
      resolve(event);
    };

    const onError = (error: Error): void => {
      cleanup();
      reject(error);
    };

    const cleanup = (): void => {
      clearTimeout(timer);
      options.worker.off("message", onMessage);
      options.worker.off("error", onError);
    };

    options.worker.on("message", onMessage);
    options.worker.on("error", onError);
  });
}

describe("udp worker", () => {
  let worker: Worker | null = null;
  let socket: dgram.Socket | null = null;

  beforeEach(() => {
    socket = dgram.createSocket("udp4");
  });

  afterEach(async () => {
    if (socket) {
      socket.close();
      socket = null;
    }

    if (worker) {
      await worker.terminate();
      worker = null;
    }
  });

  it("emits READY and PACKET for valid protobuf payload", async () => {
    const port = 56001;
    const workerPath = path.resolve(__dirname, "../dist/udpWorker.js");

    worker = new Worker(workerPath, { workerData: { port } });

    const ready = await waitForEvent(
      { worker },
      (event) => event.type === "READY"
    );
    expect(ready.type).toBe("READY");

    const root = await protobuf.load(
      path.resolve(__dirname, "../../proto/controller.proto")
    );
    const stickMove = root.lookupType("lehackit.controller.StickMove");
    const payload = stickMove.encode({ x: 123, y: -456 }).finish();

    socket!.send(Buffer.from(payload), port, "127.0.0.1");

    const packet = await waitForEvent(
      { worker },
      (event) => event.type === "PACKET"
    );

    expect(packet.type).toBe("PACKET");
    if (packet.type === "PACKET") {
      expect(packet.payload).toEqual({ x: 123, y: -456, rx: 0, ry: 0 });
      expect(packet.remote.startsWith("127.0.0.1:")).toBe(true);
    }
  });

  it("emits ERROR for malformed datagram", async () => {
    const port = 56002;
    const workerPath = path.resolve(__dirname, "../dist/udpWorker.js");

    worker = new Worker(workerPath, { workerData: { port } });

    await waitForEvent({ worker }, (event) => event.type === "READY");

    socket!.send(Buffer.from([0xff, 0x00, 0xfe]), port, "127.0.0.1");

    const errorEvent = await waitForEvent(
      { worker },
      (event) => event.type === "ERROR" && event.message.includes("Decode error")
    );

    expect(errorEvent.type).toBe("ERROR");
  });
});
