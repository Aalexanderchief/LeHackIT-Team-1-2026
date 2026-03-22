import type { XInputAxes } from "./types";

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

  updateAxes(axes: XInputAxes): void {
    if (!this.connected || !this.gamepad) {
      return;
    }

    try {
      this.gamepad.axis.leftX.setValue(axes.lx);
      this.gamepad.axis.leftY.setValue(axes.ly);
      this.gamepad.axis.rightX.setValue(axes.rx);
      this.gamepad.axis.rightY.setValue(axes.ry);
      this.gamepad.update();
    } catch (error) {
      console.error("[vigem] axis update failed", error);
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
