// import 'package:app/web/common%20method/Commmon_Method.dart';
// import 'package:app/web/common%20widget/GreenTextfield.dart';
// import 'package:flutter/material.dart';
//
// class Test extends StatefulWidget {
//   final String User_JwtToken;
//   const Test({super.key, required this.User_JwtToken});
//
//   @override
//   State<Test> createState() => _TestState();
// }
//
// class _TestState extends State<Test> {
//   final FieldTextCont=TextEditingController();
//   @override
//   void initState() {
//     super.initState();
//     Provider_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Test"),
//       ),
//       body:   SingleChildScrollView(
//         physics: AlwaysScrollableScrollPhysics(),
//         scrollDirection: Axis.vertical,
//         child: Column(
//           children:
//           [
//             GreenField(controller: FieldTextCont, label: "Enter the value", icon: Icons.numbers),
//
//             ElevatedButton(onPressed: ()async{
//               try{
//
//                 if(ServiceIdTextCont.text.trim().isEmptyOrNull){
//                   Toast.Toastmsg("Service id is required.");
//                   return;
//                 }
//
//
//               }catch(obj){
//                 print(obj.toString());
//                 return;
//               }
//
//             }, child: Text("Do.")),
//
//
//           ],
//         ),
//       ),
//     );
//   }
// }
