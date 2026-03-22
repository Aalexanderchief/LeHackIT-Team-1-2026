import path from "node:path";
import protobuf from "protobufjs";
import type { StickMove } from "./types";

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

export async function decodeStickMove(buffer: Buffer): Promise<StickMove> {
  const messageType = await getStickMoveType();
  const decoded = messageType.decode(buffer);
  const object = messageType.toObject(decoded, {
    longs: Number,
    enums: String,
    defaults: false
  }) as Partial<StickMove>;

  return {
    x: object.x ?? 0,
    y: object.y ?? 0,
    rx: object.rx ?? 0,
    ry: object.ry ?? 0
  };
}
