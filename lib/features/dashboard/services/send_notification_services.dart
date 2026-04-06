import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../notification/serverKey.dart';

class SendNotificationServices {
  static Future<void> sendUserChangeStatusNotification({
    required String? token,
    required String? title,
    required String? body,
    required Map<String, dynamic>? data,
  }) async {
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    if (projectId == null || projectId.isEmpty) {
      throw StateError('Missing required .env value: FIREBASE_PROJECT_ID');
    }

    String serverKey = await ServerKey().getServerKey();
    print("notification server key => ${serverKey}");
    String url =
        "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";

    var headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $serverKey',
    };

    //mesaage
    Map<String, dynamic> message = {
      "message": {
        "token": token,

        // 🔥 ANDROID CONFIG (CRITICAL FOR POPUP)
        "android": {
          "priority": "HIGH",
          "notification": {
            "channel_id": "high_importance_channel",
            "sound": "default",
            "visibility": "PUBLIC",
            "default_sound": true,
            "default_vibrate_timings": true,
            "notification_priority": "PRIORITY_MAX",
          },
        },

        // 🔔 SYSTEM NOTIFICATION
        "notification": {"title": title, "body": body},

        // 📦 CUSTOM DATA (FOR APP LOGIC)
        "data": data ?? {},
      },
    };

    //hit api
    final http.Response response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print("Notification Send Successfully!");
    } else {
      print("Notification not send!");
    }
  }
}
