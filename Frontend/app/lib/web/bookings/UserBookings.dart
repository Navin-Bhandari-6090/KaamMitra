import 'package:flutter/material.dart';

class MyBookingScreenUser extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  const MyBookingScreenUser({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});

  @override
  State<MyBookingScreenUser> createState() => _MyBookingScreenUserState();
}

class _MyBookingScreenUserState extends State<MyBookingScreenUser> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Profile Screen User"),
          centerTitle: true,
        ),
        body:Container(

        )
    );
  }
}
