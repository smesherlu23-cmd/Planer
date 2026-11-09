import 'package:flutter/material.dart';

import 'app.dart';
import 'data/database.dart';
import 'services/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  final notifications = NotificationService(db);
  // Напоминания не должны мешать запуску, даже если что-то пошло не так.
  notifications.init().catchError((Object e) => debugPrint('Напоминания: $e'));
  runApp(PlanerApp(db: db, notifications: notifications));
}
