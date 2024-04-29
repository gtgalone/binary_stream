import 'package:binary_stream/binary_stream.dart';

void main() {
  var binaryStream = BinaryStream();
  binaryStream.writeInt32(1);

  print('Int: ${binaryStream.readInt32()}');
}
