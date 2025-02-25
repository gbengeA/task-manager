import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_management/screens/task.dart';
import 'package:task_management/screens/tasks.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'firebase_options.dart';
import 'model/Task.dart';



/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;

/// Create a [AndroidNotificationChannel] for heads up notifications
bool   isFlutterLocalNotificationsInitialized = false;

Future<void> showFlutterNotification(RemoteMessage message, bool  isBackground) async {
  print("Showing from @${isBackground?"Background":" foreground"}");

  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null && !kIsWeb) {
    //String senderId= message.data['senderId']??"";
    //block if notification is coming from self.
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      flutterLocalNotificationsPlugin.show(
        notification.android.hashCode,
        "${notification.title}",
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: 'launch_background',
            importance: Importance.max,
            // High importance to make sure it's heads-up
            priority: Priority
                .high, // Set to high priority for heads-up notifications
          ),
        ),
        payload: jsonEncode(message.data), // Pass data as payload

      );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {

  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  await setupFlutterNotifications();
}


/// The backgroundHandler needs to be either a static function or a top
void backgroundNotificationHandler(NotificationResponse notificationResponse) {//
  print("onDidReceiveBackgroundNotificationResponse ${notificationResponse.actionId}, ${notificationResponse.payload}");
  if (notificationResponse.payload != null) {
    loadDataNext(notificationResponse.payload);
    print(' Handling a  notificationResponse.payload');
  }else {
    print('NULL Handling notificationResponse.payload');
  }
}

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    print("Already init ");
    return;
  }else{
    print("Init var again ");
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
    'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  /// Create an Android Notification Channel.
  ///
  /// We use this channel in the `AndroidManifest.xml` file to override the
  /// default FCM channel to enable heads up notifications.
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );


  // flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
  //     ?.createNotificationChannel(channel);


  isFlutterLocalNotificationsInitialized = true;
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings("launch_background");
  //final LinuxInitializationSettings initializationSettingsLinux =
  // LinuxInitializationSettings(
  //   defaultActionName: 'Open notification',
  //   defaultIcon: AssetsLinuxIcon('icons/app_icon.png'),
  // );
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    //iOS: initializationSettingsDarwin,
    // macOS: initializationSettingsDarwin,
    // linux: initializationSettingsLinux,
  );

  await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        print("onDidReceiveNotificationResponse ${notificationResponse.actionId}, ${notificationResponse.payload}");
        loadDataNext(notificationResponse.payload);
      },
      onDidReceiveBackgroundNotificationResponse:backgroundNotificationHandler );

}




final navigatorKey = GlobalKey<NavigatorState>();
/// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
   Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>('tasks');
  var box = await Hive.openBox('settingsBox');

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        name: "task_management",
        options: DefaultFirebaseOptions.currentPlatform);
  }


  //await  PushNotification.initNotification();

  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  if (!kIsWeb) {
    await setupFlutterNotifications();
  }

  runApp(MyApp());

}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const TasksScreen(),
    );
  }
}




void  loadDataNext(String? payload) { //String? payload
  try{
    print("Navigating to Task page");
    Map<String, dynamic> messageData = jsonDecode(payload??"");
    Task task =  Task.fromJson(jsonDecode(messageData['task']));
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) =>TaskScreen(task: task)),
    );
  }catch(e ){
    print("Error navigating to page  $e");

  }
}
