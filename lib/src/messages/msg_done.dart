import 'dart:typed_data';

import 'package:atmos_binary_buffer/atmos_binary_buffer.dart';
import 'package:meta/meta.dart';

import '../interfaces/i_msg.dart';

@immutable
class MsgDone implements IMsg {
  const MsgDone(this.id);

  factory MsgDone.binDecode(BinaryReader reader) {
    final id = reader.readSize();
    return MsgDone(id);
  }

  factory MsgDone.jsonDecode(JsonMap json) {
    final id = json['id'] as int;
    return MsgDone(id);
  }

  static const typeId = 2;

  @override
  final int id;

  @override
  Uint8List get toBytes => (BinaryWriter()
        ..writeSize(typeId)
        ..writeSize(id))
      .takeBytes();

  @override
  Map<String, Object?> get toJson => {
        'type': typeId,
        'id': id,
      };

  @override
  String toString() => 'MsgDone(id=$id)';
}
