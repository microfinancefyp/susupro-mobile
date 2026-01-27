import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:susu_micro/main.dart';
import 'package:susu_micro/providers/next_account_number.dart';
import 'package:susu_micro/providers/staff_provider.dart';
import 'package:susu_micro/utils/helpers.dart';
import 'package:susu_micro/views/chat_screen.dart';
import 'package:susu_micro/views/customers_page.dart';
import 'package:susu_micro/views/home_page.dart';
import 'package:susu_micro/views/welcome_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {

void setupNotificationHandlers() {
 FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Foreground message: ${message.data}");

    // Extract notification payload (if exists)
    RemoteNotification? notification = message.notification;

    flutterLocalNotificationsPlugin.show(
      notification?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      notification?.title ?? message.data['title'] ?? 'New Message',
      notification?.body ?? message.data['body'] ?? 'You have a new notification',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'General Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: message.data.toString(),
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    logs.d('📲 App opened from notification: ${message.data}');
     final staff = Provider.of<StaffProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen(companyId: staff.companyId ?? '', currentUserId: staff.id ?? '',)),
    );
  });
}

  
  @override
  Widget build(BuildContext context) {
    final nextAccountNumberProvider = Provider.of<AccountNumberProvider>(context);
    if (!nextAccountNumberProvider.loading && nextAccountNumberProvider.nextAccountNumber == null) {
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      if (staffProvider.id != null) {
        nextAccountNumberProvider.refreshAccountNumber(staffProvider.id!);
      }
    }
    return Consumer<StaffProvider>(
      builder: (context, staffProvider, _) {
        if (staffProvider.isCheckingAuth) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (staffProvider.isLoggedIn) {
          return const HomePage();
        }

        return const WelcomePage();
      },
    );
  }
}
