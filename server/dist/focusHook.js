"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FocusHookBridge = void 0;
const node_events_1 = require("node:events");
const layoutRouter_1 = require("./layoutRouter");
class FocusHookBridge extends node_events_1.EventEmitter {
    start() {
        // Placeholder for native module wiring in Phase 4.
        // The native addon will call into this bridge when foreground window changes.
    }
    simulateProcessFocus(processName) {
        const event = {
            type: "LAYOUT_CHANGE",
            processName,
            layout: (0, layoutRouter_1.resolveLayoutForProcess)(processName)
        };
        this.emit("layout", event);
    }
}
exports.FocusHookBridge = FocusHookBridge;
