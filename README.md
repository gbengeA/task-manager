# task_management

Task Management App with notification 

A simple Flutter application that demonstrates the following functionalities:

1. Task Management: Allow users to create, edit, and delete tasks.
2. Push Notifications: Send a reminder notification 5 minutes after a task is created.
3. Local Data Storage: Save tasks locally using   Hive.






## Getting Started
Install located in screenshots and test the app on your device or emulator.
Ensure you internet connection is on to receive notifications
you test with two device to see the notification in action
User task are saved locally and can only be view once by others devices.


## The following instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

Running the code.

cmd  `dart  run build_runner build` to generate HIVE the files // optional
cmd  `flutter run` to run the app

### Configure Firebase Project
Configure firebase project using on screen instructions from firbase console during project creation 
add
under this  https://console.firebase.google.com/u/1/project/task-manager-6e79e/settings/serviceaccounts/adminsdk
replace this "task-manager-6e79e" with your firebase project id task-manager-6e79e and generate a new private key and download it and rename it to k.json
'assets/k.json` to the root of the project

add google-services.json file from your firebase project to the android/app folder
'android/google-services.json` to the root of the project

# Note
Sending notification require server side code to send the notification to the device which done on the App but should avoided


