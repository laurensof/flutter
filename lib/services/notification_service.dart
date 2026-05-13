import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/registro_model.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const String _stockChannelId = 'stock_alerts';
  static const String _stockChannelName = 'Alertas de stock';
  static const String _stockChannelDescription =
      'Avisos cuando un producto tiene 5 unidades o menos.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _lastStockSignature;
  DateTime? _lastStockNotificationAt;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);
    await _createAndroidChannels();
    await _requestAndroidPermission();
    _initialized = true;
  }

  Future<void> showStockAlerts(
    List<ProductoRegistroModel> productos,
  ) async {
    if (productos.isEmpty) {
      return;
    }

    await initialize();
    if (!await _canShowNotifications()) {
      return;
    }

    final signature = productos
        .map((producto) => '${producto.idProducto}:${producto.stock}')
        .join('|');
    final now = DateTime.now();
    final recentlyShown = _lastStockNotificationAt != null &&
        now.difference(_lastStockNotificationAt!) <
            const Duration(minutes: 30);

    if (_lastStockSignature == signature && recentlyShown) {
      return;
    }

    _lastStockSignature = signature;
    _lastStockNotificationAt = now;

    final count = productos.length;
    final critical = productos.where((producto) => producto.stock <= 2).length;
    final first = productos.first;
    final body = count == 1
        ? '${first.nombre} tiene ${first.stock} unidades disponibles.'
        : '$count productos tienen stock bajo. $critical estan criticos.';

    const androidDetails = AndroidNotificationDetails(
      _stockChannelId,
      _stockChannelName,
      channelDescription: _stockChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      ticker: 'Stock bajo',
      enableVibration: true,
      playSound: true,
    );

    await _plugin.show(
      1001,
      'Stock bajo en Tech-Metrics',
      body,
      const NotificationDetails(android: androidDetails),
      payload: 'stock_alerts',
    );
  }

  Future<void> showPushNotification({
    required String title,
    required String body,
  }) async {
    await initialize();
    if (!await _canShowNotifications()) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _stockChannelId,
      _stockChannelName,
      channelDescription: _stockChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      ticker: 'Tech-Metrics',
      enableVibration: true,
      playSound: true,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: 'push_alert',
    );
  }

  Future<void> _requestAndroidPermission() async {
    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> _createAndroidChannels() async {
    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        _stockChannelId,
        _stockChannelName,
        description: _stockChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  Future<bool> _canShowNotifications() async {
    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await androidImplementation?.areNotificationsEnabled() ?? true;
  }
}
