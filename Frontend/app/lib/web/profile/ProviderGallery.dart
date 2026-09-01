import 'package:flutter/material.dart';

import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/toast.dart';
import 'Provider_Service_File.dart';
import 'Provider_Service_Photo.dart';

class MyGalleryScreen extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  final String Service_Name;
  const MyGalleryScreen({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role, required this.Service_Name});

  @override
  State<MyGalleryScreen> createState() => _MyGalleryScreenState();
}

class _MyGalleryScreenState extends State<MyGalleryScreen> {


  @override
  void initState() {
    super.initState();
    JwtVerify(Jwt_Token:widget.User_JwtToken);
  }

  Future<void> JwtVerify({required String Jwt_Token})async
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Gallery'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children:
          [

            ElevatedButton(onPressed: (){
              Navigator.push(context,MaterialPageRoute(builder:
                  (context) =>ProviderServicePhoto (
                    User_Email: widget.User_Email,
                User_JwtToken:widget.User_JwtToken,
                User_Role: widget.User_Role,
                    Service_Name: widget.Service_Name,

              )
              )
              );

            },
              child: Text("Photo")
            ),

            ElevatedButton(onPressed: (){

            },
              child: Text("Video"),
            ),

            ElevatedButton(onPressed: (){

              Navigator.push(context,MaterialPageRoute(builder:
                  (context) =>ProviderServiceFile (User_Email: widget.User_Email,
                User_JwtToken:widget.User_JwtToken,
                User_Role: widget.User_Role,
                    Service_Name:widget.Service_Name,
              )
              )
              );

            },
              child: Text("File"),
            ),



          ],
        ),
      )
    );
  }
}
