// Method to handle API response and save data if status code is 200
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';
import '../../constant/Server_Database.dart';
import '../authentication/Error_page.dart';
import '../common widget/toast.dart';

// Method to handle API response and save data if status code is 200
Future<void> handleResponse(Map<String, dynamic> responseData) async {
  String token = responseData['token']!;
  String email = responseData['email']!;
  String User_Type = responseData['usertype']!;
  await Save_User_Data(Jwt_Token: token, User_Email: email, User_Role: User_Type);
  print("User data");
  print("jwt token");
  print(token);
  print("Email");
  print(email);
  print("user type");
  print(User_Type);
  return;
}

//saving user credentials in hive
Future<void> Save_User_Data({required String Jwt_Token,required String User_Email,required String User_Role }) async {
  final box = await Hive.openBox('User_Data');
  // Ensure that token is not null
  if (Jwt_Token.isNotEmptyAndNotNull && User_Email.isNotEmptyAndNotNull && User_Role.isNotEmptyAndNotNull) {
    // Save user credentials to Hive
    await box.put('jwt_token', Jwt_Token);
    await box.put('user_email', User_Email);
    await box.put('user_role', User_Role);
    print("User credentials saved in hive after login.");
  } else {
    print("Error: User data is missing.");
  }
}

// Method to clear JWT token, email, and role
Future<void> Clear_User_Data() async {
  final box = await Hive.openBox('User_Data');
  // Clear JWT token, username, and password
  await box.delete('jwt_token');
  await box.delete('user_email');
  await box.delete('user_role');
  print("User data cleared.");
}

//saving user credentials in hive
Future<int> CheckUserJwtToken() async {
  final box = await Hive.openBox('User_Data');
  String? Jwt_Token = box.get('jwt_token');
  String? User_Email = box.get('user_email');
  String? User_Role = box.get('user_role');
  // Ensure that token is not null
  if (Jwt_Token.isNotEmptyAndNotNull && User_Email.isNotEmptyAndNotNull && User_Role.isNotEmptyAndNotNull) {
    print("User data get from hive.");
    return 1;
  } else {
    print("Error: User data is missing.Check for user login.");
    return 0;
  }
}

Future<void> GenerateRandomToken()async{
  const String url = Backend_Server_Url + "api/Authentication/gettoken";
  final response = await http.get(
    Uri.parse(url),
    headers: {"Content-Type": "application/json"},
  );
  print("Random token generate status code = ${response.statusCode}");
  if (response.statusCode == 200) {
    Map<String, dynamic> responseData = jsonDecode(response.body);
    print("Generate random token success.");
    await HandleGenerateRandomToken(responseData);
  } else {
    print("Generate random token failed.");
  }
}

// Method to handle API response and save data if status code is 200
Future<void> HandleGenerateRandomToken(Map<String, dynamic> responseData) async {
  String token = responseData['token']!;
  print("random token");
  await Handle_Save_User_Data( Jwt_Token:token);
}

//saving user credentials in hive
Future<void> Handle_Save_User_Data({required String Jwt_Token}) async {
  final box = await Hive.openBox('Random_Token');
  // Ensure that token is not null
  if (Jwt_Token.isNotEmptyAndNotNull) {
    // Save user credentials to Hive
    await box.put('random_token', Jwt_Token);
    print("User random token saved in hive.");
  } else {
    print("Error: User random token is missing.");
  }
}

// Method to clear JWT token, email, and role
Future<void> Random_token_Clear() async {
  final box = await Hive.openBox('Random_Token');
  // Clear JWT token, username, and password
  await box.delete('random_token');
  print("Random token cleared.");
}



//saving user credentials in hive
Future<int> CheckRandomJwtToken() async {
  final box = await Hive.openBox('Random_Token');
  String? Jwt_Token = box.get('random_token');
  // Ensure that token is not null
  if (Jwt_Token.isNotEmptyAndNotNull) {
    print("User random token get from hive.");
    return 1;
  } else {
    print("Error: User random token is missing.");
    return 0;
  }
}


Future<int> RandomJwtVerify({required String Jwt_Token})async{
  const String url = Backend_Server_Url + "api/Authentication/jwtverify";
  // verification
  final response = await http.get(
    Uri.parse(url),
    headers: {'Authorization': 'Bearer $Jwt_Token'},
  );
  if (response.statusCode == 200) {
    return 1;
  } else {
    return 0;
  }
}


Future<int> ProviderJwtVerify({required String Jwt_Token})async{
  const String url = Backend_Server_Url + "api/Authentication/jwtverifyprovider";
  // verification
  final response = await http.get(
    Uri.parse(url),
    headers: {'Authorization': 'Bearer $Jwt_Token'},
  );
  if (response.statusCode == 200) {
    return 1;
  } else {
    return 0;
  }
}

Future<int> UserJwtVerify({required String Jwt_Token})async{
  const String url = Backend_Server_Url + "api/Authentication/jwtverify";
  // verification
  final response = await http.get(
    Uri.parse(url),
    headers: {'Authorization': 'Bearer $Jwt_Token'},
  );
  if (response.statusCode == 200) {
    return 1;
  } else {
    return 0;
  }
}


Future<int> AdminJwtVerify({required String Jwt_Token})async{
  const String url = Backend_Server_Url + "api/Authentication/jwtverify";
  // verification
  final response = await http.get(
    Uri.parse(url),
    headers: {'Authorization': 'Bearer $Jwt_Token'},
  );
  if (response.statusCode == 200) {
    return 1;
  } else {
    return 0;
  }
}

Future<int> UserProviderJwtVerify({required String Jwt_Token})async{
  const String url = Backend_Server_Url + "api/Authentication/userorproviderjwtverify";
  // verification
  final response = await http.get(
    Uri.parse(url),
    headers: {'Authorization': 'Bearer $Jwt_Token'},
  );
  if (response.statusCode == 200) {
    return 1;
  } else {
    return 0;
  }
}


Future<int> AllUserJwtVerify({required String Jwt_Token})async{
  const String url = Backend_Server_Url + "api/Authentication/alluserjwtverify";
  // verification
  final response = await http.get(
    Uri.parse(url),
    headers: {'Authorization': 'Bearer $Jwt_Token'},
  );
  if (response.statusCode == 200) {
    return 1;
  } else {
    return 0;
  }
}



Future<int> AddNotifications({
  required String CurrentUserEmail,
  required String ReceiverEmail,
  required String  Message,
  required String Current_User_JwtToken,
  required BuildContext context
}) async {
  try {
    final Map<String, dynamic> userData = {
      "CurrentUserEmail": CurrentUserEmail,
      "ReceiverEmail": ReceiverEmail,
      "Message": Message,
    };
    const String url = Backend_Server_Url + "api/Service/addnotification";
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer ${Current_User_JwtToken}'
      },
      body: json.encode(userData),
    );
    if (response.statusCode == 200)
    {
      print("Add notification info success");
      // Toast.Toastmsg("Notifcations added done.");
      return 1;
    }
    else if (response.statusCode == 500)
    {
      Toastget().Toastmsg("Add notification fail.Try again.Server error.");
      print("Add notification fail.Try again.Server error.");
      return 2;
    }
    else if (response.statusCode == 502)
    {
      Toastget().Toastmsg("Current user doesn't match.");
      print("Current user doesn't match.");
      await Clear_User_Data();
      await Random_token_Clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ErrorPage()),
            (route) => false,
      );
      Toastget().Toastmsg("Session End.Relogin please.");
      return 3;
    }
    else if (response.statusCode == 503)
    {
      Toastget().Toastmsg("Provide doesn't match.Choose different provider.");
      print("Provide doesn't match.Choose different provider.");
      return 4;
    }
    else if (response.statusCode == 501)
    {
      Toastget().Toastmsg("Invalid data format.Please provide data in correct format.");
      print("Invalid data format.Please provide data in correct format.");
      return 5;
    }
    else {
      print("Other status code.Error.");
      print("Status code = ${response.statusCode}");
      Toastget().Toastmsg("Add notification fail.Try again.Server error.");
      return 6;
    }
  } catch (Obj) {
    print("Exception caught while adding  notification info.");
    print(Obj.toString());
    Toastget().Toastmsg("Add notification fail.Try again.Server error.");
    return 7;
  }
}


Future<int> AddNewNotifications({
  required String CurrentUserEmail,
  required String ReceiverEmail,
  required bool  Status,
  required BuildContext context,
  required String Current_User_JwtToken,
}) async {
  try {
    final Map<String, dynamic> userData = {
      "CurrentUserEmail": CurrentUserEmail,
      "ReceiverEmail": ReceiverEmail,
      "Status": Status,
    };
    const String url = Backend_Server_Url + "api/Service/addnewnotification";
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer ${Current_User_JwtToken}'
      },
      body: json.encode(userData),
    );
    if (response.statusCode == 200)
    {
      print("Add new notification info success");
      // Toast.Toastmsg("Add new notification done.");
      return 1;
    }
    else if (response.statusCode == 500)
    {
      Toastget().Toastmsg("Add new notification fail.Try again.Server error.");
      print("Add new notification fail.Try again.Server error.");
      return 2;
    }
    else if (response.statusCode == 502)
    {
      Toastget().Toastmsg("Current user doesn't match.");
      print("Current user doesn't match.");
      await Clear_User_Data();
      await Random_token_Clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ErrorPage()),
            (route) => false,
      );
      Toastget().Toastmsg("Session End.Relogin please.");
      return 3;
    }
    else if (response.statusCode == 503)
    {
      Toastget().Toastmsg("Provide doesn't match.Choose different provider.");
      print("Provide doesn't match.Choose different provider.");
      return 4;
    }
    else if (response.statusCode == 501)
    {
      Toastget().Toastmsg("Invalid data format.Please provide data in correct format.");
      print("Invalid data format.Please provide data in correct format.");
      return 5;
    }
    else {
      print("Other status code.Error.");
      print("Status code = ${response.statusCode}");
      Toastget().Toastmsg("Add new notification fail.Try again.Server error.");
      return 6;
    }
  } catch (Obj) {
    print("Exception caught while adding  notification info.");
    print(Obj.toString());
    Toastget().Toastmsg("Add new notification fail.Try again.Server error.");
    return 7;
  }
}
