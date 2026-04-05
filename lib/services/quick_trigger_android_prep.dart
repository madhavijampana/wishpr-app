// Android (and other platforms) can fire Quick Trigger from native code by sending
// any message on the BasicMessageChannel named in [QuickTriggerNativeChannel.name]
// (see quick_trigger_native_channel.dart). The Dart side is registered in
// [WishprSafetyHost] and calls [QuickTriggerCoordinator.fire].
//
// Example (Kotlin, once you hold a FlutterEngine / BinaryMessenger):
//   BasicMessageChannel(
//     flutterEngine.dartExecutor.binaryMessenger,
//     "com.example.wishpr_app/quick_trigger",
//     StandardMessageCodec.INSTANCE,
//   ).send("fire") { }
