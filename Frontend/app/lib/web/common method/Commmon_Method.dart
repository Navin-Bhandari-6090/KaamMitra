// Method to handle API response and save data if status code is 200
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart' hide Toast;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';
import '../../constant/Server_Database.dart';
import '../../models/AdminUserInfosModel.dart';
import '../../models/AdvancePaymentPhotoModel.dart';
import '../../models/AdvancePaymentQRPhoto.dart';
import '../../models/BookingInfoModel.dart';
import '../../models/ChatInfoModel.dart';
import '../../models/NewMsgStatusModel.dart';
import '../authentication/Error_page.dart';
import '../common widget/toast.dart';
import '../../../constant/variable.dart';

// Method to handle API response and save data if status code is 200
Future<void> handleResponse(Map<String, dynamic> responseData) async
{
  String token = responseData['token']!;
  String email = responseData['email']!;
  String User_Type = responseData['usertype']!;
  int User_Number = responseData['usernumber']!;
  await Save_User_Data(Jwt_Token: token, User_Email: email, User_Role: User_Type, User_Number: User_Number);
  print("User data");
  print("jwt token");
  print(token);
  print("Email");
  print(email);
  print("user type");
  print(User_Type);
  print("user number");
  print(User_Number);
  return;
}

//saving user credentials in hive
Future<void> Save_User_Data({required String Jwt_Token,required String User_Email,required String User_Role,required int User_Number }) async {
  final box = await Hive.openBox('User_Data');
  // Ensure that token is not null
  if (Jwt_Token.isNotEmptyAndNotNull && User_Email.isNotEmptyAndNotNull && User_Role.isNotEmptyAndNotNull && User_Number>=1) {
    // Save user credentials to Hive
    await box.put('jwt_token', Jwt_Token);
    await box.put('user_email', User_Email);
    await box.put('user_role', User_Role);
    await box.put('user_number', User_Number);
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
  await box.delete('user_number');
  print("User data cleared.");
}

//saving user credentials in hive
Future<int> CheckUserJwtToken() async
{
  final box = await Hive.openBox('User_Data');
  String? Jwt_Token = box.get('jwt_token');
  String? User_Email = box.get('user_email');
  String? User_Role = box.get('user_role');
  int? User_Number = box.get('user_number');
  // Ensure that token is not null
  if (Jwt_Token.isNotEmptyAndNotNull && User_Email.isNotEmptyAndNotNull && User_Role.isNotEmptyAndNotNull && User_Number!>=1) {
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
  const String url = Backend_Server_Url + "api/Authentication/jwtverifyuser";
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
  const String url = Backend_Server_Url + "api/Authentication/jwtverifyadmin";
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

Future<void> Random_Jwt_Verify({required String Jwt_Token,required BuildContext context}) async
{
  try {
    int Result = await RandomJwtVerify(Jwt_Token: Jwt_Token);

    if (Result == 1) {
      return;
    } else {
      Logout(context: context);

      return;
    }
  } catch (e)
  {

    Logout(context: context);

    return;

  }
}

// ===========================================================================
// ORIGINAL NETWORK / AUTH LOGIC — unchanged
// ===========================================================================
Future<void> User_Jwt_Verify({required String Jwt_Token,required BuildContext context}) async {
  try {
    int Result = await UserJwtVerify(Jwt_Token: Jwt_Token);
    if (Result == 1) {
      return;
    } else {
     Logout(context: context);
      return;
    }
  } catch (e) {
    Logout(context: context);
    return;
  }
}

Future<void> Admin_Jwt_Verify({required String Jwt_Token,required BuildContext context}) async {
  int Result = await AdminJwtVerify(Jwt_Token: Jwt_Token);
  if (Result == 1) {
    return;
  } else {
    await Logout(context: context);
    return;
  }
}


Future<void> Provider_Jwt_Verify({required String Jwt_Token,required BuildContext context}) async {
  int Result = await ProviderJwtVerify(Jwt_Token: Jwt_Token);
  if (Result == 1) {
    return;
  } else {
    await Logout(context: context);
    return;
  }
}


Future<void> Provider_User_Jwt_Verify({required String Jwt_Token,required BuildContext context}) async {
  int Result = await UserProviderJwtVerify(Jwt_Token: Jwt_Token);
  if (Result == 1) {
    return;
  } else {
    await Logout(context: context);
    return;
  }
}

Future<void> All_User_Jwt_Verify({required String Jwt_Token,required BuildContext context}) async {
  int Result = await AllUserJwtVerify(Jwt_Token: Jwt_Token);
  if (Result == 1) {
    return;
  } else {
    await Logout(context: context);
    return;
  }
}

Future<void> Logout({required BuildContext context})async{
  try {
    await Clear_User_Data();
    await Random_token_Clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => ErrorPage()),
          (route) => false,
    );
    Toastget().Toastmsg("Session End.Relogin please.");
    return;
  }catch(obj){
    return;
  }

}



Future<int> AddNotifications({
  required num ReceiverNumber,
  required String  Message,
  required String Current_User_JwtToken,
  required BuildContext context
}) async {
  try {
    final Map<String, dynamic> userData = {
      "ReceiverNumber": ReceiverNumber,
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
      // print("Add notification info success");
      // Toast.Toastmsg("Notifcations added done.");
      return 1;
    }
    else if (response.statusCode == 500)
    {
      // Toastget().Toastmsg("Add notification fail.Try again.Server error.");
      // print("Add notification fail.Try again.Server error.");
      return 2;
    }
    else if (response.statusCode == 502)
    {

      Toastget().Toastmsg("Current user doesn't match.");
      // print("Current user doesn't match.");

      // Toastget().Toastmsg("Session End.Relogin please.");
      await Logout(context: context);
      return 3;
    }
    else if (response.statusCode == 503)
    {
      // Toastget().Toastmsg("Provide doesn't match.Choose different provider.");
      // print("Provide doesn't match.Choose different provider.");
      return 4;
    }
    else if (response.statusCode == 501)
    {
      // Toastget().Toastmsg("Invalid data format.Please provide data in correct format.");
      // print("Invalid data format.Please provide data in correct format.");
      return 5;
    }
    else {
      // print("Other status code.Error.");
      // print("Status code = ${response.statusCode}");
      // Toastget().Toastmsg("Add notification fail.Try again.Server error.");
      return 6;
    }
  } catch (Obj) {
    // print("Exception caught while adding  notification info.");
    // print(Obj.toString());
    // Toastget().Toastmsg("Add notification fail.Try again.Server error.");
    return 7;
  }
}


Future<int> AddNewNotifications({
  required num ReceiverNumber,
  required bool  Status,
  required BuildContext context,
  required String Current_User_JwtToken,
}) async {
  try {
    final Map<String, dynamic> userData = {
      "ReceiverNumber": ReceiverNumber,
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
      // print("Add new notification info success");
      // Toast.Toastmsg("Add new notification done.");
      return 1;
    }
    else if (response.statusCode == 500)
    {
      // Toastget().Toastmsg("Add new notification fail.Try again.Server error.");
      // print("Add new notification fail.Try again.Server error.");
      return 2;
    }
    else if (response.statusCode == 502)
    {
      Toastget().Toastmsg("Current user doesn't match.");
      // print("Current user doesn't match.");
  await Logout(context: context);
      // Toastget().Toastmsg("Session End.Relogin please.");
      return 3;
    }
    else if (response.statusCode == 503)
    {
      // Toastget().Toastmsg("Provide doesn't match.Choose different provider.");
      // print("Provide doesn't match.Choose different provider.");
      return 4;
    }
    else if (response.statusCode == 501)
    {
      // Toastget().Toastmsg("Invalid data format.Please provide data in correct format.");
      // print("Invalid data format.Please provide data in correct format.");
      return 5;
    }
    else {
      // print("Other status code.Error.");
      // print("Status code = ${response.statusCode}");
      // Toastget().Toastmsg("Add new notification fail.Try again.Server error.");
      return 6;
    }
  } catch (Obj) {
    // print("Exception caught while adding  notification info.");
    // print(Obj.toString());
    // Toastget().Toastmsg("Add new notification fail.Try again.Server error.");
    return 7;
  }
}


List<AdvancePaymentPhotoModel> AdvancePaymentPhotoList = [];

Future<int> GetAdvancePaymentPhoto({
  required String BookId,
  required String UserEmail,
  required BuildContext context,
  required String Current_User_JwtToken,
  required bool UpdateStatePhotoUpload
}) async {
  try {
    final Map<String, dynamic> userData = {
      "BookId": BookId,
      "UserEmail": UserEmail,
    };
    const String url = Backend_Server_Url + "api/Booking/getadvancepaymentphoto";
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
      print("Advance payment info get success.");
      // Toast.Toastmsg("Add new notification done.");
      Map<dynamic, dynamic> responseData = await jsonDecode(response.body);
      AdvancePaymentPhotoList.clear();
      AdvancePaymentPhotoList.add(AdvancePaymentPhotoModel.fromJson(responseData));
      return 1;
    }
    else if (response.statusCode == 500)
    {
      // Toastget().Toastmsg("Add new notification fail.Try again.Server error.");
      print("Fail.Try again.Server error.");
      AdvancePaymentPhotoList.clear();
      return 2;
    }
    else if (response.statusCode == 502)
    {
      Toastget().Toastmsg("Current user doesn't match.");
      print("Current user doesn't match.");
      AdvancePaymentPhotoList.clear();
      await Clear_User_Data();
      await Random_token_Clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ErrorPage()),
            (route) => false,
      );
      // Toastget().Toastmsg("Session End.Relogin please.");
      return 3;
    }
    else if (response.statusCode == 501)
    {
      // Toastget().Toastmsg("Invalid data format.Please provide data in correct format.");
      print("Invalid data format.Please provide data in correct format.");
      AdvancePaymentPhotoList.clear();
      return 5;
    }
    else {
      print("Other status code.Error.");
      print("Status code = ${response.statusCode}");
      // Toastget().Toastmsg("Add new notification fail.Try again.Server error.");
      AdvancePaymentPhotoList.clear();
      return 6;
    }
  } catch (Obj) {
    print("Exception caught while getting advance photo info.");
    print(Obj.toString());
    // Toastget().Toastmsg("Add new notification fail.Try again.Server error.");
    AdvancePaymentPhotoList.clear();
    return 7;
  }
}


List<AdvancePaymentQrPhoto> AdvancePaymentQrPhotoList = [];

Future<int> GetAdvancePaymentQRPhoto({
  required num UserNumber,
  required BuildContext context,
  required String Current_User_JwtToken,
}) async {
  try {
    final Map<String, dynamic> userData = {
      "UserNumber": UserNumber,
    };
    const String url = Backend_Server_Url + "api/Booking/getadvanceqrphoto";
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
      print("Advance payment qr info get success.");
      // Toast.Toastmsg("Add new notification done.");
      Map<dynamic, dynamic> responseData = await jsonDecode(response.body);
      AdvancePaymentQrPhotoList.clear();
      AdvancePaymentQrPhotoList.add(AdvancePaymentQrPhoto.fromJson(responseData));
      return 1;
    }
    else if (response.statusCode == 500)
    {
      // Toastget().Toastmsg("Add new notification fail.Try again.Server error.");
      print("Fail.Try again.Server error.");
      AdvancePaymentQrPhotoList.clear();
      return 2;
    }
    else if (response.statusCode == 502)
    {
      Toastget().Toastmsg("Current user doesn't match.");
      print("Current user doesn't match.");
      AdvancePaymentQrPhotoList.clear();
      await Clear_User_Data();
      await Random_token_Clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ErrorPage()),
            (route) => false,
      );
      // Toastget().Toastmsg("Session End.Relogin please.");
      return 3;
    }
    else if (response.statusCode == 501)
    {
      // Toastget().Toastmsg("Invalid data format.Please provide data in correct format.");
      print("Invalid data format.Please provide data in correct format.");
      AdvancePaymentQrPhotoList.clear();
      return 5;
    }
    else {
      print("Other status code.Error.");
      print("Status code = ${response.statusCode}");
      // Toastget().Toastmsg("Add new notification fail.Try again.Server error.");
      AdvancePaymentQrPhotoList.clear();
      return 6;
    }
  } catch (Obj) {
    print("Exception caught while getting advance photo info.");
    print(Obj.toString());
    // Toastget().Toastmsg("Add new notification fail.Try again.Server error.");
    AdvancePaymentQrPhotoList.clear();
    return 7;
  }
}



String GetPhotoUrl(String? photoPath) {
  try {
    if (photoPath == null || photoPath.trim().isEmpty) {
      return "";
    }

    final String baseUrl =
    Backend_Server_Url.endsWith("/")
        ? Backend_Server_Url.substring(
      0,
      Backend_Server_Url.length - 1,
    )
        : Backend_Server_Url;

    final String path =
    photoPath.trim().startsWith("/")
        ? photoPath.trim()
        : "/${photoPath.trim()}";

    return "$baseUrl$path";
  } catch (obj) {
    print("Exception while creating photo URL.");
    print(obj.toString());
    return "";
  }
}



List<AdminUserInfosModel> UserInfoModelList = [];

Future<void> GetUserInfo({
  required String jwttoken,
}) async {
  try {
    const String url = Backend_Server_Url + "api/Admin/getuserinfo";
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $jwttoken',
      },
    );
    if (response.statusCode == 200) {
      UserInfoModelList.clear();
      List<dynamic> responseData = await jsonDecode(response.body);
      UserInfoModelList.clear();
      UserInfoModelList.addAll(
          responseData.map((data) => AdminUserInfosModel.fromJson(data)).toList());
      return;
      return;
    } else {
      UserInfoModelList.clear();
      print("Data insert in userinfo list failed.");
      return;
    }

  } catch (obj) {
    UserInfoModelList.clear();
    print("Exception caught while fetching user data for profile screen");
    print(obj.toString());
    return;
  }
}



bool LastSendSucceeded = false;

Future<bool> AddChatMessage({
  required String Message,
  required int ReceiverNumber,
  required String User_JwtToken,
}) async {
  try {
    final response = await http.post(
      Uri.parse("${Backend_Server_Url}api/Home/addchatmessage"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $User_JwtToken",
      },
      body: jsonEncode({
        "Message": Message.trim(),
        "ReceiverNumber": ReceiverNumber,
      }),
    );

    if (response.statusCode == 200) {
      Toast.Toastmsg("Message sent successfully.");
      return true;
    } else if (response.statusCode == 400) {
      Toast.Toastmsg("Invalid chat message data.");
    } else if (response.statusCode == 401) {
      Toast.Toastmsg("Please login again.");
    } else if (response.statusCode == 403) {
      Toast.Toastmsg("You do not have permission.");
    } else if (response.statusCode == 404) {
      Toast.Toastmsg("Requested endpoint not found.");
    } else if (response.statusCode == 500) {
      Toast.Toastmsg("Something went wrong on the server.");
    } else if (response.statusCode == 506) {
      Toast.Toastmsg("Invalid user authentication.");
    } else if (response.statusCode == 507) {
      Toast.Toastmsg("User not found.");
    } else if (response.statusCode == 508) {
      Toast.Toastmsg("Your account is blocked or the receiver was not found.");
    } else if (response.statusCode == 509) {
      Toast.Toastmsg("The receiver's account has been blocked.");
    } else {
      Toast.Toastmsg("Failed to send message.");
    }
    return false;
  } catch (e) {
    Toast.Toastmsg("Something went wrong.");
    return false;
  }
}




List<ChatInfoModel> ChatInfos=[];

Future<List<ChatInfoModel>> FetchChatMessagesFor({
  required int UserNumber,
  required String User_JwtToken,
}) async {
  try {
    final response = await http.post(
      Uri.parse("${Backend_Server_Url}api/Home/getchatmessage"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $User_JwtToken",
      },
      body: jsonEncode({"UserNumber": UserNumber}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) => ChatInfoModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
  } catch (e) {
    // print('FetchChatMessagesFor error: $e');
  }
  return <ChatInfoModel>[];
}

Future<void> GetChatMessages({
  required int UserNumber,
  required String User_JwtToken,
}) async {
  try {
    const String url = "${Backend_Server_Url}api/Home/getchatmessage";

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $User_JwtToken",
      },
      body: jsonEncode({"UserNumber": UserNumber}),
    );

    print('[CHAT API] status=${response.statusCode} '
        'bytes=${response.bodyBytes.length}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      final List<ChatInfoModel> parsed = data
          .map((item) => ChatInfoModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Replace only after parsing fully succeeded.
      ChatInfos
        ..clear()
        ..addAll(parsed);

      print('[CHAT API] parsed=${ChatInfos.length} '
          'last="${ChatInfos.isEmpty ? null : ChatInfos.last.message}"');
    } else {
      print('[CHAT API] FAILED ${response.statusCode}: ${response.body}');
    }
  } catch (e, st) {
    print('[CHAT API] ERROR: $e\n$st');
  }
}

Future<int> AddChatStatus({
  required String JwtToken,
  required int MessageReceiverNumber,
  required BuildContext context,
}) async {
  try {
    if (MessageReceiverNumber <= 0) {
      Toast.Toastmsg("Invalid receiver information.");
      return 3;
    }

    final String url =
        "${Backend_Server_Url}api/Home/addchatstatus";

    final response = await http.put(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $JwtToken",
      },
      body: jsonEncode({
        "MessageReceiverNumber": MessageReceiverNumber,
      }),
    );

    if (response.statusCode == 200) {
      print("Chat status add successfully.");
      return 1;
    } else if (response.statusCode == 400) {
      Toast.Toastmsg("Invalid receiver information.");
    } else if (response.statusCode == 401) {
      Toast.Toastmsg("Your session has expired. Please login again.");
      await Logout(context: context);
    } else if (response.statusCode == 403) {
      Toast.Toastmsg("You are not authorized to update chat status.");
    } else if (response.statusCode == 500) {
      Toast.Toastmsg("Server error. Please try again later.");
    } else {
      Toast.Toastmsg("Unable to add chat status. Please try again.");
    }

    return 3;
  } catch (e) {
    Toast.Toastmsg("Something went wrong. Please try again.");
    return 3;
  }
}


Future<int> UpdateChatStatus({
  required String JwtToken,
  required int MessageReceiverNumber,
  required BuildContext context,
}) async {
  try {
    if (MessageReceiverNumber <= 0) {
      Toast.Toastmsg("Invalid receiver information.");
      return 3;
    }

    final String url =
        "${Backend_Server_Url}api/Home/updatechatstatus";

    final response = await http.put(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $JwtToken",
      },
      body: jsonEncode({
        "MessageReceiverNumber": MessageReceiverNumber,
      }),
    );

    if (response.statusCode == 200) {
      print("Chat status updated successfully.");
      return 1;
    } else if (response.statusCode == 400) {
      Toast.Toastmsg("Invalid receiver information.");
    } else if (response.statusCode == 401) {
      Toast.Toastmsg("Your session has expired. Please login again.");
      await Logout(context: context);
    } else if (response.statusCode == 403) {
      Toast.Toastmsg("You are not authorized to update chat status.");
    } else if (response.statusCode == 500) {
      Toast.Toastmsg("Server error. Please try again later.");
    } else {
      Toast.Toastmsg("Unable to update chat status. Please try again.");
    }

    return 3;
  } catch (e) {
    Toast.Toastmsg("Something went wrong. Please try again.");
    return 3;
  }
}


List<NewMsgStatusModel> NewMsgStatusInfoList=[];

Future<int> GetNewMsgStatus({
  required String JwtToken,
  required BuildContext context,
}) async {
  try {
    final String url =
        "${Backend_Server_Url}api/Home/getnewmessagestatus";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $JwtToken",
      },
    );

    if (response.statusCode == 200) {
      NewMsgStatusInfoList.clear();
      final dynamic responseData = jsonDecode(response.body);
        NewMsgStatusInfoList.add(
          NewMsgStatusModel.fromJson(responseData),
        );
        print("New message status info get success.");
        return 1;
    } else if (response.statusCode == 401) {
      NewMsgStatusInfoList.clear();
      Toast.Toastmsg("Your session has expired. Please login again.");
      await Logout(context: context);
    } else if (response.statusCode == 403) {
      NewMsgStatusInfoList.clear();
      Toast.Toastmsg("You are not authorized to access this information.");
    } else if (response.statusCode == 404) {
      NewMsgStatusInfoList.clear();
      Toast.Toastmsg("User information not found.");
    } else if (response.statusCode == 506) {
      NewMsgStatusInfoList.clear();
      Toast.Toastmsg("Your account has been blocked.");
      await Logout(context: context);
    } else if (response.statusCode == 500) {
      NewMsgStatusInfoList.clear();
      Toast.Toastmsg("Server error. Please try again later.");
    } else {
      NewMsgStatusInfoList.clear();
      Toast.Toastmsg("Unable to get new message status information.");
    }
    return 3;
  } catch (e) {
    NewMsgStatusInfoList.clear();
    Toast.Toastmsg("Something went wrong. Please try again.");
    return 3;
  }
}





List<BookingInfoModel> ReactiveBookingInfos=[];

Future<int> GetBookingInfoUser({
  required int BookId,
  required String JwtToken,
  required BuildContext context,
}) async {
  try {
    const String url =
        Backend_Server_Url + "api/Booking/sendfilterbookinginfo";

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $JwtToken",
      },
      body: jsonEncode({
        "BookId": BookId,
      }),
    );

    final int statusCode = response.statusCode;
    final String responseBody = response.body.trim();

    if (statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(responseBody);

      // Clear previous booking data before adding new data
      ReactiveBookingInfos.clear();

      ReactiveBookingInfos = jsonData
          .map((data) => BookingInfoModel.fromJson(data))
          .toList();

      return 1;
    }
    else if (statusCode == 400 || statusCode == 501) {
      Toast.Toastmsg(
      "Booking data not found.",
      );
      return 2;
    }
    else if (statusCode == 401) {
      Toast.Toastmsg("Please log in again. Your session is invalid.");
      await Logout(context: context);
      return 3;
    }
    else if (statusCode == 403) {
      Toast.Toastmsg("You are not authorized to access this booking.");
      await Logout(context: context);
      return 4;
    }
    else if (statusCode == 404) {
      Toast.Toastmsg("Booking information not found.");
      return 5;
    }
    else if (statusCode == 500) {
      Toast.Toastmsg(
   "Server error occurred while retrieving booking information.",
      );
      return 6;
    }
    else if (statusCode == 502) {
      Toast.Toastmsg("User account not found.");
      await Logout(context: context);
      return 7;
    }
    else if (statusCode == 506) {
      Toast.Toastmsg(
        "You have been blocked by System. Contact the KaamMitra community.",
      );
      await Logout(context: context);
      return 8;
    }
    else if (statusCode == 507) {
      Toast.Toastmsg("No booking data available.");
      return 9;
    }
    else if (statusCode == 508) {
      Toast.Toastmsg("The service associated with this booking was not found.");
      return 10;
    }
    else {
      Toast.Toastmsg("Unable to retrieve booking information. Please try again.",
      );
      return 11;
    }
  } catch (e) {
    Toast.Toastmsg(
      "Something went wrong while retrieving booking information.",
    );
    return 12;
  }
}



Future<void> PickPhoto()async{
  try{
    int Result = await change_photo_cont_getx.pickImage();
    if (Result == 1)
    {
      Toast.Toastmsg("Photo pick success.");
      return;
    }
    else if(Result==2){
      Toast.Toastmsg("Only ${PhotoExtension} format accepted.");
      return;
    }
    else if(Result==5){
      Toast.Toastmsg("Video is larger then ${PhotoSize}.Please compressed and upload..");
      return;
    }
    else {
      Toast.Toastmsg("Photo pick  fail.");
      return;
    }
  }catch(obj){
    Toast.Toastmsg("Photo pick  fail.");
    return;
  }
}

Future<void> PickVideo()async{
  try{
    int Result = await change_video_cont_getx.pickVideo();
    if (Result == 1)
    {
      Toast.Toastmsg("Video pick success.");
      return;
    }
    else if(Result==2){
      Toast.Toastmsg("Only ${VideoExtension} format accepted.");
      return;
    }
    else if(Result==5){
      Toast.Toastmsg("Video is larger then ${VideoSize}.Please compressed and upload..");
      return;
    }
    else {
      Toast.Toastmsg("Video pick  fail.");
      return;
    }
  }catch(obj){
    Toast.Toastmsg("Video pick  fail.");
    return;
  }
}

Future<void> PickFile()async{
  try{
    int Result = await change_file_cont_getx.pickFile();
    if (Result == 1)
    {
      Toast.Toastmsg("File pick success.");
      return;
    }
    else if(Result==2){
      Toast.Toastmsg("Only ${FileExtension} format accepted.");
      return;
    }
    else if(Result==5){
      Toast.Toastmsg("File is larger then ${FileSize}.Please compressed and upload..");
      return;
    }
    else {
      Toast.Toastmsg("File pick  fail.");
      return;
    }
  }catch(obj){
    Toast.Toastmsg("File pick  fail.");
    return;
  }
}

void ClearFilesValues()
{

  try{
    change_video_cont_getx.videoExtension.value="";
    change_video_cont_getx.videoBytes.value=null;
    change_video_cont_getx.videoPath.value="";
    change_photo_cont_getx.imageExtension.value="";
    change_photo_cont_getx.imageBytes.value=null;
    change_photo_cont_getx.imagePath.value="";
    change_file_cont_getx.fileExtension.value="";
    change_file_cont_getx.fileBytes.value=null;
    change_file_cont_getx.filePath.value="";
    return;
  }
      catch(obj)
      {
        return;
      }


}






