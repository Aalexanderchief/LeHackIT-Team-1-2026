import type { InputState } from "./types";

const XINPUT_AXIS_MAX = 32767;
const XINPUT_TRIGGER_MAX = 255;

let ClientCtor: any;

try {
  // Loaded lazily to keep development possible on machines without ViGEmBus.
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  ClientCtor = require("vigemclient");
} catch {
  ClientCtor = null;
}

export class ViGEmBridge {
  private client: any;
  private gamepad: any;
  private connected = false;

  connect(): void {
    if (!ClientCtor) {
      console.warn("[vigem] package not available. Running in no-op mode.");
      return;
    }

    try {
      this.client = new ClientCtor();
      this.client.connect();
      this.gamepad = this.client.createX360Controller();
      this.gamepad.connect();
      this.connected = true;
      console.info("[vigem] virtual Xbox controller connected");
    } catch (error) {
      this.connected = false;
      console.error("[vigem] failed to connect", error);
    }
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.min(max, Math.max(min, value));
  }

  private setAxis(path: string[], value: number): void {
    let current = this.gamepad;
    for (const key of path) {
      current = current?.[key];
    }
    if (current && typeof current.setValue === "function") {
      current.setValue(value);
    }
  }

  private setButton(path: string[], pressed: boolean): void {
    let current = this.gamepad;
    for (const key of path) {
      current = current?.[key];
    }
    if (current && typeof current.setValue === "function") {
      current.setValue(pressed);
    }
  }

  updateInput(input: InputState): void {
    if (!this.connected || !this.gamepad) {
      return;
    }

    try {
      this.setAxis(
        ["axis", "leftX"],
        Math.round(this.clamp(input.lx, -1, 1) * XINPUT_AXIS_MAX)
      );
      this.setAxis(
        ["axis", "leftY"],
        Math.round(this.clamp(input.ly, -1, 1) * XINPUT_AXIS_MAX)
      );
      this.setAxis(
        ["axis", "rightX"],
        Math.round(this.clamp(input.rx, -1, 1) * XINPUT_AXIS_MAX)
      );
      this.setAxis(
        ["axis", "rightY"],
        Math.round(this.clamp(input.ry, -1, 1) * XINPUT_AXIS_MAX)
      );
      this.setAxis(
        ["axis", "leftTrigger"],
        Math.round(this.clamp(input.leftTrigger, 0, 1) * XINPUT_TRIGGER_MAX)
      );
      this.setAxis(
        ["axis", "rightTrigger"],
        Math.round(this.clamp(input.rightTrigger, 0, 1) * XINPUT_TRIGGER_MAX)
      );

      this.setButton(["button", "A"], input.a);
      this.setButton(["button", "B"], input.b);
      this.setButton(["button", "X"], input.x);
      this.setButton(["button", "Y"], input.y);
      this.setButton(["button", "START"], input.start);
      this.setButton(["button", "BACK"], input.back);
      this.setButton(["button", "LEFT_SHOULDER"], input.leftShoulder);
      this.setButton(["button", "RIGHT_SHOULDER"], input.rightShoulder);
      this.setButton(["button", "LEFT_THUMB"], input.leftThumb);
      this.setButton(["button", "RIGHT_THUMB"], input.rightThumb);
      this.setButton(["button", "GUIDE"], input.guide);
      this.setButton(["button", "DPAD_UP"], input.dpadUp);
      this.setButton(["button", "DPAD_DOWN"], input.dpadDown);
      this.setButton(["button", "DPAD_LEFT"], input.dpadLeft);
      this.setButton(["button", "DPAD_RIGHT"], input.dpadRight);

      this.gamepad.update();
    } catch (error) {
      console.error("[vigem] input update failed", error);
    }
  }

  disconnect(): void {
    try {
      if (this.gamepad) {
        this.gamepad.disconnect();
      }
      if (this.client && typeof this.client.disconnect === "function") {
        this.client.disconnect();
      }
    } catch (error) {
      console.error("[vigem] disconnect failed", error);
    } finally {
      this.connected = false;
    }
  }
}
