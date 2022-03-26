import 'dart:convert';
import 'dart:typed_data';

import 'package:atmos_binary_buffer/atmos_binary_buffer.dart';
import 'package:meta/meta.dart';

import '../interfaces/i_msg.dart';
import '../interfaces/i_msg_connection.dart';

/// Handshake Msg which send firstly from client and server wait only this
/// message when connection was created.
///
/// [key] can contain some data. Like 'login', 'password' and 'magic data' for
/// authentication of server. Or u can set this empty.
@immutable
class MsgHandshake implements IMsg {
  const MsgHandshake(this.id, this.version, {this.key});

  factory MsgHandshake.binDecode(BinaryReader reader) {
    final id = reader.readSize();
    final version = reader.readSize();
    final key = reader.readListUint8();
    return MsgHandshake(id, version, key: key);
  }

  factory MsgHandshake.jsonDecode(JsonMap json) {
    final id = json['id'] as int;
    final version = json['version'] as int;
    final keyR = json['key'] as String?;
    final key = keyR == null ? null : base64.decode(keyR);
    return MsgHandshake(
      id,
      version,
      key: key,
    );
  }

  static const typeId = 1;

  @override
  final int id;
  final int version;
  final Uint8List? key;

  @override
  Uint8List get toBytes => (BinaryWriter()
        ..writeSize(typeId)
        ..writeSize(id)
        ..writeSize(version)
        ..writeListUint8(key ?? const []))
      .takeBytes();

  @override
  JsonMap get toJson => {
        'type': typeId,
        'id': id,
        'version': version,
        if (key != null) 'key': base64.encode(key!),
      };

  @override
  String toString() => '''MsgHandshake(id=$id, version=$version, key=$key)''';
}
