import 'package:app/web/header/Header.dart';
import 'package:flutter/material.dart';
import '../authentication/Error_page.dart';
import '../authentication/Login.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/toast.dart';

class HomeScreenUi extends StatefulWidget
{
  final bool UserLogin;
  final String User_JwtToken;
  const HomeScreenUi({super.key,required this.UserLogin, required this.User_JwtToken});
  @override
  State<HomeScreenUi> createState() => _HomeScreenUiState();
}

class _HomeScreenUiState extends State<HomeScreenUi> {
  @override
  void initState() {
    super.initState();
    widget.UserLogin==true?User_Provider_Jwt_Verify(Jwt_Token: widget.User_JwtToken):Random_Jwt_Verify(Jwt_Token:widget.User_JwtToken);
  }

  Future<void> Random_Jwt_Verify({required String Jwt_Token})async
  {
    try {
      int Result = await RandomJwtVerify(Jwt_Token: Jwt_Token);
      if (Result == 1) {
        return;
      } else {
        await Clear_User_Data();
        await Random_token_Clear();
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => ErrorPage()
            )
        );
        Toastget().Toastmsg("Session End.Relogin please.");
        return;
      }
    }catch(e){
      await Clear_User_Data();
      await Random_token_Clear();
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => ErrorPage()
          )
      );
      Toastget().Toastmsg("Session End.Relogin please.");
      return;
    }
  }

  Future<void> User_Provider_Jwt_Verify({required String Jwt_Token})async
  {
    try {
      int Result = await UserProviderJwtVerify(Jwt_Token: Jwt_Token);
      if (Result == 1) {
        return;
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => ErrorPage()
            )
        );
        Toastget().Toastmsg("Session End.Relogin please.");
        return;
      }
    } catch (e) {
      await Clear_User_Data();
      await Random_token_Clear();
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
    var shortestval = MediaQuery.of(context).size.shortestSide;
    var widthval = MediaQuery.of(context).size.width;
    var heightval = MediaQuery.of(context).size.height;
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Home Screen"),
      //   centerTitle: true,
      // ),
      body:SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        child:
        Container(
          width: widthval,
          height: heightval,
          color: Colors.green,
          child: Column(
            children:
            [

             widget.UserLogin==false?
             Center(child: Container(child:
             TextButton(
               onPressed: () {
                 Navigator.pushReplacement(context, MaterialPageRoute(builder: (context){
                   return LoginScreen(User_JwtToken: widget.User_JwtToken,);
                 }));
               },
               child: Text("Please login to use all kind of services.Click login to login."),
             )
               ,
             )
               ,):Container(),

              Container(
                height: heightval*0.05,
                  width: widthval,
                  child: Header(UserLogin: widget.UserLogin, User_JwtToken:widget.User_JwtToken,)
              ),



            ],
          ),
        ),
      ),
    );
  }
}
