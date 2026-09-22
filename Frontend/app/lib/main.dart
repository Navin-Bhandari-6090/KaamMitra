import 'package:app/state%20management/bloc/common%20state/common_variable_bloc.dart';
import 'package:app/web/authentication/Error_page.dart';
import 'package:app/web/authentication/Login.dart';
import 'package:app/web/common%20method/Commmon_Method.dart';
import 'package:app/web/home/Admin_Home_Screenn.dart';
import 'package:app/web/home/Home_Screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  try{
  WidgetsFlutterBinding.ensureInitialized();
  // await Hive.initFlutter();
  // await Clear_User_Data();
  // await Random_token_Clear();
  // print("mainLogout Success");
 int UserData=await CheckUserJwtToken();
  print("User data token result = ${UserData}");
 if(UserData==1)
 {
   final box = await Hive.openBox('User_Data');
   String? Jwt_Token = box.get('jwt_token');
   String? User_Role = box.get('user_role');
   String? User_Email=box.get('user_email');
   int AllUserVerify=await AllUserJwtVerify(Jwt_Token:Jwt_Token!);
   if(AllUserVerify==1)
   {
     runApp(MyApp(Result: 1,UserLogin: true, User_JwtToken: Jwt_Token!, User_Role:User_Role!, User_Email:User_Email!,));
   }
   else
   {
     print("Random token generate start");
     await GenerateRandomToken();
     int Result = await CheckRandomJwtToken();
     print("Random token result = ${Result}");
     final box = await Hive.openBox('Random_Token');
     String? Jwt_Token = box.get('random_token');
     runApp(MyApp(Result: 1,UserLogin: false, User_JwtToken:Jwt_Token!, User_Role:"", User_Email: '',));
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
     runApp(MyApp(Result: 1,UserLogin: false, User_JwtToken:Jwt_Token!, User_Role:"", User_Email: '',));
 }
 }catch(e){
    runApp(MyApp(Result: 0,UserLogin: false, User_JwtToken:"", User_Role: "", User_Email: '',));
  }
 }

class MyApp extends StatelessWidget {
   final int? Result;
   final bool UserLogin;
   final String User_Role;
   final String User_JwtToken;
   final String User_Email;
   const MyApp({super.key,required this.Result,required this.UserLogin, required this.User_JwtToken, required this.User_Role, required this.User_Email});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Widget HomeScreen;
    if(Result==1 && UserLogin==false)
    {
      HomeScreen=HomeScreenUi(UserLogin: false, User_JwtToken:User_JwtToken,);
    }
    else if(Result==1 && UserLogin==true && User_Role=="Admin"){
      HomeScreen=AdminHomeScreen(User_Role: User_Role, User_JwtToken:User_JwtToken, User_Email:User_Email,);
    }
    else if(Result==1 && UserLogin==true && User_Role=="User"){
      HomeScreen=HomeScreenUi(User_JwtToken:User_JwtToken,UserLogin: true,);
    }
    else if(Result==1 && UserLogin==true && User_Role=="Provider"){
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


