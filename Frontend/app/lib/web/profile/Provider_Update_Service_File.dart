

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:http/http.dart' as http;

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


  Future<int> UpdateServiceFile({
    required List<int> FileBytes,
    required String ServiceId,
  }) async {
    try {
      // =====================================================
      // 1. Validate file
      // =====================================================

      if (FileBytes.isEmpty) {
        Toast.Toastmsg('File data is required');
        print('File data is required');
        return 1;
      }

      // =====================================================
      // 2. Validate service ID
      // =====================================================

      if (ServiceId.trim().isEmpty) {
        Toast.Toastmsg('Service id is required');
        print('Service id is required');
        return 1;
      }

      // =====================================================
      // 3. Validate email
      // =====================================================

      if (widget.User_Email.trim().isEmpty) {
        Toast.Toastmsg('Email is required');
        print('Email is required');
        return 1;
      }

      // =====================================================
      // 4. API URL
      // =====================================================

      const String url =
          Backend_Server_Url +
              "api/Profile/updateservicedocument";

      // =====================================================
      // 5. Create multipart request
      // =====================================================

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse(url),
      );

      // =====================================================
      // 6. Authorization
      // =====================================================

      request.headers['Authorization'] =
      'Bearer ${widget.User_JwtToken}';

      // =====================================================
      // 7. Add normal form fields
      // =====================================================

      request.fields['Email'] =
          widget.User_Email.trim();

      request.fields['ProviderServiceId'] =
          ServiceId.trim();

      // =====================================================
      // 8. Add PDF file
      // =====================================================

      request.files.add(
        http.MultipartFile.fromBytes(
          'ServiceDocument',
          FileBytes,
          filename: 'service_document.pdf',
          contentType: http.MediaType(
            'application',
            'pdf',
          ),
        ),
      );

      // =====================================================
      // 9. Debug information
      // =====================================================

      print('==========================================');
      print('UPDATE SERVICE DOCUMENT');
      print('==========================================');
      print('URL: $url');
      print('Email: ${widget.User_Email}');
      print('Service ID: ${ServiceId.trim()}');
      print('File bytes: ${FileBytes.length}');
      print('==========================================');

      // =====================================================
      // 10. Send request
      // =====================================================

      final streamedResponse = await request.send();

      // =====================================================
      // 11. Convert streamed response
      // =====================================================

      final response =
      await http.Response.fromStream(streamedResponse);

      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');

      // =====================================================
      // 12. Success
      // =====================================================

      if (response.statusCode == 200) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : 'Service document updated successfully.',
        );

        print('Update service success.');

        return 1;
      }

      // =====================================================
      // 13. Bad data
      // =====================================================

      else if (response.statusCode == 400) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : 'Data are not in correct format.',
        );

        print(
          'Update service failed - 400: ${response.body}',
        );

        return 3;
      }

      // =====================================================
      // 14. Unauthorized
      // =====================================================

      else if (response.statusCode == 401) {
        Toast.Toastmsg(
          'Unauthorized. Please login again.',
        );

        print(
          'Update service failed - 401: ${response.body}',
        );

        return 4;
      }

      // =====================================================
      // 15. Not found
      // =====================================================

      else if (response.statusCode == 404) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : 'User or service not found.',
        );

        print(
          'Update service failed - 404: ${response.body}',
        );

        return 5;
      }

      // =====================================================
      // 16. Server error
      // =====================================================

      else if (response.statusCode == 500) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : 'Server error. Please try again.',
        );

        print(
          'Update service failed - 500: ${response.body}',
        );

        return 6;
      }

      // =====================================================
      // 17. Other status codes
      // =====================================================

      else {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : 'Update service failed.',
        );

        print(
          'Unexpected status code: ${response.statusCode}',
        );

        print(
          'Response: ${response.body}',
        );

        return 2;
      }
    }

    // =======================================================
    // 18. Exception
    // =======================================================

    catch (e) {
      print(
        'UpdateServiceFile exception: $e',
      );

      Toast.Toastmsg(
        'Update service failed.',
      );

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
                        FileBytes: change_file_cont_getx.fileBytes.value!, ServiceId: '${ProviderServiceIdCont.text.trim()}');
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
