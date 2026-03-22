import dgram from "node:dgram";
import { parentPort, workerData } from "node:worker_threads";
import { decodeStickMove } from "./proto";
import type { WorkerEvent } from "./types";

const port = typeof workerData?.port === "number" ? workerData.port : 55555;

if (!parentPort) {
  throw new Error("Worker started without parentPort");
}

const workerPort = parentPort;

const socket = dgram.createSocket("udp4");

socket.on("error", (error) => {
  const event: WorkerEvent = {
    type: "ERROR",
    message: `UDP socket error: ${error.message}`
  };
  workerPort.postMessage(event);
});

socket.on("message", async (message, remote) => {
  try {
    const payload = await decodeStickMove(message);
    const event: WorkerEvent = {
      type: "PACKET",
      payload,
      remote: `${remote.address}:${remote.port}`
    };
    workerPort.postMessage(event);
  } catch (error) {
    const event: WorkerEvent = {
      type: "ERROR",
      message: `Decode error: ${error instanceof Error ? error.message : "unknown"}`
    };
    workerPort.postMessage(event);
  }
});

socket.bind(port, () => {
  const event: WorkerEvent = { type: "READY", port };
  workerPort.postMessage(event);
});
