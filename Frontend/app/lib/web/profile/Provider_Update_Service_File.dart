import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';

import '../../constant/Server_Database.dart';
import '../../constant/Style.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/single_file_pick_getx_cont.dart';
import '../common widget/toast.dart';

class ProviderUpdateServiceFile extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  const ProviderUpdateServiceFile({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});

  @override
  State<ProviderUpdateServiceFile> createState() => _ProviderUpdateServiceFileState();
}

class _ProviderUpdateServiceFileState extends State<ProviderUpdateServiceFile> {
  final Toast = Toastget();
  final change_file_cont_getx = Get.put(FilePickerController());
  final TextEditingController ProviderServiceIdCont=TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider_Jwt_Verify(Jwt_Token: widget.User_JwtToken);
  }

  Future<void> Provider_Jwt_Verify({required String Jwt_Token}) async
  {
    int Result = await ProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result == 1) {
      return;
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => ErrorPage()
          )
      );
      Toast.Toastmsg("Session End.Relogin please.");
      return;
    }
  }


  Future<int> UpdateServiceFile({required FileBytes,required String ServiceId}) async {
    try {
      final String base64File = base64Encode(FileBytes as List<int>);

      if (base64File.isEmptyOrNull) {
        Toast.Toastmsg('File data is required');
        print('File data  is required');
        return 1;
      }

      if (ServiceId.isEmptyOrNull) {
        Toast.Toastmsg('Service id is required');
        print('Service id is required');
        return 1;
      }


      // All fields valid
      final Map<String, dynamic> ServiceData = {
        "ServiceDocument":base64File,
        "Email":widget.User_Email,
        "ProviderServiceId":ProviderServiceIdCont.text.trim()
      };

      const String url = Backend_Server_Url + "api/Profile/updateservicedocument";

      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.User_JwtToken}'
        },
        body: json.encode(ServiceData),
      );

      if (response.statusCode == 200) {
        Toast.Toastmsg('Update service success.');
        print('Update service success.');
        return 1;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg('Update service fail.Data are not in correct format.');
        print('Update service fail.Data are not in correct format.');
        return 3;
      }
      else {
        print("else status code = ${response.statusCode}");
        Toast.Toastmsg(
            'Update service fail.'
        );
        print('Update service fail.');
        return 2;
      }
    } catch (E) {
      Toast.Toastmsg('Update service fail.');
      print('Update service fail.');
      return 0;
    }
  }
  @override
  Widget build(BuildContext context) {
    var shortestval = MediaQuery
        .of(context)
        .size
        .shortestSide;
    var widthval = MediaQuery
        .of(context)
        .size
        .width;
    var heightval = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Update service file"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children:
          [

            TextField(
              controller: ProviderServiceIdCont,
              obscureText: false,
              decoration: InputDecoration(
                hintText: "Enter service Id.",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(
                    horizontal: shortestval * 0.05,
                    vertical: shortestval * 0.03),
              ),
              onPressed: () async {
                try {
                  int Result = await change_file_cont_getx.pickFile();
                  if (Result == 1) {
                    int Result = await UpdateServiceFile(
                        FileBytes: change_file_cont_getx.fileBytes.value, ServiceId: '${ProviderServiceIdCont.text.trim()}');
                    if (Result == 1) {
                      return;
                    }
                    else {
                      return;
                    }
                  }
                  else {
                    return;
                  }
                } catch (exception) {
                  return;
                }
              },
              child: Text(
                "Update service",
                style: TextStyle(
                    fontFamily: semibold,
                    color: Colors.white,
                    fontSize: shortestval * 0.04),
              ),
            ),



          ],
        ),
      ),
    );
  }
}
