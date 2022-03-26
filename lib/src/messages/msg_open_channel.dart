import 'dart:typed_data';

import 'package:atmos_binary_buffer/atmos_binary_buffer.dart';
import 'package:meta/meta.dart';

import '../interfaces/i_msg.dart';
import '../msg_decoder.dart';

@immutable
class MsgOpenChannelRequest implements IMsg {
  const MsgOpenChannelRequest(this.id);

  factory MsgOpenChannelRequest.binDecode(BinaryReader reader) {
    final id = reader.readSize();
    return MsgOpenChannelRequest(id);
  }

  factory MsgOpenChannelRequest.jsonDecode(JsonMap json) {
    final id = json['id'] as int;
    return MsgOpenChannelRequest(id);
  }

  static const typeId = 5;

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
  String toString() => 'MsgOpenChannelRequest(id=$id)';
}

@immutable
class MsgChannelWrap implements IMsg {
  const MsgChannelWrap(this.id, this.msg, this.decoder);

  factory MsgChannelWrap.binDecode(BinaryReader reader, MsgDecoder decoder) {
    final id = reader.readSize();
    final msg = decoder.binDecode(reader);
    return MsgChannelWrap(id, msg, decoder);
  }

  factory MsgChannelWrap.jsonDecode(JsonMap json, MsgDecoder decoder) {
    final id = json['id'] as int;
    final msg = decoder.jsonDecode(json['msg'] as JsonMap);
    return MsgChannelWrap(id, msg, decoder);
  }

  static const typeId = 6;

  @override
  final int id;
  final IMsg msg;
  final MsgDecoder decoder;

  @override
  Uint8List get toBytes {
    final writer = BinaryWriter()
      ..writeSize(typeId)
      ..writeSize(id);
    final data = msg.toBytes;
    writer.writeListUint8(data, size: data.length);
    return writer.takeBytes();
  }

  @override
  Map<String, Object?> get toJson => {
        'type': typeId,
        'id': id,
        'msg': msg.toJson,
      };

  @override
  String toString() => 'MsgChannelWrap(id=$id, msg=$msg)';
}
