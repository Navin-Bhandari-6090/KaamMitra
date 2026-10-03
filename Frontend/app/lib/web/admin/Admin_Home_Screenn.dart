import 'package:app/web/admin/send_notification_user.dart';
import 'package:app/web/admin/update_user_login_access.dart';
import 'package:flutter/material.dart';

import '../../constant/variable.dart';
import 'Booking_pro_task_complete_pay.dart';
import 'add_del_advertisement_screen.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/toast.dart';
import 'add_del_services.dart';
import 'admin_qr.dart';
import 'advance_pay_qr_info.dart';
import 'del_pro_reg_service_res.dart';

class AdminHomeScreen extends StatefulWidget {
  final String User_Role;
  final String User_JwtToken;
  final String User_Email;
  final int User_Number;
  const AdminHomeScreen({super.key, required this.User_Role, required this.User_JwtToken, required this.User_Email, required this.User_Number});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Admin_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Home Screen"),
        centerTitle: true,
      ),

      body:   SingleChildScrollView(
        child: Column(

          children:
          [
            SizedBox(height: 10,),
            ElevatedButton(onPressed: (){

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdvertisementScreen(
                  User_Role: widget.User_Role,
                  User_JwtToken: widget.User_JwtToken,
                  User_Email: widget.User_Email,)

                ),
              );

            }, child: Text("Add/Delete advertisement")),

            SizedBox(height: 10,),

            ElevatedButton(onPressed: (){

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddDelServices(
                  User_Role: widget.User_Role,
                  User_JwtToken: widget.User_JwtToken,
                  User_Email: widget.User_Email,)

                ),
              );

            }, child: Text("Add/Delete services.")),

            SizedBox(height: 10,),

            ElevatedButton(onPressed: (){

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UpdateUserLoginAccess(
                  User_Role: widget.User_Role,
                  User_JwtToken: widget.User_JwtToken,
                  User_Email: widget.User_Email,)

                ),
              );

            }, child: Text("Update user login access..")),

            SizedBox(height: 10,),


            SizedBox(height: 10,),

            ElevatedButton(onPressed: (){

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DelProRegServiceRes(
                  User_Role: widget.User_Role,
                  User_JwtToken: widget.User_JwtToken,
                  User_Email: widget.User_Email,)

                ),
              );

            }, child: Text("Delete provider register service and resources.")),

            SizedBox(height: 10,),

            SizedBox(height: 10,),

            ElevatedButton(onPressed: (){

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdvancePayQrInfo(
                  User_Role: widget.User_Role,
                  User_JwtToken: widget.User_JwtToken,
                  User_Email: widget.User_Email,
                  User_Number: widget.User_Number,)

                ),
              );

            }, child: Text("Advance payment and payment qr info.")),

            SizedBox(height: 10,),

            SizedBox(height: 10,),

            ElevatedButton(onPressed: (){

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminQr(
                  User_Role: widget.User_Role,
                  User_JwtToken: widget.User_JwtToken,
                  User_Email: widget.User_Email,
                  User_Number: widget.User_Number,)

                ),
              );

            }, child: Text("Add Admin QR for provider task complete.")),

            SizedBox(height: 10,),

            ElevatedButton(onPressed: (){

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BookingProTaskCompletePay(
                  User_Role: widget.User_Role,
                  User_JwtToken: widget.User_JwtToken,
                  User_Email: widget.User_Email,
                  User_Number: widget.User_Number,)

                ),
              );

            }, child: Text("Booking and provider task complete payment.")),

            SizedBox(height: 10,),


            ElevatedButton(onPressed: (){

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SendNotificationUser(
                  User_Role: widget.User_Role,
                  User_JwtToken: widget.User_JwtToken,
                  User_Email: widget.User_Email,
                  User_Number: widget.User_Number,)

                ),
              );

            }, child: Text("Send notification to user.")),

            SizedBox(height: 10,),

            ElevatedButton(onPressed: ()async{
              await Clear_User_Data();
              await Random_token_Clear();
              Toast.Toastmsg("Logout Success");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ErrorPage()),
              );
              Toastget().Toastmsg("Session End.Relogin please.");
              return;

            }, child: Text("Logout")),




          ],
        )
      ),

    );
  }
}
