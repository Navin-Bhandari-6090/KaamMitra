import 'dart:convert';

import 'package:app/web/common%20widget/GreenTextfield.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../constant/Server_Database.dart';
import '../../authentication/Error_page.dart';
import '../../common method/Commmon_Method.dart';
import '../../common widget/toast.dart';

class UpdateAddress extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  const UpdateAddress({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});

  @override
  State<UpdateAddress> createState() => _UpdateAddressState();
}

class _UpdateAddressState extends State<UpdateAddress> {

  final Toast=Toastget();
  final AddressController=TextEditingController();



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Pro_User_Jwt_Verify(Jwt_Token: widget.User_JwtToken);
  }

  Future<void> Pro_User_Jwt_Verify({required String Jwt_Token}) async {
    int Result = await UserProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result == 1) {
      return;
    } else {
      await Clear_User_Data();
      await Random_token_Clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ErrorPage()),
            (route) => false,
      );
      Toastget().Toastmsg("Session End.Relogin please.");
      return;
    }
  }


  Future<void> ChangeAddress(
      {required String Address}) async {
    try {
      const String url = Backend_Server_Url + "api/Profile/updateaddress";
      Map<String, dynamic> UserDetails = {
        "Address": Address,
        "Email": widget.User_Email
      };
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.User_JwtToken}',
        },
        body: json.encode(UserDetails),
      );
      if (response.statusCode == 200) {
        print("Update success.");
        Toast.Toastmsg("Update  success.");
        return;
      } else if (response.statusCode == 500) {
        final data = jsonDecode(response.body);
        print("Exception Message: ${data['error']}");
        print("Exception caught in backend.");
        Toast.Toastmsg("Server erro try again.");
        return;
      } else if (response.statusCode == 501) {
        print("Details are not in correct format.");
        Toast.Toastmsg("Provide deatails in correct format.");
        return;
      } else if (response.statusCode == 502) {
        print("Email does not match");
        Toast.Toastmsg("Your current email doesn't match.");
        await Clear_User_Data();
        await Random_token_Clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ErrorPage()),
              (route) => false,
        );
        Toastget().Toastmsg("Session End.Relogin please.");
        return;
      } else {
        print("Update  failed.");
        Toast.Toastmsg("Server error try again.");
        return;
      }
    } catch (obj) {
      print("Exception in change address: $obj");
      Toast.Toastmsg("Server error try again.");
      return;
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Address"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children:
          [

            GreenField(controller: AddressController,
                label: "Enter address",
                icon: Icons.location_city
            ),

            ElevatedButton(onPressed: ()async{
              try{
                await ChangeAddress(
                  Address: AddressController.text.trim(),
                );
              }catch(obj){
                return;
              }

            }, child: Text("Chnage address."))




          ],
        ),
      ),
    );
  }
}
