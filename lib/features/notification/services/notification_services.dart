
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService{
  FirebaseMessaging message = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // notification request
  void requestNotification()async{
    NotificationSettings settings = await message.requestPermission(
      criticalAlert: true,
      carPlay: true,
      sound: true,
      provisional: true,
      badge: true,
      announcement: true,
      alert: true,
    );

    if(settings.authorizationStatus == AuthorizationStatus.authorized){
      print('User granted permission');
    }else if(settings.authorizationStatus == AuthorizationStatus.provisional){
      print('User provisional granted permission');
    }else{
      print('User denied permission');
      Future.delayed(Duration(seconds: 3),() {
        AppSettings.openAppSettings(type: AppSettingsType.notification);
      },);

    }
  }

  // Getting device token
  Future<String> getDeviceToken()async{
    NotificationSettings settings = await message.requestPermission(
      badge: true,
      alert: true,
      sound: true,
    );
    String? token = await message.getToken();
    print("token - >$token ");
    return token!;
  }

// local notification initialization
  void localNotificationInit(BuildContext context , RemoteMessage message)async{
    var androidInit = const AndroidInitializationSettings("@mipmap/ic_launcher");
    var iosInit = const DarwinInitializationSettings();

    var initializationSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (payload) {
        handleMessage(context, message);
      },
    );
  }

// firebase intialize

  void firebaseInit(BuildContext context){
    FirebaseMessaging.onMessage.listen((message){
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification!.android;

      if(kDebugMode){
        print("notification title${notification!.title}");
        print("notification body${notification.body}");
      }
      // for plateform ios
      if(Platform.isIOS){
        iosForeGroundMessage();
      }
      // for android
      if(Platform.isAndroid){
        localNotificationInit(context ,message);
        // handleMessage( context , message);
        showNotification(message);
      }
    });
  }

// show notification
  Future<void> showNotification(RemoteMessage message)async{
    // channel setting
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      message.notification!.android!.channelId.toString(),
      message.notification!.android!.channelId.toString(),
      importance: Importance.high,
      showBadge: true,
      playSound: true,
    );

    // android setting
    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: "Channel Description",
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: channel.sound
    );
    // ios setting
    DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(
      presentSound: true,
      presentBadge: true,
      presentAlert: true,
    );


    // merge notification details
    NotificationDetails notificationDetails = NotificationDetails(
      android:androidNotificationDetails ,
      iOS: darwinNotificationDetails,
    );

    // show notification
    Future.delayed(Duration.zero,
          () {
        flutterLocalNotificationsPlugin.show(
          0,
          message.notification!.title.toString(),
          message.notification!.body.toString(),
          notificationDetails,
          payload: "MyData",
        );
      },
    );


  }

// for teminated and background message
  Future<void> setInteractMessage(BuildContext context)async{

    // for background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleMessage( context , message);
    },);

    // for terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if(message != null && message.data.isNotEmpty){
        handleMessage( context , message);
      }
    },);
  }

// message handler
  Future<void> handleMessage(BuildContext context , RemoteMessage message)async{
    // Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen(),));
  }

// ios
  Future iosForeGroundMessage()async{
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      sound: true,
      badge: true,
    );
  }
}