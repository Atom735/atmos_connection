import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:atmos_logger/atmos_logger.dart';
import 'package:stream_channel/stream_channel.dart';

import '../interfaces/i_msg.dart';
import '../interfaces/i_msg_connection.dart';
import '../messages/msg_done.dart';
import '../messages/msg_error.dart';
import '../msg_decoder.dart';

abstract class MsgConnectionBase extends StreamChannelMixin<IMsg>
    implements IMsgConnection {
  MsgConnectionBase(this._msgId);

  int _msgId;

  MsgDecoder get decoder;

  @override
  int get mewMsgId => _msgId += 2;

  final requestsCompleters = <int, Completer<IMsg>>{};
  @override
  Future<IMsg> request(IMsg msg) {
    final completer = Completer<IMsg>.sync();
    requestsCompleters[msg.id] = completer;
    send(msg);
    return completer.future;
  }

  final streamControllers = <int, StreamController<IMsg>>{};
  @override
  Stream<IMsg> openStream(IMsg msg) {
    // ignore: close_sinks
    final controller = StreamController<IMsg>(sync: true);
    streamControllers[msg.id] = controller;
    send(msg);
    return controller.stream;
  }

  @override
  void dispose() {
    for (final controller in streamControllers.values) {
      controller
        ..addError(const ConnectionClossedException())
        ..close();
    }
    streamControllers.clear();
    for (final completer in requestsCompleters.values) {
      completer.completeError(const ConnectionClossedException());
    }
    requestsCompleters.clear();
  }

  @override
  void handleMsg(IMsg msg) {
    if (msg is MsgError) {
      requestsCompleters.remove(msg.id)?.completeError(msg);
      streamControllers.remove(msg.id)
        ?..addError(msg)
        ..close();
    } else if (msg is MsgDone) {
      requestsCompleters.remove(msg.id)?.complete(msg);
      streamControllers.remove(msg.id)?.close();
    }
  }
}

class MsgStreamChanngelDebugTransformer<T> {
  const MsgStreamChanngelDebugTransformer(
    this.name,
    this.logger,
  );

  final String name;
  final Logger logger;

  StreamSubscription<T> onListenStream(Stream<T> stream, bool cancelOnError) {
    final controller = StreamController<T>(sync: true);
    controller.onListen = () {
      final subscription = stream.listen(
        (data) {
          logger.debug('RECV', data.toString(), name);
          controller.add(data);
        },
        onError: (error, [stackTrace]) {
          logger.error('RECV ERROR', '', name);
          controller.addError(error, stackTrace);
        },
        onDone: () {
          logger.info('RECV DONE', '', name);
          controller.close();
        },
        cancelOnError: cancelOnError,
      );
      // Controller forwards pause, resume and cancel events.
      controller
        ..onPause = subscription.pause
        ..onResume = subscription.resume
        ..onCancel = subscription.cancel;
    };
    // Return a new [StreamSubscription] by listening to the controller's
    // stream.
    return controller.stream.listen(null);
  }

  StreamSubscription<T> onListenSink(Stream<T> stream, bool cancelOnError) {
    final controller = StreamController<T>(sync: true);
    controller.onListen = () {
      final subscription = stream.listen(
        (data) {
          logger.debug('SEND', data.toString(), name);
          controller.add(data);
        },
        onError: (error, [stackTrace]) {
          logger.error('SEND ERROR', '', name);
          controller.addError(error, stackTrace);
        },
        onDone: () {
          logger.info('SEND DONE', '', name);
          controller.close();
        },
        cancelOnError: cancelOnError,
      );
      // Controller forwards pause, resume and cancel events.
      controller
        ..onPause = subscription.pause
        ..onResume = subscription.resume
        ..onCancel = subscription.cancel;
    };
    // Return a new [StreamSubscription] by listening to the controller's
    // stream.
    return controller.stream.listen(null);
  }

  StreamChannelTransformer<T, T> get transformer =>
      StreamChannelTransformer<T, T>(
          StreamTransformer(onListenStream),
          StreamSinkTransformer.fromStreamTransformer(
              StreamTransformer(onListenSink)));
}

class MsgStreamChanngelTransformer {
  const MsgStreamChanngelTransformer(this.decoder);

  final MsgDecoder decoder;

  StreamChannelTransformer<IMsg, Object?> get transformerJson =>
      StreamChannelTransformer<IMsg, Object?>(
        decoder,
        const StreamSinkTransformer.fromStreamTransformer(_MsgJsonEncoder()),
      );
  StreamChannelTransformer<IMsg, Object?> get transformerBin =>
      StreamChannelTransformer<IMsg, Object?>(
        decoder,
        const StreamSinkTransformer.fromStreamTransformer(_MsgBinEncoder()),
      );
}

class _MsgBinEncoder extends Converter<IMsg, Object?> {
  const _MsgBinEncoder();
  @override
  Object? convert(IMsg input) => input.toBytes;
}

Object? _toEncodable(Object? msg) => (msg as IMsg).toJson;

class _MsgJsonEncoder extends Converter<IMsg, Object?> {
  const _MsgJsonEncoder();
  @override
  Object? convert(IMsg input) =>
      const JsonEncoder.withIndent('  ', _toEncodable).convert(input.toJson);

  @override
  Sink<IMsg> startChunkedConversion(Sink<Object?> sink) => _SinkJson(sink);
}

class _SinkJson implements Sink<IMsg> {
  const _SinkJson(this.sink);

  final Sink<Object?> sink;

  @override
  void add(IMsg data) =>
      sink.add(const JsonEncoder.withIndent('  ', _toEncodable).convert(data));

  @override
  void close() => sink.close();
}
