# Binary Stream
[![pub package](https://img.shields.io/pub/v/binary_stream.svg)](https://pub.dartlang.org/packages/binary_stream)

Binary Stream to transfer binary between a server and a client.

## Features

* Support multiple data types

## Getting started

```yaml
dependencies:
  binary_stream: ^1.0.3
```

### Solving packages conflict
Add this code end of pubspec.yaml.
```yaml
dependency_overrides:
  collection: your package version
  vector_math: your package version
```

## Usage

```dart
void main() {
  var binaryStream = BinaryStream();
  binaryStream.writeInt32(1);

  print('Int: ${binaryStream.readInt32()}');
}
```
