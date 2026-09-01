import 'package:flutter/material.dart';

class ServicesScreen extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  const ServicesScreen({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Services Screen"),
        centerTitle: true,
      ),
      body:Container()
    );
  }
}
