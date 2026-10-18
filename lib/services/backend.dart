import 'package:flutter/foundation.dart';

/// Stub. Replace with your real API (Firebase, Supabase, your own server).
/// The police console would read from the same store.
class Backend {
  static Future<void> sendAlert({
    required int alertId,
    required String zone,
    required String reason,
    required bool viaRelay,
  }) async {
    debugPrint('[Backend] alert $alertId zone=$zone reason="$reason" relay=$viaRelay');
    // TODO: POST to your server. It should: notify trusted contacts (SMS/push),
    // and show the alert on the police console.
  }
}
