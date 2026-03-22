import path from "node:path";
import protobuf from "protobufjs";
import type { InputState, StickMove } from "./types";

let cachedType: protobuf.Type | null = null;

async function getStickMoveType(): Promise<protobuf.Type> {
  if (cachedType) {
    return cachedType;
  }

  const protoPath = path.resolve(__dirname, "../../proto/controller.proto");
  const root = await protobuf.load(protoPath);
  const stickMove = root.lookupType("lehackit.controller.StickMove");

  cachedType = stickMove;
  return stickMove;
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

function toNumber(value: unknown, fallback = 0): number {
  return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}

function toBoolean(value: unknown, fallback = false): boolean {
  return typeof value === "boolean" ? value : fallback;
}

function emptyInputState(): InputState {
  return {
    lx: 0,
    ly: 0,
    rx: 0,
    ry: 0,
    leftTrigger: 0,
    rightTrigger: 0,
    a: false,
    b: false,
    x: false,
    y: false,
    start: false,
    back: false,
    leftShoulder: false,
    rightShoulder: false,
    leftThumb: false,
    rightThumb: false,
    guide: false,
    dpadUp: false,
    dpadDown: false,
    dpadLeft: false,
    dpadRight: false
  };
}

function fromJsonPayload(payload: unknown): InputState {
  const state = emptyInputState();
  if (typeof payload !== "object" || payload === null) {
    throw new Error("invalid JSON input payload");
  }

  const source = payload as Record<string, unknown>;
  const buttons =
    typeof source.buttons === "object" && source.buttons !== null
      ? (source.buttons as Record<string, unknown>)
      : {};

  state.lx = clamp(toNumber(source.lx), -1, 1);
  state.ly = clamp(toNumber(source.ly), -1, 1);
  state.rx = clamp(toNumber(source.rx), -1, 1);
  state.ry = clamp(toNumber(source.ry), -1, 1);
  state.leftTrigger = clamp(toNumber(source.lt, toNumber(source.leftTrigger)), 0, 1);
  state.rightTrigger = clamp(toNumber(source.rt, toNumber(source.rightTrigger)), 0, 1);
  state.a = toBoolean(buttons.a);
  state.b = toBoolean(buttons.b);
  state.x = toBoolean(buttons.x);
  state.y = toBoolean(buttons.y);
  state.start = toBoolean(buttons.start);
  state.back = toBoolean(buttons.back);
  state.leftShoulder = toBoolean(buttons.leftShoulder);
  state.rightShoulder = toBoolean(buttons.rightShoulder);
  state.leftThumb = toBoolean(buttons.leftThumb);
  state.rightThumb = toBoolean(buttons.rightThumb);
  state.guide = toBoolean(buttons.guide);
  state.dpadUp = toBoolean(buttons.dpadUp);
  state.dpadDown = toBoolean(buttons.dpadDown);
  state.dpadLeft = toBoolean(buttons.dpadLeft);
  state.dpadRight = toBoolean(buttons.dpadRight);
  return state;
}

function fromStickMove(move: StickMove): InputState {
  const state = emptyInputState();
  state.lx = clamp(move.x / 1000, -1, 1);
  state.ly = clamp(move.y / 1000, -1, 1);
  state.rx = clamp((move.rx ?? 0) / 1000, -1, 1);
  state.ry = clamp((move.ry ?? 0) / 1000, -1, 1);
  return state;
}

function tryDecodeJson(buffer: Buffer): InputState | null {
  const text = buffer.toString("utf8").trim();
  if (!text.startsWith("{")) {
    return null;
  }

  const parsed = JSON.parse(text) as Record<string, unknown>;
  if (parsed.type !== "INPUT_STATE") {
    throw new Error("unsupported JSON payload type");
  }
  return fromJsonPayload(parsed);
}

export async function decodeStickMove(buffer: Buffer): Promise<InputState> {
  const jsonState = tryDecodeJson(buffer);
  if (jsonState) {
    return jsonState;
  }

  const messageType = await getStickMoveType();
  const decoded = messageType.decode(buffer);
  const object = messageType.toObject(decoded, {
    longs: Number,
    enums: String,
    defaults: false
  }) as Partial<StickMove>;

  const stickMove: StickMove = {
    x: object.x ?? 0,
    y: object.y ?? 0,
    rx: object.rx ?? 0,
    ry: object.ry ?? 0
  };

  return fromStickMove(stickMove);
}
