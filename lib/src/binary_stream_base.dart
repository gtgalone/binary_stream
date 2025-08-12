import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math.dart';

class BinaryStream {
  /// Creates a new BinaryStream instance.
  BinaryStream({List<int>? bytes}) {
    if (bytes != null) {
      binary.addAll(bytes);
    }
  }

  List<int> binary = [];

  int readIndex = 0;
  int writeIndex = 0;

  /// Returns the encoded byte.
  /// @returns [ByteData]
  ByteData? _byteData;
  ByteData get byteData => _byteData ?? buffer.asByteData();

  /// Returns the encoded buffer.
  /// @returns [ByteBuffer]
  ByteBuffer get buffer => Uint8List.fromList(binary).buffer;

  /// Reads a slice of bytes by the given length.
  /// @param [int] len
  /// @returns [List]
  List<int> read(int len) {
    doReadAssertions(len);
    return binary.sublist(readIndex, readIndex += len);
  }

  /// Appends bytes to the main bytes.
  /// @param [List] bytes
  void write(List<int> bytes) {
    binary.addAll(bytes);
    addOffsetWrite(bytes.length);
  }

  /// Reads a signed byte (-128 to 127).
  /// @returns [int]
  int readInt8() {
    doReadAssertions(1);
    return byteData.getInt8(readIndex++);
  }

  /// Writes a signed byte (-128 to 127).
  /// @param [int] v
  void writeInt8(int v) {
    var v2 = v;
    if (v2 < 0) {
      v2 = 0xff + v2 + 1;
    }
    write([v2 & 0xff]);
  }

  /// Reads an unsigned byte (0 to 255).
  /// @returns [int]
  int readUint8() {
    doReadAssertions(1);
    return byteData.getUint8(readIndex++);
  }

  /// Writes an unsigned byte (0 to 255).
  /// @param [int] v
  void writeUint8(int v) {
    write([v & 0xff]);
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
    return byteData.getInt16(addOffsetRead(2));
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
    return byteData.getInt16(addOffsetRead(2), Endian.little);
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
    return byteData.getUint16(addOffsetRead(2));
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
    return byteData.getUint16(addOffsetRead(2), Endian.little);
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
    final bytes = Uint8List.fromList([readInt8(), readInt8(), readInt8()]);
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
    final bytes = Uint8List.fromList([readInt8(), readInt8(), readInt8()]);
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
    final bytes = Uint8List.fromList([readUint8(), readUint8(), readUint8()]);
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
    final bytes = Uint8List.fromList([readUint8(), readUint8(), readUint8()]);
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
    return byteData.getInt32(addOffsetRead(4));
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
    return byteData.getInt32(addOffsetRead(4), Endian.little);
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
    return byteData.getUint32(addOffsetRead(4));
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
    return byteData.getUint32(addOffsetRead(4), Endian.little);
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
    return byteData.getFloat32(addOffsetRead(4));
  }

  /// Writes a 32 bit (4 bytes) big-endian floating point number.
  /// @param [int] v
  void writeFloat32(double v) {
    doWriteAssertions(v, -3.4028234663852886e38, 3.4028234663852886e38);
    final b = ByteData(4);
    b.setFloat32(0, v);
    binary.addAll(b.buffer.asUint8List());
    addOffsetWrite(4);
  }

  /// Returns a 32 bit (4 bytes) little-endian flating point number.
  /// @returns [int]
  double readFloat32LE() {
    doReadAssertions(4);
    return byteData.getFloat32(addOffsetRead(4), Endian.little);
  }

  /// Writes a 32 bit (4 bytes) little-endian floating point number.
  /// @param [int] v
  void writeFloat32LE(double v) {
    doWriteAssertions(v, -3.4028234663852886e38, 3.4028234663852886e38);
    final b = ByteData(4);
    b.setFloat32(0, v, Endian.little);
    binary.addAll(b.buffer.asUint8List());
    addOffsetWrite(4);
  }

  /// Returns a 64 bit (8 bytes) big-endian flating point number.
  /// @returns [int]
  double readFloat64() {
    doReadAssertions(8);
    return byteData.getFloat64(addOffsetRead(8));
  }

  /// Writes a 64 bit (8 bytes) big-endian floating point number.
  /// @param [int] v
  void writeFloat64(double v) {
    doWriteAssertions(v, -1.7976931348623157e308, 1.7976931348623157e308);
    final b = ByteData(8);
    b.setFloat32(0, v);
    binary.addAll(b.buffer.asUint8List());
    addOffsetWrite(8);
  }

  /// Returns a 64 bit (8 bytes) little-endian flating point number.
  /// @returns [int]
  double readFloat64LE() {
    doReadAssertions(8);
    return byteData.getFloat64(addOffsetRead(8), Endian.little);
  }

  /// Writes a 64 bit (8 bytes) little-endian floating point number.
  /// @param [int] v
  void writeFloat64LE(double v) {
    doWriteAssertions(v, -1.7976931348623157e308, 1.7976931348623157e308);
    final b = ByteData(8);
    b.setFloat32(0, v, Endian.little);
    binary.addAll(b.buffer.asUint8List());
    addOffsetWrite(8);
  }

  /// Returns a 64 bit (8 bytes) signed big-endian number.
  /// @returns [int]
  int readInt64() {
    doReadAssertions(8);
    return byteData.getInt64(addOffsetRead(8));
  }

  /// Writes a 64 bit (8 bytes) signed big-endian number.
  /// @param [int] v
  void writeInt64(int v) {
    final b = ByteData(8);
    b.setInt64(0, v);
    binary.addAll(b.buffer.asUint8List());
    addOffsetWrite(8);
  }

  /// Returns a 64 bit (8 bytes) signed little-endian number.
  /// @returns [int]
  int readInt64LE() {
    doReadAssertions(8);
    return byteData.getInt64(addOffsetRead(8), Endian.little);
  }

  /// Writes a 64 bit (8 bytes) signed little-endian number.
  /// @param [int] v
  void writeInt64LE(int v) {
    final b = ByteData(8);
    b.setInt64(0, v, Endian.little);
    binary.addAll(b.buffer.asUint8List());
    addOffsetWrite(8);
  }

  /// Returns a 64 bit (8 bytes) unsigned big-endian number.
  /// @returns [int]
  int readUint64() {
    doReadAssertions(8);
    return byteData.getUint64(addOffsetRead(8));
  }

  /// Writes a 64 bit (8 bytes) unsigned big-endian number.
  /// @param [int] v
  void writeUint64(int v) {
    final b = ByteData(8);
    b.setUint64(0, v);
    binary.addAll(b.buffer.asUint8List());
    addOffsetWrite(8);
  }

  /// Returns a 64 bit (8 bytes) unsigned little-endian number.
  /// @returns [int]
  int readUint64LE() {
    doReadAssertions(8);
    return byteData.getUint64(addOffsetRead(8), Endian.little);
  }

  /// Writes a 64 bit (8 bytes) unsigned little-endian number.
  /// @param [int] v
  void writeUint64LE(int v) {
    final b = ByteData(8);
    b.setUint64(0, v, Endian.little);
    binary.addAll(b.buffer.asUint8List());
    addOffsetWrite(8);
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
      if (feof()) {
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
    return _utf8Codec.decode(read(length));
  }

  /// Writes a utf-8 string.
  /// @param [String] v
  void writeString(String v) {
    final bytes = Uint8List.fromList(_utf8Codec.encode(v));
    writeVarUint32(bytes.lengthInBytes);
    write(bytes);
  }

  /// Reads a ascii string.
  /// @returns [String]
  String readLELengthASCIIString() {
    final strLen = readUint32LE();
    final str = _ascii8Codec.decode(read(strLen));
    return str;
  }

  /// Writes a ascii string.
  /// @param [String] v
  void writeLELengthASCIIString(String v) {
    final bytes = Uint8List.fromList(_ascii8Codec.encode(v));
    writeUint32LE(bytes.lengthInBytes);
    write(bytes);
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
    return Vector2(readVarInt32().toDouble(), readVarInt32().toDouble());
  }

  /// Writes [Vector2].
  /// @param [Vector2] v
  void writeVector2VarInt32(Vector2 v) {
    writeVarInt32(v.x.toInt());
    writeVarInt32(v.y.toInt());
  }

  /// Reads [Uuid].
  /// @returns [Uuid]
  String readUuid() {
    var b = read(16);
    final b1 = b.sublist(0, 8);
    final b2 = b.sublist(8);
    b = Uint8List.fromList([...b2, ...b1]);
    final buf = Uint8List(16);
    for (var i = 0; i < b.length / 2; i++) {
      final j = b.length - 1 - i;
      final t = b[i];
      buf[i] = b[j];
      buf[j] = t;
    }
    return Uuid.unparse(buf);
  }

  /// Writes [Uuid].
  /// @param [String] v
  void writeUuid(String v) {
    final b = Uuid.parseAsByteList(v);
    final bytes = Uint8List(16);
    for (var i = 0; i < b.length / 2; i++) {
      final j = b.length - 1 - i;
      final t = b[i];
      bytes[i] = b[j];
      bytes[j] = t;
    }
    write(bytes);
  }

  /// Increases the read offset by the given length.
  /// @param [int] len
  int addOffsetRead(int len) {
    return (readIndex += len) - len;
  }

  /// Increases the write offset by the given length.
  /// @param [int] len
  int addOffsetWrite(int len) {
    return (writeIndex += len) - len;
  }

  /// Returns whatever or not the read offset is at end of line.
  /// @returns [int]
  bool feof() {
    return binary.length <= readIndex;
  }

  /// Reads the remaining bytes and returns the buffer slice.
  /// @returns [List]
  List<int> readRemaining() {
    final list = binary.sublist(readIndex);
    readIndex = binary.length;
    return list;
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
    assert(binary.length >= v, 'Cannot read without buffer data!');
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

  void resetOffset() {
    readIndex = 0;
    writeIndex = 0;
    _byteData = null;
  }

  void clear() {
    binary.clear();
    resetOffset();
  }

  BinaryStream clone() {
    return BinaryStream(bytes: binary);
  }
}

final _utf8Codec = const Utf8Codec();
final _ascii8Codec = const AsciiCodec();
