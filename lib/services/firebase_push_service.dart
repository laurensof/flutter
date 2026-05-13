import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/user_model.dart';
import 'api_service.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  await NotificationService.instance.initialize();
}

class FirebasePushService {
  FirebasePushService._();

  static final FirebasePushService instance = FirebasePushService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;
  String? _lastRegisteredToken;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    if (Firebase.apps.isEmpty) {
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      final title = notification?.title ?? 'Tech-Metrics';
      final body = notification?.body ?? 'Tienes una nueva alerta.';
      NotificationService.instance.showPushNotification(
        title: title,
        body: body,
      );
    });

    _messaging.onTokenRefresh.listen((token) {
      _registerToken(token);
    });

    _initialized = true;
  }

  Future<void> syncUserToken(UserModel? user) async {
    await initialize();
    if (Firebase.apps.isEmpty) {
      return;
    }
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }
    await _registerToken(token, user: user);
  }

  Future<void> _registerToken(String token, {UserModel? user}) async {
    if (_lastRegisteredToken == token) {
      return;
    }

    final response = await ApiService().registrarTokenNotificacion(
      token: token,
      idUsuario: user?.idUsuario,
      username: user?.usuario,
    );

    if (response.success) {
      _lastRegisteredToken = token;
    }
  }
}
