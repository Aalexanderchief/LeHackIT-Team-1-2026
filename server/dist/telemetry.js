"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Telemetry = void 0;
class Telemetry {
    sample;
    constructor() {
        const now = Date.now();
        this.sample = {
            packets: 0,
            startedAtMs: now,
            lastPacketAtMs: now,
            previousInterArrivalMs: null,
            jitterAccumulatorMs: 0,
            interArrivalSamples: 0,
            droppedPacketsEstimate: 0
        };
    }
    onPacket() {
        const now = Date.now();
        const interArrival = now - this.sample.lastPacketAtMs;
        if (this.sample.previousInterArrivalMs !== null) {
            this.sample.jitterAccumulatorMs += Math.abs(interArrival - this.sample.previousInterArrivalMs);
            this.sample.interArrivalSamples += 1;
        }
        this.sample.previousInterArrivalMs = interArrival;
        this.sample.packets += 1;
        this.sample.lastPacketAtMs = now;
    }
    snapshot() {
        const now = Date.now();
        const uptimeMs = now - this.sample.startedAtMs;
        const seconds = Math.max(1, uptimeMs / 1000);
        return {
            packetsPerSecond: this.sample.packets / seconds,
            packets: this.sample.packets,
            uptimeMs,
            idleMs: now - this.sample.lastPacketAtMs,
            jitterMs: this.sample.interArrivalSamples === 0
                ? 0
                : this.sample.jitterAccumulatorMs / this.sample.interArrivalSamples,
            droppedPacketsEstimate: this.sample.droppedPacketsEstimate
        };
    }
}
exports.Telemetry = Telemetry;
