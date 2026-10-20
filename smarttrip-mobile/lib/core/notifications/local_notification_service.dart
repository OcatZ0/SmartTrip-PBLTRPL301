import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// On-device notifications only (design spec Section 2: no Firebase/FCM, no
/// backend endpoint). Used for the arrival notification of F012 and the
/// weather check reminder of F025.
class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _arrivalChannelId = 'trip_arrival';
  static const _weatherChannelId = 'trip_weather';

  /// Arrival notifications use itinerary item ids; trip reminders live far
  /// above them, 100 per trip (slot 0 is the weather reminder).
  static const _tripIdBase = 1000000000;

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialization;

  Future<void> _ensureInitialized() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    // Batam is on WIB; the reminder time is meant in the trip's local time.
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  /// Reminds the user at 09.00 seven days before [startDate] to check the
  /// forecast. Scheduling again for the same trip replaces the reminder; a
  /// time already past schedules nothing, the forecast is on screen by then.
  Future<void> scheduleWeatherReminder({
    required int tripsId,
    required DateTime startDate,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    await _ensureInitialized();
    final id = _tripIdBase + tripsId * 100;
    await _plugin.cancel(id);

    final day = startDate.subtract(const Duration(days: 7));
    final at = tz.TZDateTime(tz.local, day.year, day.month, day.day, 9);
    if (!at.isAfter(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      at,
      NotificationDetails(
        android: AndroidNotificationDetails(_weatherChannelId, channelName, channelDescription: channelDescription),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Android 13+ and iOS ask the user once; later calls return the answer.
  Future<bool> requestPermission() async {
    await _ensureInitialized();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  Future<void> showArrival({
    required int id,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    await _ensureInitialized();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _arrivalChannelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});
