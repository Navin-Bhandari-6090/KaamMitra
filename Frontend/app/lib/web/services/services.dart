import 'package:flutter/material.dart';

import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/toast.dart';

class ServicesScreen extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  const ServicesScreen({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    JwtVerify(Jwt_Token:widget.User_JwtToken);
  }


  Future<void> JwtVerify({required String Jwt_Token})async
  {
    int Result=await UserProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result==1)
    {
      return;
    } else
    {
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => ErrorPage())
        ,
            (route) => false,
      );
      Toastget().Toastmsg("Session End.Relogin please.");
      return;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Services Screen"),
        centerTitle: true,
      ),
      body:Container()
    );
  }
}
