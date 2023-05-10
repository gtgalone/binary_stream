# Binary Stream
[![pub package](https://img.shields.io/pub/v/binary_stream.svg)](https://pub.dartlang.org/packages/binary_stream)

Binary Stream to transfer binary between a server and a client.

## Features

* Support multiple data types

## Getting started

```dart
dependencies:
  binary_stream: ^1.0.0
```

## Usage

```dart
void main() {
  var binaryStream = BinaryStream();
  binaryStream.writeInt(1);

  print('Int: ${binaryStream.readInt()}');
}
```
