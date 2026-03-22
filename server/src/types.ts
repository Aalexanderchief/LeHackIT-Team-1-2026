export type StickMove = {
  x: number;
  y: number;
};

export type StickVector = {
  x: number;
  y: number;
};

export type XInputAxes = {
  lx: number;
  ly: number;
};

export type WorkerEvent =
  | { type: "READY"; port: number }
  | { type: "PACKET"; payload: StickMove; remote: string }
  | { type: "ERROR"; message: string };
