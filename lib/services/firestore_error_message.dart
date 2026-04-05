import 'package:firebase_core/firebase_core.dart';

String firestoreErrorMessage(Object? error) {
  if (error is FirebaseException) {
    final msg = error.message;
    if (msg != null && msg.isNotEmpty) return msg;
    return 'Request failed (${error.code}).';
  }
  return error?.toString() ?? 'Unknown error';
}
