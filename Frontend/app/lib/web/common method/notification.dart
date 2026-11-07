import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../../constant/Server_Database.dart';
import '../../constant/variable.dart';
import '../../models/NewNotificationsModel.dart';
import '../../models/NotificationsInfoModel.dart';
import 'Commmon_Method.dart';

List<NotificationsInfoModel> NotificationsInfoList = [];

Future<int> GetNotificationsInfo({required String Email,required String Current_User_JwtToken,required BuildContext context }) async {
  try {
    final Map<String, dynamic> userData = {"Email": Email};
    const String url = Backend_Server_Url + "api/Booking/sendnotification";
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer ${Current_User_JwtToken}',
      },
      body: json.encode(userData),
    );
    if (response.statusCode == 200) {
      List<dynamic> responseData = await jsonDecode(response.body);
      NotificationsInfoList.clear();
      NotificationsInfoList.addAll(responseData
          .map((data) => NotificationsInfoModel.fromJson(data))
          .toList());
      return 1;
    } else if (response.statusCode == 502) {
      NotificationsInfoList.clear();
      await Logout(context: context);
      Toast.Toastmsg("Your register email don't match..");
      return 3;
    } else if (response.statusCode == 500) {
      NotificationsInfoList.clear();

      return 4;
    }
    else if (response.statusCode == 501) {
      NotificationsInfoList.clear();

      return 4;
    }
    else {
      NotificationsInfoList.clear();

      return 2;
    }
  } catch (Obj) {
    NotificationsInfoList.clear();

    print(Obj.toString());
    return 0;
  }
}



List<NewNotificationsModel> NewNotificationsList = [];

Future<int> GetNewNotificationInfo({required String Email,required String Current_User_JwtToken,required BuildContext context}) async {
  try {
    final Map<String, dynamic> userData = {"Email": Email};
    const String url = Backend_Server_Url + "api/Booking/sendnewnotification";
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer ${Current_User_JwtToken}',
      },
      body: json.encode(userData),
    );
    if (response.statusCode == 200) {
      final String body = response.body.trim();
      final dynamic decoded = body.isEmpty ? [] : jsonDecode(body);

      final List<dynamic> rows = decoded is List
          ? decoded
          : (decoded is Map ? [decoded] : <dynamic>[]);

      NewNotificationsList.clear();
      NewNotificationsList.addAll(
        rows
            .whereType<Map>()
            .map((data) => NewNotificationsModel.fromJson(
            Map<String, dynamic>.from(data)))
            .toList(),
      );
      return 1;
    }else if (response.statusCode == 502) {
      NewNotificationsList.clear();
      await Logout(context: context);
      Toast.Toastmsg("Your register email don't match..");
      return 3;
    } else if (response.statusCode == 500) {
      NewNotificationsList.clear();

      return 4;
    }
    else if (response.statusCode == 501) {
      NewNotificationsList.clear();

      return 4;
    }
    else {
      NewNotificationsList.clear();

      return 2;
    }
  } catch (Obj) {
    NewNotificationsList.clear();
    print(Obj.toString());
    return 0;
  }
}



Future<int> UpdateNewNotificationInfo({required String Email,required String Current_User_JwtToken,required BuildContext context}) async
{
  try {
    final Map<String, dynamic> userData = {"Email": Email};
    const String url = Backend_Server_Url + "api/Booking/updatenewnotification";
    final response = await http.put(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer ${Current_User_JwtToken}',
      },
      body: json.encode(userData),
    );
    if (response.statusCode == 200) {

      return 1;
    } else if (response.statusCode == 502) {
      await Logout(context: context);
      Toast.Toastmsg("Your register email don't match..");
      return 3;
    } else if (response.statusCode == 500) {

      return 4;
    }
    else if (response.statusCode == 501) {

      return 4;
    }
    else {
      return 2;
    }
  } catch (Obj) {
    print(Obj.toString());
    return 0;
  }
}