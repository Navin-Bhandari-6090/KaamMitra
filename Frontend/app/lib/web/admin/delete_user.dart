import 'dart:convert';

import 'package:app/web/common%20widget/GreenTextfield.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';

import '../../constant/Server_Database.dart';
import '../../constant/variable.dart';
import '../common method/Commmon_Method.dart';

class DeleteUser extends StatefulWidget {
  final String User_JwtToken;
  const DeleteUser({super.key, required this.User_JwtToken});

  @override
  State<DeleteUser> createState() => _DeleteUserState();
}

class _DeleteUserState extends State<DeleteUser> {


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Admin_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
  }

  Future<void> DeleteUserInfo({
    required int UserNumber,
    required String Current_User_JwtToken,
    required BuildContext context,
  }) async {
    try {

      final String url =
          "${Backend_Server_Url}api/Admin/deleteuserinfo";

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $Current_User_JwtToken",
        },
        body: jsonEncode({
          "UserNumber": UserNumber,
        }),
      );




      if (response.statusCode == 200) {
        Toast.Toastmsg("User deleted successfully.");
        return;
      }

      String errorMessage = response.body.trim();

      if (errorMessage.isEmpty) {
        errorMessage = "Something went wrong. Please try again.";
      }

      switch (response.statusCode) {
        case 400:
          Toast.Toastmsg(errorMessage);
          break;

        case 401:
          Toast.Toastmsg("Unauthorized. Please login again.");
          Logout(context: context);
          break;

        case 403:
          Toast.Toastmsg("Admin access required.");
          Logout(context: context);
          break;

        case 404:
          Toast.Toastmsg(errorMessage);
          break;

        case 500:
          Toast.Toastmsg(errorMessage);
          break;

        default:
          Toast.Toastmsg(errorMessage);
          break;
      }
    } catch (e, stackTrace) {
      Toast.Toastmsg("Something went wrong. Please try again.");
    }
  }

  final TextEditingController UserNumberController =
  TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('Delete User'),
        centerTitle: true,
      ),
      body:
      SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        child: Column(
          children:
          [

            GreenField(controller: UserNumberController, label: "Enter user ID.", icon: Icons.numbers),

            ElevatedButton(onPressed: ()async{
              try{

                if(UserNumberController.text.isEmptyOrNull){
                  Toast.Toastmsg("User id is required.");
                  return;
                }

                int? UserNumberValue=int.tryParse(UserNumberController.text);

                await DeleteUserInfo(
                  UserNumber: UserNumberValue!,
                  Current_User_JwtToken: widget.User_JwtToken,
                  context: context,
                );

              }catch(obj){
                print(obj.toString());
                return;
              }

            }, child: Text("Delete user.")),

          ],
        ),
      ),

    );
  }
}
