import 'dart:typed_data';

import 'package:atmos_binary_buffer/atmos_binary_buffer.dart';
import 'package:meta/meta.dart';

import '../interfaces/i_msg.dart';

/// Unknown Msg which send when recived msg have unknown type
@immutable
class MsgUnknown implements IMsg {
  const MsgUnknown(this.type, this.id, [this.data]);

  factory MsgUnknown.binDecode(int type, BinaryReader reader) {
    final id = reader.readSize();
    final length = reader.peek;
    final data = reader.readListUint8(size: length);
    return MsgUnknown(type, id, data);
  }

  factory MsgUnknown.jsonDecode(int type, JsonMap json) {
    final id = json['id'] as int? ?? 0;
    return MsgUnknown(type, id, json);
  }

  static const typeId = 0;

  final int type;
  @override
  final int id;

  final Object? data;

  @override
  Uint8List get toBytes => (BinaryWriter()
        ..writeSize(type)
        ..writeSize(id))
      .takeBytes();

  @override
  JsonMap get toJson => {
        'type': typeId,
        'id': id,
      };

  @override
  String toString() => 'MsgUnknown(type=$type, id=$id, data=$data)';
}
