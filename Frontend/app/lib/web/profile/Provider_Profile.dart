import 'dart:convert';
import 'package:app/web/profile/ProviderGallery.dart';
import 'package:app/web/profile/Provider_add_Sevice_Resources.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:http/http.dart' as http;
import '../../constant/Server_Database.dart';
import '../../constant/Style.dart';
import '../../models/UserInfo.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/commonbutton.dart';
import '../common widget/getx_cont_pick_single_photo_int.dart';
import '../common widget/toast.dart';
import '../header/Header.dart';
import 'ProviderAddService.dart';
import 'Provider_Service_Select.dart';
import 'Provider_Update_Service_File.dart';
import 'Provider_Update_Service_Resources.dart';
import 'Update_Password.dart';



class ProviderProfile extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  final bool UserLogin;
  const ProviderProfile({super.key,req, required this.User_Email, required this.User_JwtToken, required this.User_Role, required this.UserLogin});
  @override
  State<ProviderProfile> createState() => _ProviderProfileState();
}

class _ProviderProfileState extends State<ProviderProfile>
{
  final Toast = Toastget();
  final change_photo_cont_getx = Get.put(pick_single_photo_getx_int());


  @override
  void initState() {
    super.initState();
    Provider_Jwt_Verify(Jwt_Token:widget.User_JwtToken);
  }

  Future<void> Provider_Jwt_Verify({required String Jwt_Token})async
  {
    int Result=await ProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result==1)
    {
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


  List<UserInfo> UserInfoModelList = [];
  Future<void> GetUserInfo({required String Email,required String jwttoken}) async {
    try {
      print("profile user info method called");
      const String url = Backend_Server_Url + "api/Profile/getuserinfo";
      Map<String, dynamic> UserDetails = {"Email": Email};
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $jwttoken'
        },
        body: json.encode(UserDetails),
      );
      if (response.statusCode == 200) {
        print("profile user info");
        Map<dynamic, dynamic> responseData = await jsonDecode(response.body);
        UserInfoModelList.clear();
        UserInfoModelList.add(UserInfo.fromJson(responseData));
        return;
      } else {
        UserInfoModelList.clear();
        print("Data insert in userinfo list failed.");
        return;
      }
    } catch (obj) {
      UserInfoModelList.clear();
      print("Exception caught while fetching user data for profile screen");
      print(obj.toString());
      return;
    }
  }

  Future<bool> UpdatePhoto(
      {required String Email,
        required String jwttoken,
        required photo_bytes}) async {
    try {
      final String base64Image = base64Encode(photo_bytes as List<int>);
      const String url = Backend_Server_Url + "api/Profile/updateprofilephoto";
      Map<String, dynamic> new_photo = {
        "Email": Email,
        "Photo": base64Image
      };
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $jwttoken'
        },
        body: json.encode(new_photo),
      );
      if (response.statusCode == 200) {
        print("User authenticated");
        return true;
      } else {
        print("error");
        return false;
      }
    } catch (obj) {
      print("Exception caught while fetching user data for profile screen");
      print(obj.toString());
      return false;
    }
  }



  @override
  Widget build(BuildContext context) {
    var shortestval = MediaQuery.of(context).size.shortestSide;
    var widthval = MediaQuery.of(context).size.width;
    var heightval = MediaQuery.of(context).size.height;
    return Scaffold(
        appBar: AppBar(
          title: const Text("Profile Screen provider"),
          centerTitle: true,
        ),
        body:
        SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          child: Column(
              children:
              [
                Container(
                    height: heightval*0.05,
                    width: widthval,
                    child: Header(UserLogin: widget.UserLogin, User_JwtToken:widget.User_JwtToken,)
                ),

                FutureBuilder(
                  future: GetUserInfo(Email:widget.User_Email, jwttoken:widget.User_JwtToken),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: Colors.green[700]));
                    }
                    else if (snapshot.hasError) {
                      return Center(child: Text('Error:No data available'));
                    }
                    else if (snapshot.connectionState == ConnectionState.done) {
                      if (UserInfoModelList.isNotEmpty)
                      {
                        return Column(
                          children: [

                            Container (
                              width: shortestval * 0.4,
                              height: shortestval * 0.4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 4))
                                ],
                              ),
                              child: ClipOval(
                                child: UserInfoModelList[0].photo == null ||
                                    UserInfoModelList[0].photo!.isEmpty
                                    ? Image.asset('assets/images/profile/u_p_p_1.jpg',
                                    fit: BoxFit.cover)
                                    : Image.memory(
                                    base64Decode(UserInfoModelList[0].photo!),
                                    fit: BoxFit.cover),
                              ),
                            ),


                            SizedBox(height: shortestval * 0.02),
                            Text(
                              "Name: ${UserInfoModelList[0].firstName} ${UserInfoModelList[0].lastName}",
                              style: TextStyle(
                                  fontFamily: bold,
                                  fontSize: shortestval * 0.05,
                                  color: Colors.grey[800]),
                            ),

                          ],
                        );
                      }
                      return Text('No image data available');
                    }
                    return Text('Error. Relogin.');
                  },
                ),

                Commonbutton("Logout", ()async{
                  await Clear_User_Data();
                  await Random_token_Clear();
                  Toast.Toastmsg("Logout Success");
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => ErrorPage())
                  );
                  Toastget().Toastmsg("Session End.Relogin please.");
                  return;

                }, context, Colors.red),

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
                      int Result = await change_photo_cont_getx.pickImage();
                      if (Result == 1)
                      {
                        bool Result = await UpdatePhoto(Email: widget.User_Email,
                            jwttoken:widget.User_JwtToken,
                            photo_bytes: change_photo_cont_getx.imageBytes.value);
                        if (Result == true)
                        {
                          print("Image update success");
                          Toast.Toastmsg("Image update success");
                          setState(() {
                          });
                          return;
                        }
                        else{
                          print("Image update fail.");
                          Toast.Toastmsg("Fail to change photo.Try again.");
                          return;
                        }
                      }
                      else{
                        Toast.Toastmsg("Pick image fail.Use jpg,jpeg,png format only.");
                        return;
                      }

                  }catch (exception)
                    {
                      Toast.Toastmsg("Fail to change photo.Try again.");
                      return;
                    }
                  },
                  child:Text(
                    "Change Photo",
                    style: TextStyle(
                        fontFamily: semibold,
                        color: Colors.white,
                        fontSize: shortestval * 0.04),
                  ),
                ),

                SizedBox(height: shortestval * 0.02),
ElevatedButton(onPressed: (){

  Navigator.push(context, MaterialPageRoute(builder: (context) => ProviderAddService(
    User_Email: widget.User_Email,
    User_JwtToken:widget.User_JwtToken,
    User_Role: widget.User_Role,),));

}, child: Text("Add service.")),
                SizedBox(height: shortestval * 0.02),

                ElevatedButton(onPressed: (){

                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProviderAddSeviceResources(
                    User_Email: widget.User_Email,
                    User_JwtToken:widget.User_JwtToken,
                    User_Role: widget.User_Role,),));

                }, child: Text("Add service resources.")),
                SizedBox(height: shortestval * 0.02),

        ElevatedButton(onPressed: () {
          Navigator.push(context,MaterialPageRoute(builder:
(context) =>ProviderServiceSelect (User_Email: widget.User_Email,
  User_JwtToken:widget.User_JwtToken,
  User_Role: widget.User_Role,
          )
          )
          );
    }, child:Text("My gallery.")),

                SizedBox(height: shortestval * 0.02),

                ElevatedButton(onPressed: () {
                  Navigator.push(context,MaterialPageRoute(builder:
                      (context) =>UpdatePasswordScreen (User_Email: widget.User_Email,
                    User_JwtToken:widget.User_JwtToken,
                    User_Role: widget.User_Role,
                  )
                  )
                  );
                }, child:Text("Update password.")),

                SizedBox(height: shortestval * 0.02),

                ElevatedButton(onPressed: () {
                  Navigator.push(context,MaterialPageRoute(builder:
                      (context) =>ProviderUpdateServiceFile (User_Email: widget.User_Email,
                    User_JwtToken:widget.User_JwtToken,
                    User_Role: widget.User_Role,
                  )
                  )
                  );
                }, child:Text("Update service file.")),

                SizedBox(height: shortestval * 0.02),

                ElevatedButton(onPressed: () {
                  Navigator.push(context,MaterialPageRoute(builder:
                      (context) =>ProviderUpdateServiceResources (User_Email: widget.User_Email,
                    User_JwtToken:widget.User_JwtToken,
                    User_Role: widget.User_Role,
                  )
                  )
                  );
                }, child:Text("Update service resources.")),




              ]
          ),
        )

    );
  }
}


