import 'dart:typed_data';

/// Base class for all messages
///
/// All masseges must have static const int of `typeId`, and factories of decode
/// binary datas and json data.
///
/// All json datas must have `'id'` and `'type'` props. All binary data must
/// start with first unsigned value of `typeId`, and second value must be [id]
///
/// For user defined messages `typeId` must be greater than `256`
abstract class IMsg {
  /// This Interface
  const IMsg._();

  /// unique id of message.
  int get id;

  /// Binary represent of that msg
  Uint8List get toBytes;

  JsonMap get toJson;
}

typedef JsonMap = Map<String, Object?>;
