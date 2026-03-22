export type StickMove = {
  x: number;
  y: number;
  rx?: number;
  ry?: number;
};

export type StickVector = {
  x: number;
  y: number;
};

export type InputState = {
  lx: number;
  ly: number;
  rx: number;
  ry: number;
  leftTrigger: number;
  rightTrigger: number;
  a: boolean;
  b: boolean;
  x: boolean;
  y: boolean;
  start: boolean;
  back: boolean;
  leftShoulder: boolean;
  rightShoulder: boolean;
  leftThumb: boolean;
  rightThumb: boolean;
  guide: boolean;
  dpadUp: boolean;
  dpadDown: boolean;
  dpadLeft: boolean;
  dpadRight: boolean;
};

export type XInputAxes = {
  lx: number;
  ly: number;
};

export type WorkerEvent =
  | { type: "READY"; port: number }
  | { type: "PACKET"; payload: InputState; remote: string }
  | { type: "ERROR"; message: string };
