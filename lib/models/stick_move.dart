/// Protobuf message for stick movement (joystick/gyroscope input)
class StickMove {
  int x = 0;
  int y = 0;

  StickMove({this.x = 0, this.y = 0});

  /// Encode to protobuf format
  /// Proto3 wire format for message with two int32 fields
  List<int> toProtoBytes() {
    final buffer = <int>[];

    // Field 1: x (int32)
    if (x != 0) {
      buffer.addAll(_encodeVarint(_encodeTag(1, 0))); // tag (field 1, type 0)
      buffer.addAll(_encodeVarint(_encodeSignedInt(x)));
    }

    // Field 2: y (int32)
    if (y != 0) {
      buffer.addAll(_encodeVarint(_encodeTag(2, 0))); // tag (field 2, type 0)
      buffer.addAll(_encodeVarint(_encodeSignedInt(y)));
    }

    return buffer;
  }

  /// Encode field tag (field number + wire type)
  static int _encodeTag(int fieldNumber, int wireType) {
    return (fieldNumber << 3) | wireType;
  }

  /// Encode signed int32 as varint
  static int _encodeSignedInt(int value) {
    return (value << 1) ^ (value >> 31);
  }

  /// Encode varint
  static List<int> _encodeVarint(int value) {
    final result = <int>[];
    while ((value & 0xFFFFFF80) != 0) {
      result.add((value & 0x7F) | 0x80);
      value >>= 7;
    }
    result.add(value & 0x7F);
    return result;
  }
}
