import 'dart:convert';
import 'dart:typed_data';

import 'package:atmos_binary_buffer/atmos_binary_buffer.dart';
import 'package:meta/meta.dart';

import 'interfaces/i_msg.dart';
import 'messages/msg_done.dart';
import 'messages/msg_error.dart';
import 'messages/msg_handshake.dart';
import 'messages/msg_open_channel.dart';
import 'messages/msg_unknown.dart';

@immutable
class MsgDecoder extends Converter<Object?, IMsg> {
  @literal
  const MsgDecoder();

  @override
  @nonVirtual
  IMsg convert(Object? input) {
    if (input is Uint8List) {
      return binDecode(BinaryReader(input));
    } else if (input is String) {
      input = const JsonDecoder().convert(input);
    }
    if (input is JsonMap) {
      return jsonDecode(input);
    }
    throw Exception('Unknowns data');
  }

  @override
  @nonVirtual
  Sink<Object?> startChunkedConversion(Sink<IMsg> sink) => _Sink(this, sink);

  @mustCallSuper
  IMsg binDecode(BinaryReader reader) {
    final type = reader.readSize();
    switch (type) {
      case MsgHandshake.typeId:
        return MsgHandshake.binDecode(reader);
      case MsgDone.typeId:
        return MsgDone.binDecode(reader);
      case MsgError.typeId:
        return MsgError.binDecode(reader);
      case MsgOpenChannelRequest.typeId:
        return MsgOpenChannelRequest.binDecode(reader);
      case MsgChannelWrap.typeId:
        return MsgChannelWrap.binDecode(reader, this);
      default:
        return MsgUnknown.binDecode(type, reader);
    }
  }

  @mustCallSuper
  IMsg jsonDecode(JsonMap json) {
    final type = json['type'] as int;
    switch (type) {
      case MsgHandshake.typeId:
        return MsgHandshake.jsonDecode(json);
      case MsgDone.typeId:
        return MsgDone.jsonDecode(json);
      case MsgError.typeId:
        return MsgError.jsonDecode(json);
      case MsgOpenChannelRequest.typeId:
        return MsgOpenChannelRequest.jsonDecode(json);
      case MsgChannelWrap.typeId:
        return MsgChannelWrap.jsonDecode(json, this);
      default:
        return MsgUnknown.jsonDecode(type, json);
    }
  }
}

@immutable
class _Sink implements Sink<Object?> {
  const _Sink(this.decoder, this.sink);

  final MsgDecoder decoder;
  final Sink<IMsg> sink;

  @override
  void add(Object? data) {
    sink.add(decoder.convert(data));
  }

  @override
  void close() => sink.close();
}
