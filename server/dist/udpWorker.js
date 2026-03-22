"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const node_dgram_1 = __importDefault(require("node:dgram"));
const node_worker_threads_1 = require("node:worker_threads");
const proto_1 = require("./proto");
const port = typeof node_worker_threads_1.workerData?.port === "number" ? node_worker_threads_1.workerData.port : 55555;
if (!node_worker_threads_1.parentPort) {
    throw new Error("Worker started without parentPort");
}
const workerPort = node_worker_threads_1.parentPort;
const socket = node_dgram_1.default.createSocket("udp4");
socket.on("error", (error) => {
    const event = {
        type: "ERROR",
        message: `UDP socket error: ${error.message}`
    };
    workerPort.postMessage(event);
});
socket.on("message", async (message, remote) => {
    try {
        const payload = await (0, proto_1.decodeStickMove)(message);
        const event = {
            type: "PACKET",
            payload,
            remote: `${remote.address}:${remote.port}`
        };
        workerPort.postMessage(event);
    }
    catch (error) {
        const event = {
            type: "ERROR",
            message: `Decode error: ${error instanceof Error ? error.message : "unknown"}`
        };
        workerPort.postMessage(event);
    }
});
socket.bind(port, () => {
    const event = { type: "READY", port };
    workerPort.postMessage(event);
});
