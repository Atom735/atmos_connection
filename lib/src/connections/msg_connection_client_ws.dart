import 'dart:async';
import 'dart:typed_data';

import 'package:atmos_logger/atmos_logger.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../interfaces/i_msg.dart';
import '../interfaces/i_msg_connection.dart';
import '../messages/msg_handshake.dart';
import '../msg_decoder.dart';
import 'msg_connection_base.dart';

class MsgConnectionClientWebSocket extends MsgConnectionBase
    implements IMsgConnectionClient {
  MsgConnectionClientWebSocket(this.decoder) : super(2);

  StreamChannel<IMsg>? ws;

  final controller = StreamChannelController<IMsg>(sync: true);

  @override
  String adress = '';

  @override
  int get id => 0;

  @override
  ConnectionTransferType transferType = ConnectionTransferType.json;

  @override
  final MsgDecoder decoder;

  @override
  void send(IMsg msg) => sink.add(msg);

  @override
  StreamSink<IMsg> get sink => controller.local.sink;

  @override
  Stream<IMsg> get stream => controller.local.stream;

  @override
  int get version => 1;

  @override
  IMsgConnectionClient virtualChannel([int? id]) {
    // TODO: implement virtualChannel
    throw UnimplementedError();
  }

  @override
  Future<MsgHandshake> reconnect(String adress, [Uint8List? key]) async {
    await ws?.sink.close();
    this.adress = adress;
    statusCode = ConnectionStatus.connecting;
    statusErrorMsg = '';
    _suController.sink.add(this);
    ws = WebSocketChannel.connect(Uri.parse(adress))
        .transform(const MsgStreamChanngelDebugTransformer<Object?>(
                'Client connection RAW', LoggerConsole())
            .transformer)
        .transform(MsgStreamChanngelTransformer(decoder).transformerJson)
        .transform(const MsgStreamChanngelDebugTransformer<IMsg>(
                'Client connection', LoggerConsole())
            .transformer);
    // ..stream.listen(handleMsg, onError: (e) {
    //   statusCode = ConnectionStatus.error;
    //   statusErrorMsg = e.toString();
    //   _suController.sink.add(this);
    // });
    controller.foreign.pipe(ws!);
    final msg = await request(MsgHandshake(newMsgId, version));
    if (msg is MsgHandshake) {
      statusCode = ConnectionStatus.connected;
      statusErrorMsg = '';
      _suController.sink.add(this);
      return msg;
    }
    dispose();
    throw Exception();
  }

  @override
  ConnectionStatus statusCode = ConnectionStatus.unconnected;

  @override
  String statusErrorMsg = '';

  @override
  Stream<IMsgConnectionClient> get statusUpdates => _suController.stream;

  final _suController =
      StreamController<IMsgConnectionClient>.broadcast(sync: true);

  @override
  void dispose() {
    ws?.sink.close();
    controller.local.sink.close();
    _suController.close();
    super.dispose();
  }
}
