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

class ProviderUpdateServiceResources extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;

  const ProviderUpdateServiceResources({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});

  @override
  State<ProviderUpdateServiceResources> createState() => _ProviderUpdateServiceResourcesState();
}

class _ProviderUpdateServiceResourcesState extends State<ProviderUpdateServiceResources> {
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
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => ErrorPage()
          )
      );
      Toast.Toastmsg("Session End.Relogin please.");
      return;
    }
  }



  Future<int> UpdateServiceResources({required ImageBytes,required VideoBytes,required String SeviceResourcesId}) async {
    try {

      final String base64Photo = base64Encode(ImageBytes as List<int>);
      final String base64Video = base64Encode(VideoBytes as List<int>);

      if (base64Photo.isEmptyOrNull) {
        Toast.Toastmsg('Photo data is required');
        print('Photo data  is required');
        return 1;
      }
      if (base64Video.isEmptyOrNull) {
        Toast.Toastmsg('Video is required');
        print('Video is required');
        return 2;
      }
      if (SeviceResourcesId.isEmptyOrNull) {
        Toast.Toastmsg('SeviceId is required');
        print('SeviceId is required');
        return 2;
      }


      // All fields valid
      final Map<String, dynamic> ServiceData = {
        "ServicePhoto": base64Photo,
        "ServiceVideo":base64Video,
        "ProviderServiceResourcesId":SeviceResourcesId,
        "Email":widget.User_Email
      };

      final String url = Backend_Server_Url + "api/Profile/updateserviceresources";

      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.User_JwtToken}'
        },
        body: json.encode(ServiceData),
      );

      if (response.statusCode == 200) {
        Toast.Toastmsg('Update service resources success.');
        print('Update service resources success.');
        return 1;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg('Update service resources fail.Data are not in correct format.');
        print('Update service resources fail.Data are not in correct format.');
        return 3;
      }
      else if (response.statusCode == 502) {
        Toast.Toastmsg('Update service resources fail.Service ID not register.Use correct.');
        print('Update service resources fail.Service ID not register.Use correct.');
        return 3;
      }
      else {
        print("else status code = ${response.statusCode}");
        Toast.Toastmsg(
            'Update service resources fail.'
        );
        print('Update service resources fail.');
        return 2;
      }
    } catch (E) {
      Toast.Toastmsg('Update service resources fail.');
      print('Update service resources fail.');
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
        title: Text("Update service resources"),
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
                    int Result = await UpdateServiceResources(ImageBytes: change_photo_cont_getx.imageBytes.value,
                        VideoBytes:change_video_cont_getx.videoBytes.value ,
                         SeviceResourcesId: ProviderServiceIdCont.text.trim());
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
