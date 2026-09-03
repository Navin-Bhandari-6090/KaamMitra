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
import '../common widget/getx_cont_pick_single_photo_int.dart';

import '../common widget/single_video_pick_getx.dart';
import '../common widget/toast.dart';

class ProviderAddSeviceResources extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  const ProviderAddSeviceResources({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});

  @override
  State<ProviderAddSeviceResources> createState() => _ProviderAddSeviceResourcesState();
}

class _ProviderAddSeviceResourcesState extends State<ProviderAddSeviceResources> {
  final Toast = Toastget();
  final change_photo_cont_getx = Get.put(pick_single_photo_getx_int());
  final change_video_cont_getx = Get.put(PickSingleVideoController());
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
      await Clear_User_Data();
      await Random_token_Clear();
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => ErrorPage()
          )
      );
      Toastget().Toastmsg("Session End.Relogin please.");
      return;
    }
  }
  Future<int> AddServiceResources({
    required List<int> ImageBytes,
    required List<int> VideoBytes,
    required String SeviceId,
    required String PhotoExtension,
    required String VideoExtension,
  }) async {
    try {
      // =========================================================
      // 1. Validate photo
      // =========================================================

      if (ImageBytes.isEmpty) {
        Toast.Toastmsg(
          'Photo data is required',
        );

        print(
          'Photo data is required',
        );

        return 1;
      }

      // =========================================================
      // 2. Validate video
      // =========================================================

      if (VideoBytes.isEmpty) {
        Toast.Toastmsg(
          'Video data is required',
        );

        print(
          'Video data is required',
        );

        return 2;
      }

      // =========================================================
      // 3. Validate service ID
      // =========================================================

      if (SeviceId.trim().isEmpty) {
        Toast.Toastmsg(
          'ServiceId is required',
        );

        print(
          'ServiceId is required',
        );

        return 3;
      }

      // =========================================================
      // 4. Convert service ID
      // =========================================================

      final int? serviceId =
      int.tryParse(SeviceId.trim());

      if (serviceId == null || serviceId <= 0) {
        Toast.Toastmsg(
          'Invalid ServiceId',
        );

        print(
          'Invalid ServiceId: $SeviceId',
        );

        return 3;
      }

      // =========================================================
      // 5. Validate photo extension
      // =========================================================

      final String photoExtension =
      PhotoExtension
          .trim()
          .toLowerCase()
          .replaceFirst('.', '');

      if (photoExtension.isEmpty) {
        Toast.Toastmsg(
          'Photo extension is required',
        );

        print(
          'Photo extension is required',
        );

        return 4;
      }

      // =========================================================
      // 6. Validate video extension
      // =========================================================

      final String videoExtension =
      VideoExtension
          .trim()
          .toLowerCase()
          .replaceFirst('.', '');

      if (videoExtension.isEmpty) {
        Toast.Toastmsg(
          'Video extension is required',
        );

        print(
          'Video extension is required',
        );

        return 5;
      }

      // =========================================================
      // 7. Print information
      // =========================================================

      print(
        "========== ADD SERVICE RESOURCES ==========",
      );

      print(
        "Email: ${widget.User_Email}",
      );

      print(
        "ProviderServiceId: $serviceId",
      );

      print(
        "Photo Size: ${ImageBytes.length} bytes",
      );

      print(
        "Video Size: ${VideoBytes.length} bytes",
      );

      print(
        "Photo Extension: $photoExtension",
      );

      print(
        "Video Extension: $videoExtension",
      );

      // =========================================================
      // 8. API URL
      // =========================================================

      const String url =
          Backend_Server_Url +
              "api/Profile/addserviceresources";

      print(
        "API URL: $url",
      );

      // =========================================================
      // 9. Create multipart request
      // =========================================================

      final request = http.MultipartRequest(
        "POST",
        Uri.parse(url),
      );

      // =========================================================
      // 10. Authorization
      // =========================================================

      request.headers["Authorization"] =
      "Bearer ${widget.User_JwtToken}";

      // =========================================================
      // 11. Normal form fields
      // =========================================================

      request.fields["ProviderServiceId"] =
          serviceId.toString();

      request.fields["Email"] =
          widget.User_Email;

      request.fields["PhotoExtension"] =
          photoExtension;

      request.fields["VideoExtension"] =
          videoExtension;

      // =========================================================
      // 12. Add photo
      // =========================================================

      request.files.add(
        http.MultipartFile.fromBytes(
          "ServicePhoto",
          ImageBytes,
          filename: "service_photo.$photoExtension",
        ),
      );

      // =========================================================
      // 13. Add video
      // =========================================================

      request.files.add(
        http.MultipartFile.fromBytes(
          "ServiceVideo",
          VideoBytes,
          filename: "service_video.$videoExtension",
        ),
      );

      // =========================================================
      // 14. Print multipart information
      // =========================================================

      print(
        "Multipart request created.",
      );

      print(
        "Photo filename: service_photo.$photoExtension",
      );

      print(
        "Video filename: service_video.$videoExtension",
      );

      print(
        "Uploading service resources...",
      );

      // =========================================================
      // 15. Send request
      // =========================================================

      final streamedResponse =
      await request.send();

      // =========================================================
      // 16. Convert response
      // =========================================================

      final response =
      await http.Response.fromStream(
        streamedResponse,
      );

      // =========================================================
      // 17. Print response
      // =========================================================

      print(
        "Response status: ${response.statusCode}",
      );

      print(
        "Response body: ${response.body}",
      );

      // =========================================================
      // 18. Success
      // =========================================================

      if (response.statusCode == 200) {
        Toast.Toastmsg(
          'Add service resources success.',
        );

        print(
          'Add service resources success.',
        );

        return 1;
      }

      // =========================================================
      // 19. Bad request
      // =========================================================

      if (response.statusCode == 400) {
        Toast.Toastmsg(
          response.body,
        );

        print(
          "Bad request: ${response.body}",
        );

        return 4;
      }

      // =========================================================
      // 20. Service not found
      // =========================================================

      if (response.statusCode == 404) {
        Toast.Toastmsg(
          response.body,
        );

        print(
          "Service not found: ${response.body}",
        );

        return 5;
      }

      // =========================================================
      // 21. Unauthorized
      // =========================================================

      if (response.statusCode == 401) {
        Toast.Toastmsg(
          "Unauthorized. Please login again.",
        );

        print(
          "Unauthorized.",
        );

        return 6;
      }

      // =========================================================
      // 22. Forbidden
      // =========================================================

      if (response.statusCode == 403) {
        Toast.Toastmsg(
          "You are not authorized.",
        );

        print(
          "Forbidden.",
        );

        return 7;
      }

      // =========================================================
      // 23. Server error
      // =========================================================

      if (response.statusCode == 500) {
        Toast.Toastmsg(
          "Server error while adding service resources.",
        );

        print(
          "Server error: ${response.body}",
        );

        return 8;
      }

      // =========================================================
      // 24. Other status
      // =========================================================

      print(
        "Unexpected status code: ${response.statusCode}",
      );

      Toast.Toastmsg(
        'Add service resources failed.',
      );

      return 9;
    } catch (E) {
      // =========================================================
      // 25. Exception
      // =========================================================

      print(
        "Exception caught while adding service resources.",
      );

      print(
        E.toString(),
      );

      Toast.Toastmsg(
        'Add service resources failed.',
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
      appBar:AppBar(
        title: Text("Add service resources"),
        centerTitle: true,
      ),
      body: Container(
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

            SizedBox(height: shortestval * 0.02),
            ElevatedButton(onPressed: ()async{
              try{
                int PhotoResult = await change_photo_cont_getx.pickImage();
                if(PhotoResult==1){
                  Toast.Toastmsg("Pick photo for service resources success.");
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

            ElevatedButton(onPressed: ()async{
              try{
                int PhotoResult = await change_video_cont_getx.pickVideo();
                if(PhotoResult==1){
                  Toast.Toastmsg("Pick video for service resources success.");
                  return;
                }
                else{
                  Toast.Toastmsg("Pick video for service resources fail.");
                  return;
                }

              }catch(e){
                Toast.Toastmsg("Pick photo for service resources fail.");
                return;
              }

            },
                child: Text("Pick video for service resources")),

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
                  if (change_video_cont_getx.videoBytes.value != null  && change_photo_cont_getx.imageBytes.value != null )
                  {
                    int Result = await AddServiceResources(
                        ImageBytes: change_photo_cont_getx.imageBytes.value!,
                        VideoBytes:change_video_cont_getx.videoBytes.value! ,
                        SeviceId:ProviderServiceIdCont.text.trim(),
                        PhotoExtension: change_photo_cont_getx.imageExtension.value!,
                        VideoExtension: change_video_cont_getx.videoExtension.value!
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
                "Add resources on service",
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
