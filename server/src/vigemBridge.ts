import type { InputState } from "./types";

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
  private updateCount = 0;
  private readonly debugRaw = process.env.DEBUG_VIGEM_RAW === "1";

  connect(): void {
    if (!ClientCtor) {
      console.warn("[vigem] package not available. Running in no-op mode.");
      return;
    }

    try {
      this.client = new ClientCtor();
      this.client.connect();
      this.gamepad = this.client.createX360Controller();
      this.gamepad.updateMode = "manual";
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
      // vigemclient InputAxis expects normalized input ranges:
      // sticks [-1..1], triggers [0..1], dpad axes {-1,0,1}.
      this.setAxis(["axis", "leftX"], this.clamp(input.lx, -1, 1));
      this.setAxis(["axis", "leftY"], this.clamp(input.ly, -1, 1));
      this.setAxis(["axis", "rightX"], this.clamp(input.rx, -1, 1));
      this.setAxis(["axis", "rightY"], this.clamp(input.ry, -1, 1));
      this.setAxis(["axis", "leftTrigger"], this.clamp(input.leftTrigger, 0, 1));
      this.setAxis(["axis", "rightTrigger"], this.clamp(input.rightTrigger, 0, 1));

      const dpadHorz = (input.dpadRight ? 1 : 0) + (input.dpadLeft ? -1 : 0);
      const dpadVert = (input.dpadUp ? 1 : 0) + (input.dpadDown ? -1 : 0);
      this.setAxis(["axis", "dpadHorz"], dpadHorz);
      this.setAxis(["axis", "dpadVert"], dpadVert);

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

      if (this.debugRaw) {
        this.updateCount += 1;
        if (this.updateCount % 20 === 0) {
          const lxRaw = this.gamepad?.axis?.leftX?.valueRaw;
          const lyRaw = this.gamepad?.axis?.leftY?.valueRaw;
          const rxRaw = this.gamepad?.axis?.rightX?.valueRaw;
          const ryRaw = this.gamepad?.axis?.rightY?.valueRaw;
          const ltRaw = this.gamepad?.axis?.leftTrigger?.valueRaw;
          const rtRaw = this.gamepad?.axis?.rightTrigger?.valueRaw;
          const dpadHRaw = this.gamepad?.axis?.dpadHorz?.valueRaw;
          const dpadVRaw = this.gamepad?.axis?.dpadVert?.valueRaw;
          console.info(
            `[vigem-raw] lx=${lxRaw} ly=${lyRaw} rx=${rxRaw} ry=${ryRaw} lt=${ltRaw} rt=${rtRaw} dpad=(${dpadHRaw},${dpadVRaw})`
          );
        }
      }

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
