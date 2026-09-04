import 'package:flutter/material.dart';

import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';


import 'package:http/http.dart' as http;
import '../../constant/Server_Database.dart';
import '../../constant/Style.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/getx_cont_pick_single_photo_int.dart';
import '../common widget/toast.dart';

class ProUpdateSerResPhotoScreen extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  const ProUpdateSerResPhotoScreen({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});

  @override
  State<ProUpdateSerResPhotoScreen> createState() => _ProUpdateSerResPhotoScreenState();
}

class _ProUpdateSerResPhotoScreenState extends State<ProUpdateSerResPhotoScreen> {
  final Toast = Toastget();
  final change_photo_cont_getx = Get.put(pick_single_photo_getx_int());
  final TextEditingController ProviderServiceIdCont=TextEditingController();
  final TextEditingController ProviderServiceResIdCont=TextEditingController();

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
      await Clear_User_Data();
      await Random_token_Clear();
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => ErrorPage()
          )
      );
      Toast.Toastmsg("Session End.Relogin please.");
      return;
    }
  }


  Future<int> UpdateServiceResourcesPhoto({
    required List<int> ImageBytes,
    required String ImageExtension,
    required String ServiceResourcesId,
    required String ProviderServiceId,
  }) async {
    try {
      // =====================================================
      // 1. Validate image bytes
      // =====================================================

      if (ImageBytes.isEmpty) {
        Toast.Toastmsg(
          'Photo data is required.',
        );

        print('Photo data is required.');

        return 1;
      }

      // =====================================================
      // 2. Validate resource ID
      // =====================================================

      if (ServiceResourcesId.trim().isEmpty) {
        Toast.Toastmsg(
          'Service resource ID is required.',
        );

        print(
          'Service resource ID is required.',
        );

        return 1;
      }

      // =====================================================
      // 3. Validate provider service ID
      // =====================================================

      if (ProviderServiceId.trim().isEmpty) {
        Toast.Toastmsg(
          'Provider service ID is required.',
        );

        print(
          'Provider service ID is required.',
        );

        return 1;
      }

      // =====================================================
      // 4. Validate extension
      //
      // You said frontend already validates it.
      // We only use it to create the filename.
      // =====================================================

      if (ImageExtension.trim().isEmpty) {
        Toast.Toastmsg(
          'Image extension is required.',
        );

        print(
          'Image extension is required.',
        );

        return 1;
      }

      // =====================================================
      // 5. Validate Email
      // =====================================================

      if (widget.User_Email.trim().isEmpty) {
        Toast.Toastmsg(
          'Email is required.',
        );

        print(
          'Email is required.',
        );

        return 1;
      }

      // =====================================================
      // 6. API URL
      // =====================================================

      const String url =
          Backend_Server_Url +
              "api/Profile/updateserviceresourcesphoto";

      // =====================================================
      // 7. Create Multipart Request
      // =====================================================

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse(url),
      );

      // =====================================================
      // 8. Authorization
      // =====================================================

      request.headers['Authorization'] =
      'Bearer ${widget.User_JwtToken}';

      // =====================================================
      // 9. Add normal fields
      // =====================================================

      request.fields['ProviderServiceResourcesId'] =
          ServiceResourcesId.trim();

      request.fields['ProviderServiceId'] =
          ProviderServiceId.trim();

      request.fields['Email'] =
          widget.User_Email.trim();

      // =====================================================
      // 10. Add image file
      // =====================================================

      request.files.add(
        http.MultipartFile.fromBytes(
          'ServicePhoto',
          ImageBytes,
          filename:
          'service_photo.${ImageExtension.trim().toLowerCase()}',
        ),
      );

      // =====================================================
      // 11. Debug information
      // =====================================================

      print('==========================================');
      print('UPDATE SERVICE RESOURCE PHOTO');
      print('==========================================');
      print('URL: $url');
      print(
        'Resource ID: ${ServiceResourcesId.trim()}',
      );
      print(
        'Provider Service ID: ${ProviderServiceId.trim()}',
      );
      print(
        'Email: ${widget.User_Email.trim()}',
      );
      print(
        'Image Extension: ${ImageExtension.trim()}',
      );
      print(
        'Image Bytes: ${ImageBytes.length}',
      );
      print('==========================================');

      // =====================================================
      // 12. Send request
      // =====================================================

      final streamedResponse =
      await request.send();

      // =====================================================
      // 13. Convert response
      // =====================================================

      final response =
      await http.Response.fromStream(
        streamedResponse,
      );

      print(
        'Update resource photo status: '
            '${response.statusCode}',
      );

      print(
        'Update resource photo response: '
            '${response.body}',
      );

      // =====================================================
      // 14. Success
      // =====================================================

      if (response.statusCode == 200) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : 'Service resource photo updated successfully.',
        );

        print(
          'Service resource photo updated successfully.',
        );

        return 1;
      }

      // =====================================================
      // 15. Bad data
      // =====================================================

      else if (response.statusCode == 400) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : 'Data are not in correct format.',
        );

        print(
          'Update resource photo failed - 400: '
              '${response.body}',
        );

        return 3;
      }

      // =====================================================
      // 16. Unauthorized
      // =====================================================

      else if (response.statusCode == 401) {
        Toast.Toastmsg(
          'Unauthorized. Please login again.',
        );

        print(
          'Update resource photo failed - 401: '
              '${response.body}',
        );

        return 4;
      }

      // =====================================================
      // 17. Not found
      // =====================================================

      else if (response.statusCode == 404) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : 'Service resource not found.',
        );

        print(
          'Update resource photo failed - 404: '
              '${response.body}',
        );

        return 5;
      }

      // =====================================================
      // 18. Server error
      // =====================================================

      else if (response.statusCode == 500) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : 'Server error. Please try again.',
        );

        print(
          'Update resource photo failed - 500: '
              '${response.body}',
        );

        return 6;
      }

      // =====================================================
      // 19. Other status codes
      // =====================================================

      else {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : 'Update service resource photo failed.',
        );

        print(
          'Unexpected status code: '
              '${response.statusCode}',
        );

        print(
          'Response: ${response.body}',
        );

        return 2;
      }
    }

    // =======================================================
    // 20. Exception
    // =======================================================

    catch (e) {
      print(
        'UpdateServiceResources exception: $e',
      );

      Toast.Toastmsg(
        'Update service resource photo failed.',
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
        title: Text("Update service resources photo"),
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
                hintText: "Enter service  Id.",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            TextField(
              controller: ProviderServiceResIdCont,
              obscureText: false,
              decoration: InputDecoration(
                hintText: "Enter service resources Id.",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            SizedBox(height: shortestval * 0.02),
            ElevatedButton(onPressed: ()async{
              try{
                int PhotoResult = await change_photo_cont_getx.pickImage();
                if(PhotoResult==1){
                  Toast.Toastmsg("Pick photo for service resources success.");
                  return;
                }
                else if(PhotoResult==2){
                  Toast.Toastmsg("Invalid photo extension(format only jpg,jpeg,png)");
                  return;
                }
                else if(PhotoResult==5){
                  Toast.Toastmsg("Photo is larger than 100 MB.");
                  return;
                }
                else{
                  Toast.Toastmsg("Pick photo for service resources fail.");
                  return;
                }

              }catch(e){
                Toast.Toastmsg("Pick photo for service resources fail.");
                return;
              }

            },
                child: Text("Pick photo for service resources")),

            SizedBox(height: shortestval * 0.02),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(
                    horizontal: shortestval * 0.05, vertical: shortestval * 0.03),
              ),
              onPressed: ()async{
                try {
                  if (change_photo_cont_getx.imageBytes.value != null )
                  {
                    int Result = await UpdateServiceResourcesPhoto(
                      ImageBytes: change_photo_cont_getx.imageBytes.value!,
                        ImageExtension: change_photo_cont_getx.imageExtension.value!,
                        ServiceResourcesId:ProviderServiceIdCont.text.trim() ,
                        ProviderServiceId: ProviderServiceIdCont.text.trim(),
                    );
                    if (Result == 1)
                    {
                      return;
                    }
                    else
                    {
                      return;
                    }
                  }
                  else{
                    Toast.Toastmsg("Pick photo(.png,.jpg,.jpeg) and video(.mp4) in correct format and then try again.");
                    return;
                  }

                }catch (exception)
                {
                  return;
                }
              },
              child:Text(
                "Update resources.",
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
