import 'package:app/web/advertisement/Advertisement.dart';
import 'package:app/web/bookings/ProviderBookings.dart';
import 'package:app/web/common%20widget/toast.dart';
import 'package:app/web/profile/User_Profile.dart';
import 'package:app/web/services/services.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:velocity_x/velocity_x.dart';
import '../bookings/UserBookings.dart';
import '../home/Home_Screen.dart';
import '../profile/Provider_Profile.dart';

class Header extends StatefulWidget {
  final bool UserLogin;
  final String User_JwtToken;
  const Header({super.key, required this.UserLogin, required this.User_JwtToken});
  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    var shortestval = MediaQuery.of(context).size.shortestSide;
    var widthval = MediaQuery.of(context).size.width;
    var heightval = MediaQuery.of(context).size.height;
    return Container(
      height: heightval*0.10,
      width: widthval,
    color: Colors.blue,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
      [
        Text("Home",style: TextStyle(fontSize: shortestval*0.02,color: Colors.white),).onTap(() {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context){
            return HomeScreenUi(UserLogin:widget.UserLogin, User_JwtToken:widget.User_JwtToken ,);
          }));
        }),

        Text("Services",style: TextStyle(fontSize: shortestval*0.02,color: Colors.white),).onTap(() async {
          try {
            if (widget.UserLogin == true) {
              final box = await Hive.openBox('User_Data');
              String? Jwt_Token = box.get('jwt_token');
              String? User_Email = box.get('user_email');
              String? User_Role = box.get('user_role');
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) {
                  return ServicesScreen(User_Email: User_Email!,
                    User_JwtToken: Jwt_Token!,
                    User_Role: User_Role!,);
                }));
            }
            else
            {
              Toastget().Toastmsg("Please login to use all kind of services.");
            }
          }catch(e)
          {
            Toastget().Toastmsg("Something went wrong.Try again.");
          }

        }),


        Text("Bookings",style: TextStyle(fontSize: shortestval*0.02,color: Colors.white),).onTap(() async {
          try {
            if (widget.UserLogin == true) {
              final box = await Hive.openBox('User_Data');
              String? Jwt_Token = box.get('jwt_token');
              String? User_Email = box.get('user_email');
              String? User_Role = box.get('user_role');
              if (User_Role == "Provider")
              {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) {
                  return ProviderBookingsScreen(User_Email: User_Email!,
                    User_JwtToken: Jwt_Token!,
                    User_Role: User_Role!,);
                }));
              }
              else {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) {
                  return MyBookingScreenUser(User_Email: User_Email!,
                    User_JwtToken: Jwt_Token!,
                    User_Role: User_Role!,);
                }));
              }
            }
            else
            {
              Toastget().Toastmsg("Please login to use all kind of services.");
            }
          }catch(e)
          {
            Toastget().Toastmsg("Something went wrong.Try again.");
          }

        }),

        Text("Profile",style: TextStyle(fontSize: shortestval*0.02,color: Colors.white),).onTap(()async {

          try {
            if (widget.UserLogin == true) {
              final box = await Hive.openBox('User_Data');
              String? Jwt_Token = box.get('jwt_token');
              String? User_Email = box.get('user_email');
              String? User_Role = box.get('user_role');
              print("header token");
              print(Jwt_Token);
              if (User_Role == "Provider")
              {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) {
                  return ProviderProfile(User_Email: User_Email!,
                    User_JwtToken: Jwt_Token!,
                    User_Role: User_Role!,
                    UserLogin: widget.UserLogin,);
                }));
              }
              else {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) {
                  return ProfileScreenUser(User_Email: User_Email!,
                    User_JwtToken: Jwt_Token!,
                    User_Role: User_Role!,
                    UserLogin: widget.UserLogin,);
                }));
              }
            }
            else
            {
              Toastget().Toastmsg("Please login to use all kind of services.");
            }
          }catch(e)
          {
            Toastget().Toastmsg("Something went wrong.Try again.");
          }

        }
        ),


      ],
    ),
    );
  }
}
