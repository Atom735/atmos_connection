import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import '../messages/msg_done.dart';
import '../messages/msg_handshake.dart';
import 'i_msg.dart';

/// Interface of msg connection
abstract class IMsgConnection implements VirtualChannel<IMsg> {
  /// This Interface
  const IMsgConnection._();

  /// Version of this type of connection, thats can use for set server/client
  /// side for copability mode.
  int get version;

  /// Generate new id for msg, odds for server side, and evens for client side
  int get newMsgId;

  ConnectionTransferType get transferType;
  set transferType(ConnectionTransferType value);

  /// Send msg to other side like notification...
  ///
  /// Thats used for all sends messages...
  void send(IMsg msg);

  /// Send msg, and return [Future] which completed with recived msg with
  /// same [IMsg.id] of sended. (Request - Response)
  ///
  /// Can used for create chain of msgs. For example:
  /// 1. (C)lient send `Msg1`, and wait response. (called [request])
  /// 2. (S)erver recived `Msg1`, and then they send `Msg2` with same [IMsg.id]
  /// and wait response for thats. (called [request])
  /// 3. (C) recive `Msg2` and send `Msg3` with same [IMsg.id]. (called [send])
  /// 4. (S) recived `Msg3` and chain ended.
  Future<IMsg> request(IMsg msg);

  /// Send msg, and return [Stream] of recived msgs with same [IMsg.id].
  ///
  /// Like request, but auto closed when recived [MsgDone].
  Stream<IMsg> openStream(IMsg msg);

  /// Close this connection and dispose all resources.
  @mustCallSuper
  void dispose();

  /// Handle all inputs messages
  @mustCallSuper
  void handleMsg(IMsg msg);

  @override
  IMsgConnection virtualChannel([int? id]);
}

/// Interface of msg connection
abstract class IMsgConnectionClient implements IMsgConnection {
  /// This Interface
  const IMsgConnectionClient._();

  /// Adress of connection, can be like `ws://127.0.0.1:8080` or `http://example.com`
  String get adress;

  /// Status of this connection
  ConnectionStatus get statusCode;

  /// Status error msg, not empty when [statusCode] == [ConnectionStatus.error]
  String get statusErrorMsg;

  /// Stream of updates state/status of that connection
  Stream<IMsgConnectionClient> get statusUpdates;

  /// Try to start connecting
  ///
  /// Works only on client side.
  /// Return [Future] of ends process of connection,
  /// before sets [statusCode] == [ConnectionStatus.connected].
  ///
  /// If [statusCode] == [ConnectionStatus.connecting] they return privius
  /// future of thats call. So thats u can call it many times, but in really
  /// thats process was start only once, while connection not loosed.
  /// If connection is establish, they return [Future.sync]
  @mustCallSuper
  Future<MsgHandshake> reconnect(String adress, [Uint8List? key]);

  @override
  IMsgConnectionClient virtualChannel([int? id]);
}

enum ConnectionTransferType {
  json,
  bin,
}

enum ConnectionStatus {
  /// Connection unconnected
  unconnected,

  /// Connection in process of connection and handshake
  connecting,

  /// Establish connection
  connected,

  /// Erorred of connection, other data in [IMsgConnection.statusErrorMsg]
  error,
}

/// Throws to [IMsgConnection.request] or [IMsgConnection.openStream]
/// when connection clossed, before recive last msg
class ConnectionClossedException implements Exception {
  const ConnectionClossedException();
  @override
  String toString() => 'ConnectionClossedException';
}
