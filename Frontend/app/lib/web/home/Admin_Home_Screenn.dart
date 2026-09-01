import 'package:flutter/material.dart';

class AdminHomeScreen extends StatefulWidget {
  final String User_Role;
  final String User_JwtToken;
  final String User_Email;
  const AdminHomeScreen({super.key, required this.User_Role, required this.User_JwtToken, required this.User_Email});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(

    );
  }
}
