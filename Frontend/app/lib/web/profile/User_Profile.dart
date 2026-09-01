import 'package:app/web/common%20widget/commonbutton.dart';
import 'package:app/web/home/Home_Screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../authentication/Error_page.dart';
import '../authentication/Login.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/toast.dart';

class ProfileScreenUser extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  final bool UserLogin;
  const ProfileScreenUser({super.key,req, required this.User_Email, required this.User_JwtToken, required this.User_Role, required this.UserLogin});

  @override
  State<ProfileScreenUser> createState() => _ProfileScreenUserState();
}

class _ProfileScreenUserState extends State<ProfileScreenUser> {
  final Toast = Toastget();
  @override
  Widget build(BuildContext context) {
    var shortestval = MediaQuery.of(context).size.shortestSide;
    var widthval = MediaQuery.of(context).size.width;
    var heightval = MediaQuery.of(context).size.height;
    return Scaffold(
        appBar: AppBar(
          title: const Text("Profile Screen User"),
          centerTitle: true,
        ),
        body:
        SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          child: Container(
            width: widthval,
            height: heightval,
            color: Colors.green,
            child: Column(
                children:
                [

                   Commonbutton("Logout", ()async{
                     await Clear_User_Data();
                     await Random_token_Clear();
                     Toast.Toastmsg("Logout Success");

                     Navigator.pushReplacement(context,
                         MaterialPageRoute(builder: (context) => ErrorPage())
                     );
                     Toastget().Toastmsg("Session End.Relogin please.");
                     return;

                   }, context, Colors.red)

                ]
            )
          ),
        )

    );
  }
}
