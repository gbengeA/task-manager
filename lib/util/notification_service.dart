import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import '../model/Task.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String topic = "tasks";

  Future<String?> getToken() async {
    String? token = await _firebaseMessaging.getToken();
    //  print("FCM Token: $token");
    return token;
  }

  Future<void> subscribeToTopic() async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic() async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }



  void testSend() {
    Task task = Task(name: "Name", description: "My tes description", id: 8);
    sendNoti(task: task, isNewTask:true);
  }

  final String credentialsPath = 'assets/k.json';

  Future<String?> getAccessToken() async {
    try {
      // Load the JSON file from assets
      String jsonCredentials = await rootBundle.loadString(credentialsPath);
      var accountCredentials =
      ServiceAccountCredentials.fromJson(json.decode(jsonCredentials));
      var scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      var client = await clientViaServiceAccount(accountCredentials, scopes);
      return client.credentials.accessToken.data;
    } catch (e) {
      print('Error generating access token: $e');
      return null;
    }
  }

  Future<void> sendNoti({required Task task , required bool isNewTask}) async {
    String title = isNewTask?"Task created: ":"Task Updated: "+task.name;
    String messageContent = task.description;

    String? token = await getAccessToken();

    if (token == null) {
      print('Failed to retrieve access token');
      return;
    }

    try {
      var bodi = jsonEncode(
        <String, dynamic>{
          'message': {
            'topic': topic,
            'notification': {
              'title': title,
              'body': messageContent
            },
            'data': {
              "task": jsonEncode(task.toJson()),
            },
          },
        },
      );

      // Delay the notification by 5 minutes later and totally it is server side notification
      Future.delayed(Duration(minutes: 5), () async {
        var res = await http.post(
          Uri.parse(
              'https://fcm.googleapis.com/v1/projects/task-manager-6e79e/messages:send'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': "Bearer $token", // Use OAuth 2 token here
          },
          body: bodi,
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          print('Notification sent to topic: $topic');
        } else {
          print('Fail to sent to topic: ${res.body}');
        }
      });


    } catch (e) {
      print('Error sending notification: $e');
    }
  }


}
