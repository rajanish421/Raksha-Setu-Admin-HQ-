

import 'package:cloud_firestore/cloud_firestore.dart';

class GetUserDeviceToken{

  Future<String> getUserDeviceToken(String userId)async{
    final data = await FirebaseFirestore.instance.collection("user").doc(userId).get();
    final token = data['fcmToken'];

    return token!;
  }

}