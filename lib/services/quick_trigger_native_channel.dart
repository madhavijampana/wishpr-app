import 'package:flutter/services.dart';

/// Android/iOS can send a message on this channel to invoke Quick Trigger
/// (handled in [WishprSafetyHost]).
abstract final class QuickTriggerNativeChannel {
  static const String name = 'com.example.wishpr_app/quick_trigger';

  /// Payload accepted from native code (any value triggers fire).
  static const BasicMessageChannel<Object?> channel = BasicMessageChannel(
    name,
    StandardMessageCodec(),
  );
}
