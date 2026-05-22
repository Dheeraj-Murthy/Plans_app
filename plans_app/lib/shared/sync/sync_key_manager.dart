import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class SyncKeyManager {
  static const _salt = 'plans-app-sync-v1:SHA256:20260522';

  /// Derives a deterministic AES-256 key from the user's Google account ID.
  /// Every device with the same Google account gets the same key.
  static Uint8List deriveKey(String googleUserId) {
    final input = utf8.encode('$_salt$googleUserId');
    return Uint8List.fromList(sha256.convert(input).bytes);
  }
}
