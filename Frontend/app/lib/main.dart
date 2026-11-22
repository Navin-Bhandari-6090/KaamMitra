import 'package:app/state%20management/bloc/common%20state/common_variable_bloc.dart';
import 'package:app/web/authentication/Error_page.dart';
import 'package:app/web/common%20method/Commmon_Method.dart';
import 'package:app/web/admin/Admin_Home_Screenn.dart';
import 'package:app/web/home/Home_Screen.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';


void main() async {
  try{
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  // DevicePreview.enable();
  // await Hive.initFlutter();
  // await Clear_User_Data();
  // await Random_token_Clear();
  // print("mainLogout Success");
 int UserData=await CheckUserJwtToken();
  print("User data get result = ${UserData}");
 if(UserData==1)
 {
   final box = await Hive.openBox('User_Data');
   String? Jwt_Token = box.get('jwt_token');
   String? User_Role = box.get('user_role');
   String? User_Email=box.get('user_email');
   int? User_Number=box.get('user_number');

   int AllUserVerify=await AllUserJwtVerify(Jwt_Token:Jwt_Token!);

   print("all user jwt verify result = ${AllUserVerify}");
   if(AllUserVerify==1)
   {
     print("Verified token");
     print(Jwt_Token);
     runApp
       (

       // DevicePreview
       //   (
       //   builder: (context) =>

         MyApp
           (
           Result: 1,UserLogin: true, User_JwtToken: Jwt_Token!, User_Role:User_Role!, User_Email:User_Email!, User_Number: User_Number!,
         )


         // )

     );
   }
   else
   {
     print("Random token generate start");
     await GenerateRandomToken();
     int Result = await CheckRandomJwtToken();
     print("Random token result = ${Result}");
     final box = await Hive.openBox('Random_Token');
     String? Jwt_Token = box.get('random_token');
     print("Random token");
     print(Jwt_Token);
     runApp(

       // DevicePreview
       //   (
       //
       //   builder: (context) =>

         MyApp(Result: 1,UserLogin: false, User_JwtToken:Jwt_Token!, User_Role:"", User_Email: '',User_Number: 0
         )

       // )

          );


   }
 }
 else
 {
   print("Random token generate start");
   await GenerateRandomToken();
   int Result = await CheckRandomJwtToken();
   print("Random token result = ${Result}");
     final box = await Hive.openBox('Random_Token');
     String? Jwt_Token = box.get('random_token');
   print("Random token");
   print(Jwt_Token);
     runApp
       (

       // DevicePreview(
       //   builder: (context) =>

         MyApp(Result: 1,UserLogin: false, User_JwtToken:Jwt_Token!, User_Role:"", User_Email: '',User_Number: 0)

       // )

     );


 }
 }catch(e)
  {
    runApp
      (
      // DevicePreview(
      //   builder: (context) =>

        MyApp(Result: 0,UserLogin: false, User_JwtToken:"", User_Role: "", User_Email: '',User_Number: 0
        )

      // )

    );
  }
 }

class MyApp extends StatelessWidget
{
   final int? Result;
   final bool UserLogin;
   final String User_Role;
   final String User_JwtToken;
   final String User_Email;
   final int User_Number;
   const MyApp({super.key,required this.Result,required this.UserLogin, required this.User_JwtToken, required this.User_Role, required this.User_Email, required this.User_Number});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context)
  {

    Widget HomeScreen;
    if(Result==1 && UserLogin==false)
    {
      HomeScreen=HomeScreenUi(UserLogin: false, User_JwtToken:User_JwtToken,);
    }
    else if(Result==1 && UserLogin==true && User_Role=="admin"){
      HomeScreen=AdminHomeScreen(User_Role: User_Role, User_JwtToken:User_JwtToken, User_Email:User_Email, User_Number: User_Number,);
    }
    else if(Result==1 && UserLogin==true && User_Role=="user"){
      HomeScreen=HomeScreenUi(User_JwtToken:User_JwtToken,UserLogin: true,);
    }
    else if(Result==1 && UserLogin==true && User_Role=="provider"){
      HomeScreen=HomeScreenUi(User_JwtToken:User_JwtToken,UserLogin:true);
    }
    else
    {
     HomeScreen= ErrorPage();
    }
    return
      MultiBlocProvider(
        providers:
        [
          BlocProvider (
            create: (BuildContext context) {
              return CommonVariableBloc();
            },
          ),
        ],
        child: GetMaterialApp(
    debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home:HomeScreen
            ),
      );



  }



}


