import 'package:app/web/common%20widget/GreenTextfield.dart';
import 'package:flutter/material.dart';

import '../../models/BookingInfoModel.dart';

class Userbookinginfodetailsscreen extends StatefulWidget {
  final String Current_User_Email;
  final String Current_User_JwtToken;
  final String Current_User_Role;
  final List<BookingInfoModel> BookingInfoListInfo;

  Userbookinginfodetailsscreen({super.key, required this.Current_User_Email, required this.Current_User_JwtToken, required this.Current_User_Role, required this.BookingInfoListInfo});

  @override
  State<Userbookinginfodetailsscreen> createState() => _UserbookinginfodetailsscreenState();
}

class _UserbookinginfodetailsscreenState extends State<Userbookinginfodetailsscreen> {
  final RatingValueCont=TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
        title: const Text("Booking Details"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
          children:
          [

            GreenField(controller: RatingValueCont, label: "Enter rating value", icon: Icons.rate_review_rounded),


          ],
        ),
      ),

    );
  }
}
