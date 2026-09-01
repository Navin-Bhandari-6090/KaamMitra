import 'package:flutter/material.dart';

class ProviderBookingsScreen extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  const ProviderBookingsScreen({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Provider Bookings Screen"),
        centerTitle: true,
      ),
      body:Container()
    );
  }
}
