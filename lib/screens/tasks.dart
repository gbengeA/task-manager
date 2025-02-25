import 'dart:convert';
import 'dart:io';

import 'package:art_sweetalert/art_sweetalert.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:task_management/screens/task.dart';
import 'package:task_management/util/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';
import '../model/Task.dart';

class TasksScreen extends StatefulWidget {


  const TasksScreen(   {super.key});


  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final Box<Task> taskBox = Hive.box<Task>('tasks');

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();


  bool _notificationsEnabled = false;
  bool _resolved = false;

  @override
  void initState() {
    _isAndroidPermissionGranted();
    _requestPermissions();
    _initNotificationSubscription();
      FirebaseMessaging.instance.getInitialMessage().then(
            (value) =>
            setState(
                  () {
                _resolved = true;
                var initialMessage = value?.data;
                if (initialMessage != null) {
                 _loadData(initialMessage);
                }
              },
            ),
      );


    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("On message should show notification");
      showFlutterNotification(message, false);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
        _loadData(message.data);
    });

    //request permission
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    super.initState();
  }


  Future<void> _isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      final bool granted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled() ??
          false;
      setState(() {
        _notificationsEnabled = granted;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
      await androidImplementation?.requestNotificationsPermission();
      setState(() {
        _notificationsEnabled = grantedNotificationPermission ?? false;
      });
    }
  }


  Future<void> _saveTask(int? index) async {
    if (nameController.text.isEmpty) {
      ArtSweetAlert.show(
          context: context,
          artDialogArgs: ArtDialogArgs(
            type: ArtSweetAlertType.danger,
            title: "Oops...",
            text: "Name is required",
          )
      );
      return;
    }

    if (index == null) {
      final task = Task(
        id: taskBox.length + 1,
        name: nameController.text,
        description: descriptionController.text,
      );
      taskBox.add(task);
      NotificationService().sendNoti(task: task,isNewTask: true);
    } else {
      final task = Task(
        id: index.toInt(),
        name: nameController.text,
        description: descriptionController.text,
      );
      taskBox.putAt(index, task);
      NotificationService().sendNoti(task: task,isNewTask: false);
    }


    //center the textfield
    nameController.clear();
    descriptionController.clear();
    //close the bottom sheet
    Navigator.pop(context);
    await ArtSweetAlert.show(
        context: context,
        artDialogArgs: ArtDialogArgs(
          type: ArtSweetAlertType.success,
          title: "${index == null ? "Save" : "Updated"} successfully",
          text: "Task has been ${index == null
              ? "saved"
              : "updated"}, reminder has been set",
        )
    );
    if (!_notificationsEnabled) {
      ArtSweetAlert.show(
          context: context,
          artDialogArgs: ArtDialogArgs(
            type: ArtSweetAlertType.info,
            title: "Notification",
            text: "Notification is disabled, enable it to get reminder",
          )
      );
    }
  }

  Future<void> _deleteTask(int index) async {
    ArtDialogResponse response = await ArtSweetAlert.show(
        barrierDismissible: false,
        context: context,
        artDialogArgs: ArtDialogArgs(
            denyButtonText: "Cancel",
            title: "Are you sure?",
            text: "You won't be able to revert this!",
            confirmButtonText: "Yes, delete it",
            type: ArtSweetAlertType.warning
        )
    );

    if (response.isTapConfirmButton) { //delete
      taskBox.deleteAt(index);
      ArtSweetAlert.show(
          context: context,
          artDialogArgs: ArtDialogArgs(
              type: ArtSweetAlertType.success,
              title: "Deleted!"
          )
      );
      return;
    }
  }

  void _editTask(int index) {
    final task = taskBox.getAt(index);
    nameController.text = task!.name;
    descriptionController.text = task.description;
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) =>
          Padding(
            padding: EdgeInsets.only(bottom: MediaQuery
                .of(context)
                .viewInsets
                .bottom),
            child: addTaskContainer(index),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Task Manager'),
        backgroundColor: Theme
            .of(context)
            .primaryColor,),
      body: ValueListenableBuilder(
        valueListenable: taskBox.listenable(),
        builder: (context, Box<Task> box, _) {
          if (box.isEmpty) {
            return Center(child: Text('No tasks available'));
          }
          return ListView.builder(
            padding: EdgeInsets.all(8), // Adds spacing around the list
            itemCount: box.length,
            itemBuilder: (context, index) {
              final task = box.getAt(index);
              return Card(
                  elevation: 2, // Adds a subtle shadow
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  child: ListTile(
                    onTap: () {
                      _showTaskDetail(task);
                    },
                    leading: CircleAvatar(
                      child: Text(task!.name.substring(0, 1).toUpperCase()),
                    ),
                    contentPadding: EdgeInsets.all(8),
                    title: Text(
                      task.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      task.description,
                      style: TextStyle(color: Colors.grey[600]),
                    ),

                    trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editTask(index);
                          } else if (value == 'delete') {
                            _deleteTask(index);
                          }
                        },
                        itemBuilder: (context) =>
                        [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue),
                                SizedBox(width: 8),
                                Text("Edit"),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text("Delete"),
                              ],
                            ),)
                        ]),

                  )
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {

          showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: addTaskContainer(null),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  SingleChildScrollView addTaskContainer(int? index) {
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${index == null ? "Add" : "Edit"} Task",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
            SizedBox(height: 16,),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              minLines: 3,
              maxLines: 5,
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () {
                  Navigator.pop(context);
                }, child: Text('Cancel', style: TextStyle(color: Colors.red),)),
                ElevatedButton(
                  onPressed: () {
                    _saveTask(index);
                  },
                  child: Text('${index == null ? "Add" : "Update"} Task',
                    style: TextStyle(color: Colors.green),),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }


  void _showTaskDetail(Task task) {
     Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskScreen(task: task),
      ));
  }

  void _loadData( Map<String, dynamic> messageData
      ) {
    //print("payload $payload");
    try {
     // Map<String, dynamic> messageData = jsonDecode(payload ?? "");
      Task task = Task.fromJson(jsonDecode(messageData['task']));
      _showTaskDetail(task);
    } catch (e) {
      print(" showing dailog  $e");
    }
  }

  Future<void> _initNotificationSubscription() async {
    var box = Hive.box('settingsBox');
    bool isSubscribed = box.get('isSubscribed', defaultValue: false);

    if (!isSubscribed) {
      NotificationService().subscribeToTopic();
      box.put('isSubscribed', true); // Store subscription status
    }
  }


}