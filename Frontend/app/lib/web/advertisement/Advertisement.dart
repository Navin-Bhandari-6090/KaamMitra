import 'package:flutter/material.dart';

class AdvertisementScreen extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  const AdvertisementScreen({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});

  @override
  State<AdvertisementScreen> createState() => _AdvertisementScreenState();
}

class _AdvertisementScreenState extends State<AdvertisementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Advertisement Screen"),
          centerTitle: true,
        ),
        body:Container()
    );
  }
}
