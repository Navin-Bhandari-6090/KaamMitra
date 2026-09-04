import 'package:flutter/material.dart';

import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/toast.dart';
import 'Pro_Upd_Ser_Res_Video_Screen.dart';
import 'Pro_Update_Ser_Res_Photo_Screen.dart';

class SelectSerResUpdate extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  const SelectSerResUpdate({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});

  @override
  State<SelectSerResUpdate> createState() => _SelectSerResUpdateState();
}

class _SelectSerResUpdateState extends State<SelectSerResUpdate> {
  final Toast = Toastget();

  @override
  void initState() {
    super.initState();
    Provider_Jwt_Verify(Jwt_Token: widget.User_JwtToken);
  }

  Future<void> Provider_Jwt_Verify({required String Jwt_Token}) async
  {
    int Result = await ProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result == 1) {
      return;
    } else {
      await Clear_User_Data();
      await Random_token_Clear();
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => ErrorPage()
          )
      );
      Toast.Toastmsg("Session End.Relogin please.");
      return;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select service resources update"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            ElevatedButton(onPressed: (){

              Navigator.push(context, MaterialPageRoute(builder: (context) => ProUpdateSerResPhotoScreen(
                User_Email: widget.User_Email,
                User_JwtToken:widget.User_JwtToken,
                User_Role: widget.User_Role,),));

            },
                child: Text("Update service resources photo")) ,

            ElevatedButton(onPressed: (){

              Navigator.push(context, MaterialPageRoute(builder: (context) => ProUpdSerResVideoScreen(
                User_Email: widget.User_Email,
                User_JwtToken:widget.User_JwtToken,
                User_Role: widget.User_Role,),));

            },
                child: Text("Update service resources video"))
          ],
        ),

      ),

    );
  }
}
