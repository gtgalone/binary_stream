import 'dart:convert';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:vector_math/vector_math_64.dart';

class BinaryStream {
  final utf8Codec = const Utf8Codec();
  final ascii8Codec = const AsciiCodec();

  List<int> binary = [];

  late int readIndex;
  int writeIndex = 0;

  /// Returns the encoded buffer.
  /// @returns [ByteBuffer]
  ByteBuffer? _buffer;
  ByteBuffer get buffer {
    return _buffer ?? Uint8List.fromList(binary).buffer;
  }

  /// Creates a new BinaryStream instance.
  /// @param [ByteBuffer] buffer - The array or Buffer containing binary data.
  /// @param [int] offset - The initial pointer position.
  BinaryStream([ByteBuffer? buffer, int offset = 0]) {
    readIndex = offset;
    _buffer = buffer;
  }

  /// Reads a slice of buffer by the given length.
  /// @param [int] len
  ByteBuffer read(int len) {
    doReadAssertions(len);
    return buffer.asUint8List().sublist(readIndex, readIndex += len).buffer;
  }

  /// Appends a buffer to the main buffer.
  /// @param [ByteBuffer] buf
  void write(ByteBuffer buf) {
    binary = [...binary, ...buf.asUint8List()];
    writeIndex += buf.lengthInBytes;
  }

  /// Reads a signed byte (-128 to 127).
  /// @returns [int]
  int readInt8() {
    doReadAssertions(1);
    return buffer.asByteData().getInt8(readIndex++);
  }

  /// Writes a signed byte (-128 to 127).
  /// @param [int] v
  void writeInt8(int v) {
    var v2 = v;
    if (v2 < 0) {
      v2 = 0xff + v2 + 1;
    }
    writeIndex++;
    binary.add(v2 & 0xff);
  }

  /// Reads an unsigned byte (0 to 255).
  /// @returns [int]
  int readUint8() {
    doReadAssertions(1);
    return buffer.asByteData().getUint8(readIndex++);
  }

  /// Writes an unsigned byte (0 to 255).
  /// @param [int] v
  void writeUint8(int v) {
    writeIndex++;
    binary.add(v & 0xff);
  }

  /// Reads a boolean (true or false).
  /// @returns [bool]
  bool readBoolean() {
    doReadAssertions(1);
    return readUint8() == 1;
  }

  /// Writes a boolean (true or false).
  /// @param [bool] v
  void writeBoolean(bool v) {
    writeUint8(v ? 1 : 0);
  }

  /// Reads a 16 bit (2 bytes) signed big-endian number.
  /// @returns [int]
  int readInt16() {
    doReadAssertions(2);
    return buffer.asByteData().getInt16(addOffset(2));
  }

  /// Writes a 16 bit (2 bytes) signed big-endian number.
  /// @param [int] v
  void writeInt16(int v) {
    doWriteAssertions(v, -32768, 32767);
    writeInt8(v >> 8);
    writeInt8(v);
  }

  /// Reads a 16 bit (2 bytes) signed little-endian number.
  /// @returns [int]
  int readInt16LE() {
    doReadAssertions(2);
    return buffer.asByteData().getInt16(addOffset(2), Endian.little);
  }

  /// Writes a 16 bit (2 bytes) signed little-endian number.
  /// @param [int] v
  void writeInt16LE(int v) {
    doWriteAssertions(v, -32768, 32767);
    writeInt8(v);
    writeInt8(v >> 8);
  }

  /// Reads a 16 bit (2 bytes) unsigned big-endian number.
  /// @returns [int]
  int readUint16() {
    doReadAssertions(2);
    return buffer.asByteData().getUint16(addOffset(2));
  }

  /// Writes a 16 bit (2 bytes) unsigned big-endian number.
  /// @param [int] v
  void writeUint16(int v) {
    doWriteAssertions(v, 0, 65535);
    writeUint8(v >>> 8);
    writeUint8(v);
  }

  /// Reads a 16 bit (2 bytes) unsigned little-endian number.
  /// @returns [int]
  int readUint16LE() {
    doReadAssertions(2);
    return buffer.asByteData().getUint16(addOffset(2), Endian.little);
  }

  /// Writes a 16 bit (2 bytes) unsigned little-endian number.
  /// @param [int] v
  void writeUint16LE(int v) {
    doWriteAssertions(v, 0, 65535);
    writeUint8(v);
    writeUint8(v >>> 8);
  }

  /// Reads a 24 bit (3 bytes) signed big-endian number.
  /// @returns [int]
  int readInt24() {
    doReadAssertions(3);
    final bytes = Uint8List.fromList([
      readInt8(),
      readInt8(),
      readInt8(),
    ]);
    return bytes[0] << 16 | bytes[1] << 8 | bytes[2];
  }

  /// Writes a 24 bit (3 bytes) signed big-endian number.
  /// @param [int] v
  void writeInt24(int v) {
    doWriteAssertions(v, -8388608, 8388607);
    writeInt8((v & 0xff0000) >> 16); // msb
    writeInt8((v & 0x00ff00) >> 8); // mib
    writeInt8(v & 0x0000ff); // lsb
  }

  /// Reads a 24 bit (3 bytes) signed little-endian number.
  /// @returns [int]
  int readInt24LE() {
    doReadAssertions(3);
    final bytes = Uint8List.fromList([
      readInt8(),
      readInt8(),
      readInt8(),
    ]);
    return bytes[2] << 16 | bytes[1] << 8 | bytes[0];
  }

  /// Writes a 24 bit (3 bytes) signed little-endian number.
  /// @param [int] v
  void writeInt24LE(int v) {
    doWriteAssertions(v, -8388608, 8388607);
    writeInt8(v & 0x0000ff);
    writeInt8((v & 0x00ff00) >> 8);
    writeInt8((v & 0xff0000) >> 16);
  }

  /// Reads a 24 bit (3 bytes) unsigned big-endian number.
  /// @returns [int]
  int readUint24() {
    doReadAssertions(3);
    final bytes = Uint8List.fromList([
      readUint8(),
      readUint8(),
      readUint8(),
    ]);
    return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16);
  }

  /// Writes a 24 bit (3 bytes) unsigned big-endian number.
  /// @param [int] v
  void writeUint24(int v) {
    doWriteAssertions(v, 0, 16777215);
    writeUint8((v & 0xff0000) >>> 16); // msb
    writeUint8((v & 0x00ff00) >>> 8); // mib
    writeUint8(v & 0x0000ff); // lsb
  }

  /// Reads a 24 bit (3 bytes) unsigned little-endian number.
  /// @returns [int]
  int readUint24LE() {
    doReadAssertions(3);

    final bytes = Uint8List.fromList([
      readUint8(),
      readUint8(),
      readUint8(),
    ]);

    return bytes[2] | (bytes[1] << 8) | (bytes[0] << 16);
  }

  /// Writes a 24 bit (3 bytes) unsigned little-endian number.
  /// @param [int] v
  void writeUint24LE(int v) {
    doWriteAssertions(v, 0, 16777215);
    writeUint8(v & 0x0000ff);
    writeUint8((v & 0x00ff00) >>> 8);
    writeUint8((v & 0xff0000) >>> 16);
  }

  /// Reads a 32 bit (4 bytes) big-endian signed number.
  /// @returns [int]
  int readInt32() {
    doReadAssertions(4);
    return buffer.asByteData().getInt32(addOffset(4));
  }

  /// Writes a 32 bit (4 bytes) big-endian signed number.
  /// @param [int] v
  void writeInt32(int v) {
    var v2 = v;
    if (v2 < 0) {
      v2 = v2 & (0xffffffff + v2 + 1);
    }
    doWriteAssertions(v2, -2147483648, 2147483647);
    writeInt8(v2 >> 24);
    writeInt8(v2 >> 16);
    writeInt8(v2 >> 8);
    writeInt8(v2);
  }

  /// Reads a 32 bit (4 bytes) little-endian signed number.
  /// @returns [int]
  int readInt32LE() {
    doReadAssertions(4);
    return buffer.asByteData().getInt32(addOffset(4), Endian.little);
  }

  /// Writes a 32 bit (4 bytes) little-endian signed number.
  /// @param [int] v
  void writeInt32LE(int v) {
    var v2 = v;
    if (v2 < 0) {
      v2 = v2 & (0xffffffff + v2 + 1);
    }
    doWriteAssertions(v2, -2147483648, 2147483647);
    writeInt8(v2);
    writeInt8(v2 >> 8);
    writeInt8(v2 >> 16);
    writeInt8(v2 >> 24);
  }

  /// Reads a 32 bit (4 bytes) big-endian unsigned number.
  /// @returns [int]
  int readUint32() {
    doReadAssertions(4);
    return buffer.asByteData().getUint32(addOffset(4));
  }

  /// Writes a 32 bit (4 bytes) big-endian unsigned number.
  /// @param [int] v
  void writeUint32(int v) {
    doWriteAssertions(v, 0, 4294967295);
    writeUint8(v >>> 24);
    writeUint8(v >>> 16);
    writeUint8(v >>> 8);
    writeUint8(v);
  }

  /// Reads a 32 bit (4 bytes) little-endian unsigned number.
  /// @returns [int]
  int readUint32LE() {
    doReadAssertions(4);
    return buffer.asByteData().getUint32(addOffset(4), Endian.little);
  }

  /// Writes a 32 bit (4 bytes) little-endian unsigned number.
  /// @param [int] v
  void writeUint32LE(int v) {
    doWriteAssertions(v, 0, 4294967295);
    writeUint8(v);
    writeUint8(v >>> 8);
    writeUint8(v >>> 16);
    writeUint8(v >>> 24);
  }

  /// Returns a 32 bit (4 bytes) big-endian flating point number.
  /// @returns [int]
  double readFloat32() {
    doReadAssertions(4);
    return buffer.asByteData().getFloat32(addOffset(4));
  }

  /// Writes a 32 bit (4 bytes) big-endian floating point number.
  /// @param [int] v
  void writeFloat32(double v) {
    doWriteAssertions(
      v,
      -3.4028234663852886e38,
      3.4028234663852886e38,
    );

    final byteData = ByteData(4);
    byteData.setFloat32(0, v);
    write(byteData.buffer);
  }

  /// Returns a 32 bit (4 bytes) little-endian flating point number.
  /// @returns [int]
  double readFloat32LE() {
    doReadAssertions(4);
    return buffer.asByteData().getFloat32(addOffset(4), Endian.little);
  }

  /// Writes a 32 bit (4 bytes) little-endian floating point number.
  /// @param [int] v
  void writeFloat32LE(double v) {
    doWriteAssertions(
      v,
      -3.4028234663852886e38,
      3.4028234663852886e38,
    );

    final byteData = ByteData(4);
    byteData.setFloat32(0, v, Endian.little);
    write(byteData.buffer);
  }

  /// Returns a 64 bit (8 bytes) big-endian flating point number.
  /// @returns [int]
  double readFloat64() {
    doReadAssertions(8);
    return buffer.asByteData().getFloat64(addOffset(8));
  }

  /// Writes a 64 bit (8 bytes) big-endian floating point number.
  /// @param [int] v
  void writeFloat64(double v) {
    doWriteAssertions(
      v,
      -1.7976931348623157e308,
      1.7976931348623157e308,
    );

    final byteData = ByteData(8);
    byteData.setFloat64(0, v);
    write(byteData.buffer);
  }

  /// Returns a 64 bit (8 bytes) little-endian flating point number.
  /// @returns [int]
  double readFloat64LE() {
    doReadAssertions(8);
    return buffer.asByteData().getFloat64(addOffset(8), Endian.little);
  }

  /// Writes a 64 bit (8 bytes) little-endian floating point number.
  /// @param [int] v
  void writeFloat64LE(double v) {
    doWriteAssertions(
      v,
      -1.7976931348623157e308,
      1.7976931348623157e308,
    );

    final byteData = ByteData(8);
    byteData.setFloat64(0, v, Endian.little);
    write(byteData.buffer);
  }

  /// Returns a 64 bit (8 bytes) signed big-endian number.
  /// @returns [int]
  int readInt64() {
    doReadAssertions(8);
    return buffer.asByteData().getInt64(addOffset(8));
  }

  /// Writes a 64 bit (8 bytes) signed big-endian number.
  /// @param [int] v
  void writeInt64(int v) {
    final byteData = ByteData(8);
    byteData.setInt64(0, v);
    write(byteData.buffer);
  }

  /// Returns a 64 bit (8 bytes) signed little-endian number.
  /// @returns [int]
  int readInt64LE() {
    doReadAssertions(8);
    return buffer.asByteData().getInt64(addOffset(8), Endian.little);
  }

  /// Writes a 64 bit (8 bytes) signed little-endian number.
  /// @param [int] v
  void writeInt64LE(int v) {
    final byteData = ByteData(8);
    byteData.setInt64(0, v, Endian.little);
    write(byteData.buffer);
  }

  /// Returns a 64 bit (8 bytes) unsigned big-endian number.
  /// @returns [int]
  int readUint64() {
    doReadAssertions(8);
    return buffer.asByteData().getUint64(addOffset(8));
  }

  /// Writes a 64 bit (8 bytes) unsigned big-endian number.
  /// @param [int] v
  void writeUint64(int v) {
    final byteData = ByteData(8);
    byteData.setUint64(0, v);
    write(byteData.buffer);
  }

  /// Returns a 64 bit (8 bytes) unsigned little-endian number.
  /// @returns [int]
  int readUint64LE() {
    doReadAssertions(8);
    return buffer.asByteData().getUint64(addOffset(8), Endian.little);
  }

  /// Writes a 64 bit (8 bytes) unsigned little-endian number.
  /// @param [int] v
  void writeUint64LE(int v) {
    final byteData = ByteData(8);
    byteData.setUint64(0, v, Endian.little);
    write(byteData.buffer);
  }

  /// Reads a 32 bit (4 bytes) zigzag-encoded number.
  /// @returns [int]
  int readVarInt32() {
    final raw = readVarUint32();
    final temp = (((raw << 63) >> 63) ^ raw) >> 1;
    return temp ^ (raw & (1 << 63));
  }

  /// Writes a 32 bit (4 bytes) zigzag-encoded number.
  /// @param [int] v
  void writeVarInt32(int v) {
    var v2 = v;
    v2 = (v2 << 32) >> 32;
    return writeVarUint32((v2 << 1) ^ (v2 >> 31));
  }

  /// Reads a 32 bit unsigned number.
  /// @returns [int]
  int readVarUint32() {
    var value = 0;
    for (var i = 0; i <= 28; i += 7) {
      if (buffer.asUint8List().elementAtOrNull(readIndex) == null) {
        throw Exception('No bytes left in buffer int');
      }
      final b = readUint8();
      value |= (b & 0x7f) << i;

      if ((b & 0x80) == 0) {
        return value;
      }
    }

    throw Exception('VarInt did not terminate after 5 bytes!');
  }

  /// Writes a 32 bit unsigned number with variable-length.
  /// @param [int] v
  void writeVarUint32(int v) {
    var v2 = v;
    while ((v2 & 0xffffff80) != 0) {
      writeUint8((v2 & 0x7f) | 0x80);
      v2 >>>= 7;
    }
    writeUint8(v2 & 0x7f);
  }

  /// Reads a 64 bit zigzag-encoded variable-length number.
  /// @returns [int]
  int readVarInt64ZE() {
    final raw = readVarUint64();
    return raw >> 1;
  }

  /// Writes a 64 bit unsigned zigzag-encoded number.
  /// @param [int] v
  void writeVarInt64ZE(int v) {
    return writeVarUint64((v << 1) ^ (v >> 63));
  }

  /// Reads a 64 bit unsigned variable-length number.
  /// @returns [int]
  int readVarUint64() {
    var value = 0;
    for (var i = 0; i <= 63; i += 7) {
      if (feof()) {
        throw Exception('No bytes left in buffer long');
      }
      final b = readUint8();
      value |= (b & 0x7f) << i;

      if ((b & 0x80) == 0) {
        return value;
      }
    }

    throw Exception('VarLong did not terminate after 10 bytes!');
  }

  /// Writes a 64 bit unsigned variable-length number.
  /// @param [int] v
  void writeVarUint64(int v) {
    var v2 = v;
    for (var i = 0; i < 10; ++i) {
      if (v2 >> 7 != 0) {
        writeUint8(v2 | 0x80);
      } else {
        writeUint8(v2 & 0x7f);
        break;
      }
      v2 >>= 7;
    }
  }

  /// Reads a utf-8 string.
  /// @returns [String]
  String readString() {
    final length = readVarUint32();
    return utf8Codec.decode(read(length).asUint8List());
  }

  /// Writes a utf-8 string.
  /// @param [String] v
  void writeString(String v) {
    final buffer = Uint8List.fromList(utf8Codec.encode(v)).buffer;
    writeVarUint32(buffer.lengthInBytes);
    write(buffer);
  }

  /// Reads a ascii string.
  /// @returns [String]
  String readLELengthASCIIString() {
    final strLen = readUint32LE();
    final str = ascii8Codec.decode(read(strLen).asUint8List());
    return str;
  }

  /// Writes a ascii string.
  /// @param [String] v
  void writeLELengthASCIIString(String v) {
    final buffer = Uint8List.fromList(ascii8Codec.encode(v)).buffer;
    writeUint32LE(buffer.lengthInBytes);
    write(buffer);
  }

  /// Reads [Vector3].
  /// @returns [Vector3]
  Vector3 readVector3() {
    return Vector3(readFloat32(), readFloat32(), readFloat32());
  }

  /// Writes [Vector3].
  /// @param [Vector3] v
  void writeVector3(Vector3 v) {
    writeFloat32(v.x);
    writeFloat32(v.y);
    writeFloat32(v.z);
  }

  /// Reads [Vector3].
  /// @returns [Vector3]
  Vector3 readVector3LE() {
    return Vector3(readFloat32LE(), readFloat32LE(), readFloat32LE());
  }

  /// Writes [Vector3].
  /// @param [Vector3] v
  void writeVector3LE(Vector3 v) {
    writeFloat32LE(v.x);
    writeFloat32LE(v.y);
    writeFloat32LE(v.z);
  }

  /// Reads [Vector3].
  /// @returns [Vector3]
  Vector3 readVector3VarInt32() {
    return Vector3(
      readVarInt32().toDouble(),
      readVarInt32().toDouble(),
      readVarInt32().toDouble(),
    );
  }

  /// Writes [Vector3].
  /// @param [Vector3] v
  void writeVector3VarInt32(Vector3 v) {
    writeVarInt32(v.x.toInt());
    writeVarInt32(v.y.toInt());
    writeVarInt32(v.z.toInt());
  }

  /// Reads [Vector2].
  /// @returns [Vector2]
  Vector2 readVector2() {
    return Vector2(readFloat32(), readFloat32());
  }

  /// Writes [Vector2].
  /// @param [Vector2] v
  void writeVector2(Vector2 v) {
    writeFloat32(v.x);
    writeFloat32(v.y);
  }

  /// Reads [Vector2].
  /// @returns [Vector2]
  Vector2 readVector2LE() {
    return Vector2(readFloat32LE(), readFloat32LE());
  }

  /// Writes [Vector2].
  /// @param [Vector2] v
  void writeVector2LE(Vector2 v) {
    writeFloat32LE(v.x);
    writeFloat32LE(v.y);
  }

  /// Reads [Vector2].
  /// @returns [Vector2]
  Vector2 readVector2VarInt32() {
    return Vector2(
      readVarInt32().toDouble(),
      readVarInt32().toDouble(),
    );
  }

  /// Writes [Vector2].
  /// @param [Vector2] v
  void writeVector2VarInt32(Vector2 v) {
    writeVarInt32(v.x.toInt());
    writeVarInt32(v.y.toInt());
  }

  /// Increases the write offset by the given length.
  /// @param [int] len
  int addOffset(int len) {
    return (readIndex += len) - len;
  }

  /// Returns whatever or not the read offset is at end of line.
  /// @returns [int]
  bool feof() {
    return buffer.asUint8List().elementAtOrNull(readIndex) == null;
  }

  /// Reads the remaining bytes and returns the buffer slice.
  /// @returns [ByteBuffer]
  ByteBuffer readRemaining() {
    final buf = buffer.asUint8List().sublist(readIndex).buffer;
    readIndex = buffer.lengthInBytes;
    return buf;
  }

  /// Skips len bytes on the buffer.
  /// @param [int] len
  void skip(int len) {
    // assert(len is int, 'Cannot skip a float amount of bytes');
    readIndex += len;
  }

  /// Do read assertions, check if the read buffer is null.
  /// @param [int] v
  void doReadAssertions(int v) {
    assert(
      buffer.lengthInBytes >= v,
      'Cannot read without buffer data!',
    );
  }

  /// Do read assertions, check if the read buffer is null.
  /// @param [num] v
  /// @param [num] min
  /// @param [num] max
  void doWriteAssertions(num v, num min, num max) {
    assert(
      (v >= min) && (v <= max),
      'Value out of bounds: value=$v, min=$min, max=$max',
    );
  }
}
