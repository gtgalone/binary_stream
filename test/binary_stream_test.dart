import 'package:binary_stream/binary_stream.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final binaryStream = BinaryStream();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(binaryStream.binary, isEmpty);
    });
  });
}
