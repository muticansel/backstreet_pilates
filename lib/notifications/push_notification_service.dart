import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/account/data/account_role_resolver.dart';
import '../features/account/data/supabase_account_role_resolver.dart';
import '../features/admin/pages/admin_users_page.dart';
import '../features/admin/pages/cash_purchase_requests_page.dart';
import '../features/purchases/data/supabase_purchase_gateway.dart';
import '../theme/app_snack_bars.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();

  SupabaseClient? _client;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenSubscription;

  Future<void> initialize(SupabaseClient client) async {
    if (_client != null) return;
    _client = client;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _messageOpenSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);
    _tokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) => _upsertToken(token),
    );
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _openFromMessage(initialMessage);
  }

  /// Call only after the user reaches an authenticated home screen. The system
  /// prompt is contextual and never appears on login/signup.
  Future<void> activateForSignedInUser() async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) return;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null) return;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _upsertToken(token);
  }

  Future<void> unregisterCurrentDevice() async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await client.from('user_push_devices').delete().eq('token', token);
  }

  Future<void> _upsertToken(String token) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;
    try {
      await client.from('user_push_devices').upsert({
        'user_id': user.id,
        'token': token,
        'platform':
            defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'push_enabled': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');
    } catch (_) {
      // Notification registration should not block an authenticated session.
    }
  }

  Future<void> _openFromMessage(RemoteMessage message) async {
    final action = message.data['action'];
    if (action != 'cash_request' && action != 'registration_pending') return;
    final client = _client;
    if (client == null) return;
    final role = await SupabaseAccountRoleResolver(client).currentRole();
    if (role != AccountRole.admin) return;
    final context = AppNotifications.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => action == 'cash_request'
            ? CashPurchaseRequestsPage(
                purchases: SupabasePurchaseGateway(client))
            : const AdminUsersPage(),
      ),
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _messageOpenSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _messageOpenSubscription = null;
    _client = null;
  }
}
