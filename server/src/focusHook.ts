import { EventEmitter } from "node:events";
import { resolveLayoutForProcess } from "./layoutRouter";

export type LayoutChangeEvent = {
  type: "LAYOUT_CHANGE";
  processName: string;
  layout: "default" | "eldenring";
};

export class FocusHookBridge extends EventEmitter {
  start(): void {
    // Placeholder for native module wiring in Phase 4.
    // The native addon will call into this bridge when foreground window changes.
  }

  simulateProcessFocus(processName: string): void {
    const event: LayoutChangeEvent = {
      type: "LAYOUT_CHANGE",
      processName,
      layout: resolveLayoutForProcess(processName)
    };

    this.emit("layout", event);
  }
}
