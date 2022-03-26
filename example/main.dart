import 'dart:async';
import 'dart:io';

import 'package:atmos_connection/src/connections/msg_connection_client_ws.dart';
import 'package:atmos_connection/src/connections/msg_connection_server_ws.dart';
import 'package:atmos_connection/src/msg_decoder.dart';
import 'package:web_socket_channel/io.dart';

class Server {
  Server(this.port) {
    init();
  }

  final int port;
  late HttpServer server;
  final connections = <MsgConnectionServerWebSocket>[];

  Future<void> handleWebSocket(WebSocket ws) async {
    final connection = MsgConnectionServerWebSocket(
        IOWebSocketChannel(ws), const MsgDecoder());
    connection.stream.listen(connection.handleMsg);
    connections.add(connection);
  }

  Future<void> handleHttpRequest(HttpRequest request) async {}

  Future<void> init() async {
    server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    await for (final request in server) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        unawaited(WebSocketTransformer.upgrade(request).then(handleWebSocket));
      }
      unawaited(handleHttpRequest(request));
    }
  }
}

Future<void> main(List<String> args) async {
  Server(8080);

  final client = MsgConnectionClientWebSocket(const MsgDecoder());
  final hs = await client.reconnect('ws://127.0.0.1:8080');
}
