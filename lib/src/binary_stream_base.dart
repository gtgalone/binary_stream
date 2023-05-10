import 'dart:convert';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:vector_math/vector_math.dart';

class BinaryStream {
  final utf8Codec = const Utf8Codec();
  final ascii8Codec = const AsciiCodec();

  List<int> binary = [];
  ByteBuffer? buffer;
  late int readIndex;
  int writeIndex = 0;

  /// Creates a new BinaryStream instance.
  /// @param [ByteBuffer] buffer - The array or Buffer containing binary data.
  /// @param [int] offset - The initial pointer position.
  BinaryStream([this.buffer, int offset = 0]) {
    readIndex = offset;
  }

  /// Reads a slice of buffer by the given length.
  /// @param [int] len
  ByteBuffer read(int len) {
    doReadAssertions(len);
    return buffer!.asUint8List().sublist(readIndex, readIndex += len).buffer;
  }

  /// Appends a buffer to the main buffer.
  /// @param [ByteBuffer] buf
  void write(ByteBuffer buf) {
    binary = [...binary, ...buf.asUint8List()];
    writeIndex += buf.lengthInBytes;
  }

  /// Reads an unsigned byte (0 to 255).
  /// @returns [int]
  int readByte() {
    doReadAssertions(1);
    return buffer!.asByteData().getUint8(readIndex++);
  }

  /// Writes an unsigned byte (0 to 255).
  /// @param [int] v
  void writeByte(int v) {
    writeIndex++;
    binary.add(v & 0xff);
  }

  /// Reads a signed byte (-128 to 127).
  /// @returns [int]
  int readSignedByte() {
    doReadAssertions(1);
    return buffer!.asByteData().getInt8(readIndex++);
  }

  /// Writes a signed byte (-128 to 127).
  /// @param [int] v
  void writeSignedByte(int v) {
    var v2 = v;
    if (v2 < 0) {
      v2 = 0xff + v2 + 1;
    }
    writeIndex++;
    binary.add(v2 & 0xff);
  }

  /// Reads a boolean (true or false).
  /// @returns [bool]
  bool readBoolean() {
    doReadAssertions(1);
    return readByte() == 1;
  }

  /// Writes a boolean (true or false).
  /// @param [bool] v
  void writeBoolean(bool v) {
    writeByte(v ? 1 : 0);
  }

  /// Reads a 16 bit (2 bytes) signed big-endian number.
  /// @returns [int]
  int readShort() {
    doReadAssertions(2);
    return buffer!.asByteData().getInt16(addOffset(2));
  }

  /// Writes a 16 bit (2 bytes) signed big-endian number.
  /// @param [int] v
  void writeShort(int v) {
    doWriteAssertions(v, -32768, 32767);
    writeByte(v >> 8);
    writeByte(v);
  }

  /// Reads a 16 bit (2 bytes) signed little-endian number.
  /// @returns [int]
  int readShortLE() {
    doReadAssertions(2);
    return buffer!.asByteData().getInt16(addOffset(2), Endian.little);
  }

  /// Writes a 16 bit (2 bytes) signed big-endian number.
  /// @param [int] v
  void writeShortLE(int v) {
    doWriteAssertions(v, -32768, 32767);
    writeByte(v);
    writeByte(v >> 8);
  }

  /// Reads a 16 bit (2 bytes) unsigned big-endian number.
  /// @returns [int]
  int readUnsignedShort() {
    doReadAssertions(2);
    return buffer!.asByteData().getUint16(addOffset(2));
  }

  /// Writes a 16 bit (2 bytes) unsigned big-endian number.
  /// @param [int] v
  void writeUnsignedShort(int v) {
    doWriteAssertions(v, 0, 65535);
    writeByte(v >>> 8);
    writeByte(v);
  }

  /// Reads a 16 bit (2 bytes) unsigned little-endian number.
  /// @returns [int]
  int readUnsignedShortLE() {
    doReadAssertions(2);
    return buffer!.asByteData().getUint16(addOffset(2), Endian.little);
  }

  /// Writes a 16 bit (2 bytes) unsigned little-endian number.
  /// @param [int] v
  void writeUnsignedShortLE(int v) {
    doWriteAssertions(v, 0, 65535);
    writeByte(v);
    writeByte(v >>> 8);
  }

  /// Reads a 24 bit (3 bytes) signed big-endian number.
  /// @returns [int]
  int readTriad() {
    doReadAssertions(3);

    final bytes = Uint8List.fromList([
      readByte(),
      readByte(),
      readByte(),
    ]);

    return bytes[0] << 16 | bytes[1] << 8 | bytes[2];
  }

  /// Writes a 24 bit (3 bytes) signed big-endian number.
  /// @param [int] v
  void writeTriad(int v) {
    doWriteAssertions(v, -8388608, 8388607);
    writeByte((v & 0xff0000) >> 16); // msb
    writeByte((v & 0x00ff00) >> 8); // mib
    writeByte(v & 0x0000ff); // lsb
  }

  /// Reads a 24 bit (3 bytes) little-endian number.
  /// @returns [int]
  int readTriadLE() {
    doReadAssertions(3);

    final bytes = Uint8List.fromList([
      readByte(),
      readByte(),
      readByte(),
    ]);

    return bytes[2] << 16 | bytes[1] << 8 | bytes[0];
  }

  /// Writes a 24 bit (3 bytes) signed little-endian number.
  /// @param [int] v
  void writeTriadLE(int v) {
    doWriteAssertions(v, -8388608, 8388607);
    writeByte(v & 0x0000ff);
    writeByte((v & 0x00ff00) >> 8);
    writeByte((v & 0xff0000) >> 16);
  }

  /// Reads a 24 bit (3 bytes) unsigned big-endian number.
  /// @returns [int]
  int readUnsignedTriad() {
    doReadAssertions(3);

    final bytes = Uint8List.fromList([
      readByte(),
      readByte(),
      readByte(),
    ]);

    return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16);
  }

  /// Writes a 24 bit (3 bytes) unsigned big-endian number.
  /// @param [int] v
  void writeUnsignedTriad(int v) {
    doWriteAssertions(v, 0, 16777215);
    writeByte((v & 0xff0000) >>> 16); // msb
    writeByte((v & 0x00ff00) >>> 8); // mib
    writeByte(v & 0x0000ff); // lsb
  }

  /// Reads a 24 bit (3 bytes) unsigned little-endian number.
  /// @returns [int]
  int readUnsignedTriadLE() {
    doReadAssertions(3);

    final bytes = Uint8List.fromList([
      readByte(),
      readByte(),
      readByte(),
    ]);

    return bytes[2] | (bytes[1] << 8) | (bytes[0] << 16);
  }

  /// Writes a 24 bit (3 bytes) unsigned little-endian number.
  /// @param [int] v
  void writeUnsignedTriadLE(int v) {
    doWriteAssertions(v, 0, 16777215);
    writeByte(v & 0x0000ff);
    writeByte((v & 0x00ff00) >>> 8);
    writeByte((v & 0xff0000) >>> 16);
  }

  /// Reads a 32 bit (4 bytes) big-endian signed number.
  /// @returns [int]
  int readInt() {
    doReadAssertions(4);
    return buffer!.asByteData().getInt32(addOffset(4));
  }

  /// Writes a 32 bit (4 bytes) big-endian signed number.
  /// @param [int] v
  void writeInt(int v) {
    var v2 = v;
    if (v2 < 0) {
      v2 = v2 & (0xffffffff + v2 + 1);
    }
    doWriteAssertions(v2, -2147483648, 2147483647);
    writeByte(v2 >> 24);
    writeByte(v2 >> 16);
    writeByte(v2 >> 8);
    writeByte(v2);
  }

  /// Reads a 32 bit (4 bytes) signed number.
  /// @returns [int]
  int readIntLE() {
    doReadAssertions(4);
    return buffer!.asByteData().getInt32(addOffset(4), Endian.little);
  }

  /// Writes a 32 bit (4 bytes) little-endian signed number.
  /// @param [int] v
  void writeIntLE(int v) {
    var v2 = v;
    if (v2 < 0) {
      v2 = v2 & (0xffffffff + v2 + 1);
    }
    doWriteAssertions(v2, -2147483648, 2147483647);
    writeByte(v2);
    writeByte(v2 >> 8);
    writeByte(v2 >> 16);
    writeByte(v2 >> 24);
  }

  /// Reads a 32 bit (4 bytes) big-endian unsigned number.
  /// @returns [int]
  int readUnsignedInt() {
    doReadAssertions(4);
    return buffer!.asByteData().getUint32(addOffset(4));
  }

  /// Writes a 32 bit (4 bytes) big-endian unsigned number.
  /// @param [int] v
  void writeUnsignedInt(int v) {
    doWriteAssertions(v, 0, 4294967295);
    writeByte(v >>> 24);
    writeByte(v >>> 16);
    writeByte(v >>> 8);
    writeByte(v);
  }

  /// Reads a 32 bit (4 bytes) little-endian unsigned number.
  /// @returns [int]
  int readUnsignedIntLE() {
    doReadAssertions(4);
    return buffer!.asByteData().getUint32(addOffset(4), Endian.little);
  }

  /// Writes a 32 bit (4 bytes) little-endian unsigned number.
  /// @param [int] v
  void writeUnsignedIntLE(int v) {
    doWriteAssertions(v, 0, 4294967295);
    writeByte(v);
    writeByte(v >>> 8);
    writeByte(v >>> 16);
    writeByte(v >>> 24);
  }

  /// Returns a 32 bit (4 bytes) big-endian flating point number.
  /// @returns [int]
  double readFloat() {
    doReadAssertions(4);
    return buffer!.asByteData().getFloat32(addOffset(4));
  }

  /// Writes a 32 bit (4 bytes) big-endian floating point number.
  /// @param [int] v
  void writeFloat(double v) {
    doWriteAssertions(
      v,
      -3.4028234663852886e38,
      3.4028234663852886e38,
    );

    write(Float32List.fromList([v]).buffer);
  }

  /// Returns a 32 bit (4 bytes) little-endian flating point number.
  /// @returns [int]
  double readFloatLE() {
    doReadAssertions(4);
    return buffer!.asByteData().getFloat32(addOffset(4), Endian.little);
  }

  /// Writes a 32 bit (4 bytes) little-endian floating point number.
  /// @param [int] v
  void writeFloatLE(double v) {
    doWriteAssertions(
      v,
      -3.4028234663852886e38,
      3.4028234663852886e38,
    );

    write(
      Uint8List.fromList(
        Float32List.fromList([v]).buffer.asUint8List().reversed.toList(),
      ).buffer,
    );
  }

  /// Returns a 64 bit (8 bytes) big-endian flating point number.
  /// @returns [int]
  double readDouble() {
    doReadAssertions(8);
    return buffer!.asByteData().getFloat64(addOffset(8));
  }

  /// Writes a 64 bit (8 bytes) big-endian floating point number.
  /// @param [int] v
  void writeDouble(double v) {
    doWriteAssertions(
      v,
      -1.7976931348623157e308,
      1.7976931348623157e308,
    );

    write(Float64List.fromList([v]).buffer);
  }

  /// Returns a 64 bit (8 bytes) little-endian flating point number.
  /// @returns [int]
  double readDoubleLE() {
    doReadAssertions(8);
    return buffer!.asByteData().getFloat64(addOffset(8), Endian.little);
  }

  /// Writes a 64 bit (8 bytes) little-endian floating point number.
  /// @param [int] v
  void writeDoubleLE(double v) {
    doWriteAssertions(
      v,
      -1.7976931348623157e308,
      1.7976931348623157e308,
    );

    write(
      Uint8List.fromList(
        Float64List.fromList([v]).buffer.asUint8List().reversed.toList(),
      ).buffer,
    );
  }

  /// Returns a 64 bit (8 bytes) signed big-endian number.
  /// @returns [int]
  int readLong() {
    doReadAssertions(8);
    return buffer!.asByteData().getInt64(addOffset(8));
  }

  /// Writes a 64 bit (8 bytes) signed big-endian number.
  /// @param [int] v
  void writeLong(int v) {
    final hi = (v >> 32) & 0xffffffff;
    writeIndex++;
    binary.add(hi >> 24);
    writeIndex++;
    binary.add(hi >> 16);
    writeIndex++;
    binary.add(hi >> 8);
    writeIndex++;
    binary.add(hi);
    final lo = v & 0xffffffff;
    writeIndex++;
    binary.add(lo >> 24);
    writeIndex++;
    binary.add(lo >> 16);
    writeIndex++;
    binary.add(lo >> 8);
    writeIndex++;
    binary.add(lo);
  }

  /// Returns a 64 bit (8 bytes) signed little-endian number.
  /// @returns [int]
  int readLongLE() {
    doReadAssertions(8);
    return buffer!.asByteData().getInt64(addOffset(8), Endian.little);
  }

  /// Writes a 64 bit (8 bytes) signed big-endian number.
  /// @param [int] v
  void writeLongLE(int v) {
    final lo = v & 0xffffffff;
    writeIndex++;
    binary.add(lo);
    writeIndex++;
    binary.add(lo >> 8);
    writeIndex++;
    binary.add(lo >> 16);
    writeIndex++;
    binary.add(lo >> 24);
    final hi = (v >> 32) & 0xffffffff;
    writeIndex++;
    binary.add(hi);
    writeIndex++;
    binary.add(hi >> 8);
    writeIndex++;
    binary.add(hi >> 16);
    writeIndex++;
    binary.add(hi >> 24);
  }

  /// Returns a 64 bit (8 bytes) unsigned big-endian number.
  /// @returns [int]
  int readUnsignedLong() {
    doReadAssertions(8);
    return buffer!.asByteData().getUint64(addOffset(8));
  }

  /// Writes a 64 bit (8 bytes) unsigned big-endian number.
  /// @param [int] v
  void writeUnsignedLong(int v) {
    final hi = (v >> 32) & 0xffffffff;
    writeIndex++;
    binary.add(hi >> 24);
    writeIndex++;
    binary.add(hi >> 16);
    writeIndex++;
    binary.add(hi >> 8);
    writeIndex++;
    binary.add(hi);
    final lo = v & 0xffffffff;
    writeIndex++;
    binary.add(lo >> 24);
    writeIndex++;
    binary.add(lo >> 16);
    writeIndex++;
    binary.add(lo >> 8);
    writeIndex++;
    binary.add(lo);
  }

  /// Returns a 64 bit (8 bytes) unsigned little-endian number.
  /// @returns [int]
  int readUnsignedLongLE() {
    doReadAssertions(8);
    return buffer!.asByteData().getUint64(addOffset(8), Endian.little);
  }

  /// Writes a 64 bit (8 bytes) unsigned big-endian number.
  /// @param [int] v
  void writeUnsignedLongLE(int v) {
    final lo = v & 0xffffffff;
    writeIndex++;
    binary.add(lo);
    writeIndex++;
    binary.add(lo >> 8);
    writeIndex++;
    binary.add(lo >> 16);
    writeIndex++;
    binary.add(lo >> 24);
    final hi = (v >> 32) & 0xffffffff;
    writeIndex++;
    binary.add(hi);
    writeIndex++;
    binary.add(hi >> 8);
    writeIndex++;
    binary.add(hi >> 16);
    writeIndex++;
    binary.add(hi >> 24);
  }

  /// Reads a 32 bit (4 bytes) zigzag-encoded number.
  /// @returns [int]
  int readVarInt() {
    final raw = readUnsignedVarInt();
    final temp = (((raw << 63) >> 63) ^ raw) >> 1;
    return temp ^ (raw & (1 << 63));
  }

  /// Writes a 32 bit (4 bytes) zigzag-encoded number.
  /// @param [int] v
  void writeVarInt(int v) {
    var v2 = v;
    v2 = (v2 << 32) >> 32;
    return writeUnsignedVarInt((v2 << 1) ^ (v2 >> 31));
  }

  /// Reads a 32 bit unsigned number.
  /// @returns [int]
  int readUnsignedVarInt() {
    assert(buffer != null, 'Reading on empty buffer!');
    var value = 0;
    for (var i = 0; i <= 28; i += 7) {
      if (buffer!.asUint8List().elementAtOrNull(readIndex) == null) {
        throw Exception('No bytes left in buffer int');
      }
      final b = readByte();
      value |= (b & 0x7f) << i;

      if ((b & 0x80) == 0) {
        return value;
      }
    }

    throw Exception('VarInt did not terminate after 5 bytes!');
  }

  /// Writes a 32 bit unsigned number with variable-length.
  /// @param [int] v
  void writeUnsignedVarInt(int v) {
    var v2 = v;
    while ((v2 & 0xffffff80) != 0) {
      writeByte((v2 & 0x7f) | 0x80);
      v2 >>>= 7;
    }
    writeByte(v2 & 0x7f);
  }

  /// Reads a 64 bit zigzag-encoded variable-length number.
  /// @returns [int]
  int readVarLong() {
    final raw = readUnsignedVarLong();
    return raw >> 1;
  }

  /// Writes a 64 bit unsigned zigzag-encoded number.
  /// @param [int] v
  void writeVarLong(int v) {
    return writeUnsignedVarLong((v << 1) ^ (v >> 63));
  }

  /// Reads a 64 bit unsigned variable-length number.
  /// @returns [int]
  int readUnsignedVarLong() {
    var value = 0;
    for (var i = 0; i <= 63; i += 7) {
      if (feof()) {
        throw Exception('No bytes left in buffer long');
      }
      final b = readByte();
      value |= (b & 0x7f) << i;

      if ((b & 0x80) == 0) {
        return value;
      }
    }

    throw Exception('VarLong did not terminate after 10 bytes!');
  }

  /// Writes a 64 bit unsigned variable-length number.
  /// @param [int] v
  void writeUnsignedVarLong(int v) {
    var v2 = v;
    for (var i = 0; i < 10; ++i) {
      if (v2 >> 7 != 0) {
        writeByte(v2 | 0x80);
      } else {
        writeByte(v2 & 0x7f);
        break;
      }
      v2 >>= 7;
    }
  }

  /// Reads a utf-8 string.
  /// @returns [String]
  String readString() {
    final length = readUnsignedVarInt();
    return utf8Codec.decode(read(length).asUint8List());
  }

  /// Writes a utf-8 string.
  /// @param [String] v
  void writeString(String v) {
    final buffer = Uint8List.fromList(utf8Codec.encode(v)).buffer;
    writeUnsignedVarInt(buffer.lengthInBytes);
    write(buffer);
  }

  /// Reads a ascii string.
  /// @returns [String]
  String readLELengthASCIIString() {
    final strLen = readUnsignedIntLE();
    final str = ascii8Codec.decode(read(strLen).asUint8List());
    return str;
  }

  /// Writes a ascii string.
  /// @param [String] v
  void writeLELengthASCIIString(String v) {
    final buffer = Uint8List.fromList(ascii8Codec.encode(v)).buffer;
    writeUnsignedIntLE(buffer.lengthInBytes);
    write(buffer);
  }

  /// Reads [Vector3].
  /// @returns [Vector3]
  Vector3 readVector3() {
    return Vector3(readFloatLE(), readFloatLE(), readFloatLE());
  }

  /// Writes [Vector3].
  /// @param [Vector3] v
  void writeVector3(Vector3 v) {
    writeFloatLE(v.x);
    writeFloatLE(v.y);
    writeFloatLE(v.z);
  }

  /// Increases the write offset by the given length.
  /// @param [int] len
  int addOffset(int len) {
    return (readIndex += len) - len;
  }

  /// Returns whatever or not the read offset is at end of line.
  /// @returns [int]
  bool feof() {
    if (buffer == null) {
      throw Exception('Buffer is write only!');
    }
    return buffer!.asUint8List().elementAtOrNull(readIndex) == null;
  }

  /// Reads the remaining bytes and returns the buffer slice.
  /// @returns [ByteBuffer]
  ByteBuffer readRemaining() {
    if (buffer == null) {
      throw Exception('Buffer is write only!');
    }
    final buf = buffer!.asUint8List().sublist(readIndex).buffer;
    readIndex = buffer!.lengthInBytes;
    return buf;
  }

  /// Skips len bytes on the buffer.
  /// @param [int] len
  void skip(int len) {
    // assert(len is int, 'Cannot skip a float amount of bytes');
    readIndex += len;
  }

  /// Returns the encoded buffer.
  /// @returns [ByteBuffer]
  ByteBuffer getBuffer() {
    return (buffer != null) ? buffer! : Uint8List.fromList(binary).buffer;
  }

  /// Do read assertions, check if the read buffer is null.
  /// @param [int] v
  void doReadAssertions(int v) {
    assert(buffer != null, 'Cannot read without buffer data!');
    assert(
      buffer!.lengthInBytes >= v,
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
