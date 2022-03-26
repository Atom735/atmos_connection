import 'dart:typed_data';

import 'package:atmos_binary_buffer/atmos_binary_buffer.dart';
import 'package:meta/meta.dart';

import '../interfaces/i_msg.dart';

@immutable
class MsgError implements IMsg {
  const MsgError(this.id, this.error);

  factory MsgError.binDecode(BinaryReader reader) {
    final id = reader.readSize();
    final error = reader.readString();
    return MsgError(id, error);
  }

  factory MsgError.jsonDecode(JsonMap json) {
    final id = json['id'] as int;
    final error = json['error'] as String;
    return MsgError(id, error);
  }

  static const typeId = 3;

  @override
  final int id;
  final String error;

  @override
  Uint8List get toBytes => (BinaryWriter()
        ..writeSize(typeId)
        ..writeSize(id)
        ..writeString(error))
      .takeBytes();

  @override
  JsonMap get toJson => {
        'type': typeId,
        'id': id,
        'error': error,
      };

  @override
  String toString() => 'MsgError(id=$id, error="$error")';
}
