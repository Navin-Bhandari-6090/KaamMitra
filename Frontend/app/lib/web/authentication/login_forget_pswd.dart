import 'package:flutter/material.dart';

import '../common method/Commmon_Method.dart';

class LogForPswd extends StatefulWidget {
  final String User_JwtToken;
  const LogForPswd({super.key, required this.User_JwtToken});
  @override
  State<LogForPswd> createState() => _LogForPswdState();
}

class _LogForPswdState extends State<LogForPswd>
{
  
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Random_Jwt_Verify(Jwt_Token:widget.User_JwtToken, context: context);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Forget password"),
        centerTitle: true,
      ),
      body:   SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        child: Column(
          children:
          [



          ],
        ),
      ),
    );
  }
}
