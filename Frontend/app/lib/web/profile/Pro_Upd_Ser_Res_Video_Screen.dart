import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';

import 'package:http/http.dart' as http;
import '../../constant/Server_Database.dart';
import '../../constant/Style.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/single_video_pick_getx.dart';
import '../common widget/toast.dart';

class ProUpdSerResVideoScreen extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  const ProUpdSerResVideoScreen({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});

  @override
  State<ProUpdSerResVideoScreen> createState() => _ProUpdSerResVideoScreenState();
}

class _ProUpdSerResVideoScreenState extends State<ProUpdSerResVideoScreen> {
  final Toast = Toastget();
  final change_video_cont_getx = Get.put(PickSingleVideoController());
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



  Future<int> UpdateServiceResourcesVideo({
    required List<int> VideoBytes,
    required String ServiceResourcesId,
    required String ProviderServiceId,
    required String VideoExtension,
  }) async {
    try {
      // =========================================================
      // 1. Validate video
      // =========================================================

      if (VideoBytes.isEmpty) {
        Toast.Toastmsg(
          "Video data is required.",
        );

        print(
          "Video data is required.",
        );

        return 1;
      }

      // =========================================================
      // 2. Validate ServiceResourcesId
      // =========================================================

      if (ServiceResourcesId.trim().isEmpty) {
        Toast.Toastmsg(
          "Service resource ID is required.",
        );

        print(
          "Service resource ID is required.",
        );

        return 2;
      }

      // =========================================================
      // 3. Convert ServiceResourcesId
      // =========================================================

      final int? serviceResourcesId =
      int.tryParse(
        ServiceResourcesId.trim(),
      );

      if (serviceResourcesId == null ||
          serviceResourcesId <= 0) {
        Toast.Toastmsg(
          "Invalid service resource ID.",
        );

        print(
          "Invalid service resource ID: $ServiceResourcesId",
        );

        return 2;
      }

      // =========================================================
      // 4. Validate ProviderServiceId
      // =========================================================

      if (ProviderServiceId.trim().isEmpty) {
        Toast.Toastmsg(
          "Provider service ID is required.",
        );

        print(
          "Provider service ID is required.",
        );

        return 3;
      }

      // =========================================================
      // 5. Convert ProviderServiceId
      // =========================================================

      final int? providerServiceId =
      int.tryParse(
        ProviderServiceId.trim(),
      );

      if (providerServiceId == null ||
          providerServiceId <= 0) {
        Toast.Toastmsg(
          "Invalid provider service ID.",
        );

        print(
          "Invalid provider service ID: $ProviderServiceId",
        );

        return 3;
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
          "Video extension is required.",
        );

        print(
          "Video extension is required.",
        );

        return 4;
      }

      // =========================================================
      // 7. Validate Email
      // =========================================================

      if (widget.User_Email.trim().isEmpty) {
        Toast.Toastmsg(
          "Email is required.",
        );

        print(
          "Email is required.",
        );

        return 5;
      }

      // =========================================================
      // 8. Print information
      // =========================================================

      print(
        "==========================================",
      );

      print(
        "UPDATE SERVICE RESOURCE VIDEO",
      );

      print(
        "==========================================",
      );

      print(
        "Email: ${widget.User_Email}",
      );

      print(
        "ProviderServiceId: $providerServiceId",
      );

      print(
        "ProviderServiceResourcesId: $serviceResourcesId",
      );

      print(
        "Video Size: ${VideoBytes.length} bytes",
      );

      print(
        "Video Extension: $videoExtension",
      );

      // =========================================================
      // 9. API URL
      // =========================================================

      const String url =
          Backend_Server_Url +
              "api/Profile/updateserviceresourcesvideo";

      print(
        "API URL: $url",
      );

      // =========================================================
      // 10. Create Multipart Request
      // =========================================================

      final request = http.MultipartRequest(
        "PUT",
        Uri.parse(url),
      );

      // =========================================================
      // 11. Authorization
      // =========================================================

      request.headers["Authorization"] =
      "Bearer ${widget.User_JwtToken}";

      // =========================================================
      // 12. Add normal form fields
      // =========================================================

      request.fields["ProviderServiceResourcesId"] =
          serviceResourcesId.toString();

      request.fields["ProviderServiceId"] =
          providerServiceId.toString();

      request.fields["Email"] =
          widget.User_Email.trim();

      // =========================================================
      // 13. Add video file
      // =========================================================

      request.files.add(
        http.MultipartFile.fromBytes(
          "ServiceVideo",
          VideoBytes,
          filename:
          "service_video.$videoExtension",
        ),
      );

      // =========================================================
      // 14. Print upload information
      // =========================================================

      print(
        "Multipart request created.",
      );

      print(
        "Video filename: service_video.$videoExtension",
      );

      print(
        "Uploading service resource video...",
      );

      // =========================================================
      // 15. Send request
      // =========================================================

      final streamedResponse =
      await request.send();

      // =========================================================
      // 16. Convert streamed response
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
          response.body.isNotEmpty
              ? response.body
              : "Service resource video updated successfully.",
        );

        print(
          "Service resource video updated successfully.",
        );

        return 1;
      }

      // =========================================================
      // 19. Bad request
      // =========================================================

      if (response.statusCode == 400) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : "Data are not in correct format.",
        );

        print(
          "Bad request: ${response.body}",
        );

        return 4;
      }

      // =========================================================
      // 20. Unauthorized
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
      // 21. Forbidden
      // =========================================================

      if (response.statusCode == 403) {
        Toast.Toastmsg(
          "You are not authorized to update this resource.",
        );

        print(
          "Forbidden.",
        );

        return 7;
      }

      // =========================================================
      // 22. Resource not found
      // =========================================================

      if (response.statusCode == 404) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : "Service resource not found.",
        );

        print(
          "Service resource not found: ${response.body}",
        );

        return 5;
      }

      // =========================================================
      // 23. Server error
      // =========================================================

      if (response.statusCode == 500) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : "Server error while updating service resource video.",
        );

        print(
          "Server error: ${response.body}",
        );

        return 8;
      }

      // =========================================================
      // 24. Unexpected status code
      // =========================================================

      print(
        "Unexpected status code: ${response.statusCode}",
      );

      print(
        "Response: ${response.body}",
      );

      Toast.Toastmsg(
        "Update service resource video failed.",
      );

      return 9;
    } catch (e) {
      // =========================================================
      // 25. Exception
      // =========================================================

      print(
        "Exception caught while updating service resource video.",
      );

      print(
        "Exception: $e",
      );

      Toast.Toastmsg(
        "Update service resource video failed.",
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
        title: const Text("Update Service Resources Video"),
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
                int VideoResult = await change_video_cont_getx.pickVideo();
                if(VideoResult==1){
                  Toast.Toastmsg("Pick video for service resources success.");
                  return;
                }
                else if(VideoResult==3){
                  Toast.Toastmsg("Invalid video extension(format only .mp4)");
                  return;
                }
                else if(VideoResult==2){
                  Toast.Toastmsg("Video is larger than 1 GB.");
                  return;
                }
                else{
                  Toast.Toastmsg("Pick Video for service resources fail.");
                  return;
                }

              }catch(e){
                Toast.Toastmsg("Pick Video for service resources fail.");
                return;
              }

            },
                child: Text("Pick Video for service resources")),

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
                  if (change_video_cont_getx.videoBytes.value != null )
                  {
                    int Result = await UpdateServiceResourcesVideo(
                      VideoBytes: change_video_cont_getx.videoBytes.value!,
                      ServiceResourcesId:ProviderServiceIdCont.text.trim() ,
                      ProviderServiceId: ProviderServiceIdCont.text.trim(),
                      VideoExtension: change_video_cont_getx.videoExtension.value!,
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
