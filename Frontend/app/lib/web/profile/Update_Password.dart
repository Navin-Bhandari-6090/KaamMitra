import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constant/Server_Database.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/toast.dart';

class UpdatePasswordScreen extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  const UpdatePasswordScreen({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final Toast = Toastget();
  @override
  void initState() {
    super.initState();
    Provider_Jwt_Verify(Jwt_Token:widget.User_JwtToken);
  }

  Future<void> Provider_Jwt_Verify({required String Jwt_Token})async
  {
    int Result=await ProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result==1)
    {
      return;
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => ErrorPage()
          )
      );
      Toastget().Toastmsg("Session End.Relogin please.");
      return;
    }
  }


  Future<bool> UpdatePassword(
      {required String NewPassword}) async {
    try {
      const String url = Backend_Server_Url + "api/Profile/updatepassword";
      Map<String, dynamic> new_data = {
        "Email":widget.User_Email,
        "Password": NewPassword,
      };
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.User_JwtToken}'
        },
        body: json.encode(new_data),
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        print("Update password success");
        return true;
      } else {
        print("Update password fail.");
        return false;
      }
    } catch (obj) {
      print("Update password fail.");
      print(obj.toString());
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Password"),
        centerTitle: true,
      ),
      body:SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Handle new password input
              },
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                // Call UpdatePassword function here
                bool success = await UpdatePassword(NewPassword: "new_password_here");
                if (success) {
                  Toast.Toastmsg("Password updated successfully.");
                } else {
                  Toast.Toastmsg("Failed to update password.");
                }
              },
              child: const Text('Update Password'),
            ),
          ],
        ),
      )
    );
  }
}
