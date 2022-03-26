import 'dart:async';

import 'package:atmos_logger/atmos_logger.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../interfaces/i_msg.dart';
import '../interfaces/i_msg_connection.dart';
import '../messages/msg_handshake.dart';
import '../msg_decoder.dart';
import 'msg_connection_base.dart';

class MsgConnectionServerWebSocket extends MsgConnectionBase {
  MsgConnectionServerWebSocket(this.ws, this.decoder) : super(2);

  final WebSocketChannel ws;
  late final StreamChannel<IMsg> channel = ws
      .transform(const MsgStreamChanngelDebugTransformer<Object?>(
              'Server connection RAW', LoggerConsole())
          .transformer)
      .transform(MsgStreamChanngelTransformer(decoder).transformerJson)
      .transform(const MsgStreamChanngelDebugTransformer<IMsg>(
              'Server connection', LoggerConsole())
          .transformer);

  @override
  int get id => 0;

  @override
  ConnectionTransferType transferType = ConnectionTransferType.json;

  @override
  final MsgDecoder decoder;

  @override
  void send(IMsg msg) => channel.sink.add(msg);

  @override
  StreamSink<IMsg> get sink => channel.sink;

  @override
  Stream<IMsg> get stream => channel.stream;

  @override
  int get version => 1;

  @override
  IMsgConnection virtualChannel([int? id]) {
    // TODO: implement virtualChannel
    throw UnimplementedError();
  }

  bool handshaked = false;

  @override
  void handleMsg(IMsg msg) {
    if (msg is MsgHandshake) {
      send(MsgHandshake(id, version));
      handshaked = true;
    }
    super.handleMsg(msg);
  }
}
