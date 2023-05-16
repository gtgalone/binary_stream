import 'package:binary_stream/binary_stream.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final binaryStream = BinaryStream();

    setUp(() {
      binaryStream.writeInt(1);
    });

    test('First Test', () {
      expect(binaryStream.readInt(), 1);
    });
  });
}
