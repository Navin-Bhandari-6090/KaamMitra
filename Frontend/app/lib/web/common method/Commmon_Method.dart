// Method to handle API response and save data if status code is 200
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';
import '../../constant/Server_Database.dart';
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
