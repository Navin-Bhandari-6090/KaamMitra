import 'dart:convert';
import 'package:app/web/footer/Footer.dart';
import 'package:app/web/profile/provider/Provider_add_Sevice_Resources.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:http/http.dart' as http;
import '../../../constant/Server_Database.dart';
import '../../../constant/Style.dart';
import '../../../models/UserInfo.dart';
import '../../../state management/getx/profile/provider_user/change_pro_photo_Getx.dart';
import '../../authentication/Error_page.dart';
import '../../common method/Commmon_Method.dart';
import '../../common widget/getx_cont_pick_single_photo_int.dart';
import '../../common widget/toast.dart';
import '../../header/Header.dart';
import '../provider_user/Update_Location.dart';
import '../provider_user/update_address.dart';
import '../provider_user/update_user_name.dart';
import 'ProviderAddService.dart';
import 'Provider_Service_Select.dart';
import 'Provider_Update_Service_File.dart';
import 'Select_Ser_Res_Update.dart';
import '../provider_user/Update_Email.dart';
import '../provider_user/Update_Password.dart';
import 'add_update_fonepay_qr.dart';

/// ---------------------------------------------------------------------------
/// THEME TOKENS (dark green, modern)
/// ---------------------------------------------------------------------------
class _ProfileTheme {
  static const Color bgTop = Color(0xFF04140E);
  static const Color bgMid = Color(0xFF0A2A1C);
  static const Color bgBottom = Color(0xFF0F3D2A);
  static const Color card = Color(0xFF123A28);
  static const Color cardBorder = Color(0xFF1F5D42);
  static const Color accent = Color(0xFF34E89E);
  static const Color accentDeep = Color(0xFF0F9B6C);
  static const Color danger = Color(0xFFE5544D);
  static const Color textPrimary = Color(0xFFF3FBF7);
  static const Color textMuted = Color(0xFFAFC9BC);
}

class ProviderProfile extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  final bool UserLogin;
  const ProviderProfile({
    super.key,
    req,
    required this.User_Email,
    required this.User_JwtToken,
    required this.User_Role,
    required this.UserLogin,
  });
  @override
  State<ProviderProfile> createState() => _ProviderProfileState();
}

class _ProviderProfileState extends State<ProviderProfile>
    with SingleTickerProviderStateMixin {
  final Toast = Toastget();
  final change_photo_cont_getx = Get.put(pick_single_photo_getx_int());

  // Entrance animation controller (UI-only addition, no business logic).
  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;

  final ProviderGetx providerGetx = Get.put(ProviderGetx());



  @override
  void initState() {
    super.initState();
    Provider_Jwt_Verify(Jwt_Token: widget.User_JwtToken);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> Provider_Jwt_Verify({required String Jwt_Token}) async {
    int Result = await ProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result == 1) {
      return;
    } else {
      await Clear_User_Data();
      await Random_token_Clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ErrorPage()),
            (route) => false,
      );
      Toastget().Toastmsg("Session End.Relogin please.");
      return;
    }
  }

  List<UserInfo> UserInfoModelList = [];

  Future<void> GetUserInfo({
    required String Email,
    required String jwttoken,
    required bool ChangePhoto
  }) async {
    try {


      const String url = Backend_Server_Url + "api/Profile/getuserinfo";
      Map<String, dynamic> UserDetails = {"Email": Email};
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $jwttoken',
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

  Future<bool> UpdatePhoto({
    required String Email,
    required String jwttoken,
    required String photoExtension,
    required List<int> photoBytes,
  }) async {
    try {
      print("========== UPDATE PHOTO ==========");
      print("Email: $Email");
      print("Photo Extension: $photoExtension");
      print("Photo Size: ${photoBytes.length} bytes");

      // --------------------------------------------------
      // 1. Validate photo
      // --------------------------------------------------

      if (photoBytes.length == 0) {
        print("ERROR: Photo bytes are empty.");
        return false;
      }

      // --------------------------------------------------
      // 2. Validate extension
      // --------------------------------------------------

      String extension = photoExtension.toLowerCase().trim();

      if (extension.startsWith(".")) {
        extension = extension.substring(1);
      }

      if (extension != "jpg" && extension != "jpeg" && extension != "png") {
        print("ERROR: Invalid photo extension.");
        return false;
      }

      // --------------------------------------------------
      // 3. API URL
      // --------------------------------------------------

      const String url = Backend_Server_Url + "api/Profile/updateprofilephoto";

      print("API URL: $url");

      // --------------------------------------------------
      // 4. Create multipart request
      // --------------------------------------------------

      final request = http.MultipartRequest("PUT", Uri.parse(url));

      // --------------------------------------------------
      // 5. JWT
      // --------------------------------------------------

      request.headers["Authorization"] = "Bearer $jwttoken";

      // --------------------------------------------------
      // 6. Email
      // --------------------------------------------------

      request.fields["Email"] = Email;

      // --------------------------------------------------
      // 7. Extension
      // --------------------------------------------------

      request.fields["PhotoExtension"] = extension;

      // --------------------------------------------------
      // 8. Add image bytes
      // --------------------------------------------------

      request.files.add(
        http.MultipartFile.fromBytes(
          "Photo",
          photoBytes,
          filename: "profile.$extension",
        ),
      );

      print("Multipart request created.");
      print("Uploading photo...");

      // --------------------------------------------------
      // 9. Send request
      // --------------------------------------------------

      final streamedResponse = await request.send();

      // --------------------------------------------------
      // 10. Read response
      // --------------------------------------------------

      final response = await http.Response.fromStream(streamedResponse);

      // --------------------------------------------------
      // 11. Print response
      // --------------------------------------------------

      print("Response status: ${response.statusCode}");

      print("Response body: ${response.body}");

      // --------------------------------------------------
      // 12. Status handling
      // --------------------------------------------------

      if (response.statusCode == 200) {
        print("Profile photo updated successfully.");

        return true;
      }

      if (response.statusCode == 400) {
        print("Bad request: ${response.body}");

        return false;
      }

      if (response.statusCode == 404) {
        print("User not found: ${response.body}");

        return false;
      }

      if (response.statusCode == 500) {
        print("Server error: ${response.body}");

        return false;
      }

      print("Unexpected status code: ${response.statusCode}");

      return false;
    } catch (obj) {
      print("Exception caught while updating profile photo.");

      print("Exception: ${obj.toString()}");

      return false;
    }
  }

  String GetPhotoUrl(String photoPath) {
    if (photoPath.isEmpty) {
      return "";
    }

    final baseUrl = Backend_Server_Url.endsWith("/")
        ? Backend_Server_Url.substring(0, Backend_Server_Url.length - 1)
        : Backend_Server_Url;

    final path = photoPath.startsWith("/") ? photoPath : "/$photoPath";

    return "$baseUrl$path";
  }

  // ---------------------------------------------------------------------
  // Shared onPressed logic for changing the photo — UNCHANGED behavior,
  // just extracted so it can be triggered from the new edit-avatar button.
  // ---------------------------------------------------------------------
  Future<void> _onChangePhotoPressed() async {
    try {
      int PhotoResult = await change_photo_cont_getx.pickImage();
      if (PhotoResult == 1) {
        bool Result = await UpdatePhoto(
          Email: widget.User_Email,
          jwttoken: widget.User_JwtToken,
          photoExtension: change_photo_cont_getx.imageExtension.value,
          photoBytes: change_photo_cont_getx.imageBytes.value!,
        );
        if (Result == true) {
          print("Image update success");
          Toast.Toastmsg("Image update success");
          providerGetx.ChangePhotoClickChange();
          return;
        } else {
          print("Image update fail.");
          Toast.Toastmsg("Fail to change photo.Try again.");
          return;
        }
      } else if (PhotoResult == 2) {
        Toast.Toastmsg("Invalid photo extension(format only jpg,jpeg,png)");
        return;
      } else if (PhotoResult == 5) {
        Toast.Toastmsg("Photo is larger than 100 MB.");
        return;
      } else {
        Toast.Toastmsg(
          "Pick image fail.Use jpg,jpeg,png format only for photos.",
        );
        return;
      }
    } catch (exception) {
      Toast.Toastmsg("Fail to change photo.Try again.");
      return;
    }
  }

  Future<void> _onLogoutPressed() async {
    await Clear_User_Data();
    await Random_token_Clear();
    Toast.Toastmsg("Logout Success");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ErrorPage()),
    );
    Toastget().Toastmsg("Session End.Relogin please.");
    return;
  }

  @override
  Widget build(BuildContext context) {
    var shortestval = MediaQuery.of(context).size.shortestSide;
    var widthval = MediaQuery.of(context).size.width;
    var heightval = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    // Action items — same destinations/params as the original screen,
    // just modeled as data so they can be laid out responsively.
    final List<_ActionItem> actions = [

      _ActionItem(
        icon: Icons.add_business_rounded,
        label: "Add service",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderAddService(
              User_Email: widget.User_Email,
              User_JwtToken: widget.User_JwtToken,
              User_Role: widget.User_Role,
            ),
          ),
        ),
      ),
      _ActionItem(
        icon: Icons.inventory_2_rounded,
        label: "Add service resources",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderAddSeviceResources(
              User_Email: widget.User_Email,
              User_JwtToken: widget.User_JwtToken,
              User_Role: widget.User_Role,
            ),
          ),
        ),
      ),
      _ActionItem(
        icon: Icons.photo_library_rounded,
        label: "My gallery",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderServiceSelect(
              User_Email: widget.User_Email,
              User_JwtToken: widget.User_JwtToken,
              User_Role: widget.User_Role,
            ),
          ),
        ),
      ),
      _ActionItem(
        icon: Icons.lock_reset_rounded,
        label: "Update password",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UpdatePasswordScreen(
              User_Email: widget.User_Email,
              User_JwtToken: widget.User_JwtToken,
              User_Role: widget.User_Role,
            ),
          ),
        ),
      ),
      _ActionItem(
        icon: Icons.upload_file_rounded,
        label: "Update service file",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderUpdateServiceFile(
              User_Email: widget.User_Email,
              User_JwtToken: widget.User_JwtToken,
              User_Role: widget.User_Role,
            ),
          ),
        ),
      ),
      _ActionItem(
        icon: Icons.build_circle_rounded,
        label: "Update service resources",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectSerResUpdate(
              User_Email: widget.User_Email,
              User_JwtToken: widget.User_JwtToken,
              User_Role: widget.User_Role,
            ),
          ),
        ),
      ),

      _ActionItem(
        icon: Icons.email_rounded,
        label: "Update email",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UpdateEmail(
              User_Email: widget.User_Email,
              User_JwtToken: widget.User_JwtToken,
              User_Role: widget.User_Role,
            ),
          ),
        ),
      ),

      _ActionItem(
        icon: Icons.location_city_rounded,
        label: "Update latitude and longitude",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UpdateLocation(
              User_Email: widget.User_Email,
              User_JwtToken: widget.User_JwtToken,
              User_Role: widget.User_Role,
            ),
          ),
        ),
      ),


      _ActionItem(
        icon: Icons.location_city_rounded,
        label: "Update User name",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UpdateUserName(
              User_Email: widget.User_Email,
              User_JwtToken: widget.User_JwtToken,
              User_Role: widget.User_Role,
            ),
          ),
        ),
      ),

      _ActionItem(
        icon: Icons.location_city_rounded,
        label: "Add/Update fonepay QR photo.",
        onTap: () {
          final user = UserInfoModelList[0];
           Navigator.push
            (
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddUpdateFonepayQr(
                    User_Email: widget.User_Email,
                    User_JwtToken: widget.User_JwtToken,
                    User_Role: widget.User_Role,
                  ),
            ),
          );
        }
      ),

      _ActionItem(
          icon: Icons.location_city_rounded,
          label: "Update address.",
          onTap: () {
            final user = UserInfoModelList[0];
            Navigator.push
              (
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UpdateAddress(
                      User_Email: widget.User_Email,
                      User_JwtToken: widget.User_JwtToken,
                      User_Role: widget.User_Role,
                    ),
              ),
            );
          }
      ),







    ];

    return Scaffold(
      backgroundColor: _ProfileTheme.bgTop,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: _ProfileTheme.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout_rounded, color: _ProfileTheme.danger),
            onPressed: _onLogoutPressed,
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _ProfileTheme.bgTop,
              _ProfileTheme.bgMid,
              _ProfileTheme.bgBottom,
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, outerConstraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                child: ConstrainedBox(
                  // Ensures the page still fills the screen (so the
                  // gradient background looks right) when content is
                  // short, WITHOUT forcing Header to fit into a fixed
                  // height — if the viewport is ever shorter than
                  // Header needs, the page scrolls instead of
                  // overflowing.
                  constraints: BoxConstraints(
                    minHeight: outerConstraints.maxHeight,
                  ),
                  child: Column(
                    children:
                    [
                      // ======================================================
                      // HEADER — full width, OUTSIDE the horizontal padding
                      // (mirrors Home_Screen.dart layout so it spans edge-to-edge)
                      // ======================================================
                      Header(
                        UserLogin: widget.UserLogin,
                        User_JwtToken: widget.User_JwtToken,
                      ),

                      // ======================================================
                      // PADDED CONTENT BELOW THE HEADER
                      // ======================================================
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: widthval * (isLandscape ? 0.06 : 0.05),
                          vertical: heightval * 0.02,
                        ),
                        child:
                        Column(
                          children: [

                            Obx
                              (
                                  ()=>

                              FutureBuilder
                                (
                                future: GetUserInfo(
                                  Email: widget.User_Email,
                                  jwttoken: widget.User_JwtToken,
                                  ChangePhoto: providerGetx.ChangePhotoClick.value,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: heightval * 0.08,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: _ProfileTheme.accent,
                                        ),
                                      ),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return const Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Center(
                                        child: Text(
                                          "Error: No data available",
                                          style: TextStyle(
                                            color: _ProfileTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  if (UserInfoModelList.isNotEmpty)
                                  {

                                    final user = UserInfoModelList[0];
                                    final String photoPath = user.photo ?? "";
                                    final String photoUrl = photoPath.isNotEmpty
                                        ? GetPhotoUrl(photoPath)
                                        : "";

                                    return FadeTransition(
                                      opacity: _fadeIn,
                                      child: Column(
                                        children: [
                                          // =========================================
                                          // PROFILE PHOTO + EDIT BADGE
                                          // =========================================
                                          Stack(
                                            clipBehavior: Clip.none,
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                width: shortestval * 0.38,
                                                height: shortestval * 0.38,
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: const LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      _ProfileTheme.accent,
                                                      _ProfileTheme.accentDeep,
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: _ProfileTheme.accent
                                                          .withOpacity(0.35),
                                                      blurRadius: 24,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                                child: ClipOval(
                                                  child: Container(
                                                    color: _ProfileTheme.card,
                                                    child: photoUrl.isEmpty
                                                        ? Image.asset(
                                                      'assets/images/profile/u_p_p_1.jpg',
                                                      fit: BoxFit.cover,
                                                    )
                                                        : Image.network(
                                                      photoUrl,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (
                                                          context,
                                                          child,
                                                          loadingProgress,
                                                          ) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          return child;
                                                        }
                                                        return const Center(
                                                          child:
                                                          CircularProgressIndicator(
                                                            color:
                                                            _ProfileTheme
                                                                .accent,
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                          ) {
                                                        print(
                                                          "Profile image loading failed: $error",
                                                        );
                                                        return Image.asset(
                                                          'assets/images/profile/u_p_p_1.jpg',
                                                          fit: BoxFit.cover,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),


                                              Positioned(
                                                bottom: 0,
                                                right: shortestval * 0.02,
                                                child: Material(
                                                  color: _ProfileTheme.accent,
                                                  shape: const CircleBorder(),
                                                  elevation: 4,
                                                  child: InkWell(
                                                    customBorder:
                                                    const CircleBorder(),
                                                    onTap: _onChangePhotoPressed,
                                                    child: Padding(
                                                      padding:
                                                      const EdgeInsets.all(9),
                                                      child: Icon(
                                                        Icons.camera_alt_rounded,
                                                        size: shortestval * 0.045,
                                                        color: _ProfileTheme.bgTop,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),


                                            ],
                                          ),

                                          SizedBox(height: shortestval * 0.035),

                                          // =========================================
                                          // USER NAME
                                          // =========================================
                                          Text(
                                            "User Name : ${user.firstName} ${user.lastName}",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: bold,
                                              fontSize: shortestval * 0.052,
                                              fontWeight: FontWeight.w700,
                                              color: _ProfileTheme.textPrimary,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          SizedBox(height: shortestval * 0.008),

                                          Text(
                                            "Id: ${user.userNumber}",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: bold,
                                              fontSize: shortestval * 0.052,
                                              fontWeight: FontWeight.w700,
                                              color: _ProfileTheme.textPrimary,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          SizedBox(height: shortestval * 0.008),

                                          Text(
                                            "Email : ${user.email}",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: bold,
                                              fontSize: shortestval * 0.052,
                                              fontWeight: FontWeight.w700,
                                              color: _ProfileTheme.textPrimary,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          SizedBox(height: shortestval * 0.008),

                                          Text(
                                            "Address : ${user.address}",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: bold,
                                              fontSize: shortestval * 0.052,
                                              fontWeight: FontWeight.w700,
                                              color: _ProfileTheme.textPrimary,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          SizedBox(height: shortestval * 0.008),


                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _ProfileTheme.accent
                                                  .withOpacity(0.12),
                                              borderRadius:
                                              BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _ProfileTheme.accent
                                                    .withOpacity(0.4),
                                              ),
                                            ),
                                            child: Text(
                                              "Latitude:  ${user.latitude}",
                                              style: TextStyle(
                                                fontFamily: semibold,
                                                fontSize: shortestval * 0.026,
                                                color: _ProfileTheme.accent,
                                                letterSpacing: 1.1,
                                              ),
                                            ),
                                          ),

                                          SizedBox(height: shortestval * 0.008),

                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _ProfileTheme.accent
                                                  .withOpacity(0.12),
                                              borderRadius:
                                              BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _ProfileTheme.accent
                                                    .withOpacity(0.4),
                                              ),
                                            ),
                                            child: Text(
                                              "Longitude: :  ${user.longitude}",
                                              style: TextStyle(
                                                fontFamily: semibold,
                                                fontSize: shortestval * 0.026,
                                                color: _ProfileTheme.accent,
                                                letterSpacing: 1.1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      "No user data available",
                                      style: TextStyle(
                                        color: _ProfileTheme.textMuted,
                                      ),
                                    ),
                                  );
                                },
                              ),



                            ),

                            SizedBox(height: heightval * 0.035),

                            // =============================================
                            // ACTIONS — responsive grid (landscape) / list (portrait)
                            // =============================================
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final crossAxisCount = isLandscape
                                    ? (constraints.maxWidth > 900 ? 3 : 2)
                                    : (constraints.maxWidth > 600 ? 2 : 1);

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: actions.length,
                                  gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio:
                                    crossAxisCount == 1 ? 4.6 : 2.9,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = actions[index];
                                    final delayStart =
                                    (index * 0.08).clamp(0.0, 0.6);
                                    final anim = CurvedAnimation(
                                      parent: _entranceController,
                                      curve: Interval(
                                        delayStart,
                                        (delayStart + 0.4).clamp(0.0, 1.0),
                                        curve: Curves.easeOutCubic,
                                      ),
                                    );
                                    return AnimatedBuilder(
                                      animation: anim,
                                      builder: (context, child) {
                                        return Opacity(
                                          opacity: anim.value,
                                          child: Transform.translate(
                                            offset:
                                            Offset(0, (1 - anim.value) * 24),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _ActionTile(item: item),
                                    );
                                  },
                                );
                              },
                            ),

                            SizedBox(height: heightval * 0.03),
                          ],
                        ),
                      ),

                      Footer()
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _ActionItem({required this.icon, required this.label, required this.onTap});
}


class _ActionTile extends StatefulWidget {
  final _ActionItem item;

  const _ActionTile({
    required this.item,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  final ProviderGetx providerGetx = Get.put(ProviderGetx());

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => AnimatedScale(
        scale: providerGetx.actionTilePressed.value ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),

            onTap: widget.item.onTap,

            onTapDown: (_) {
              providerGetx.setActionTilePressed(true);
            },

            onTapCancel: () {
              providerGetx.setActionTilePressed(false);
            },

            onTapUp: (_) {
              providerGetx.setActionTilePressed(false);
            },

            child: Container(
              decoration: BoxDecoration(
                color: _ProfileTheme.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _ProfileTheme.cardBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          _ProfileTheme.accent,
                          _ProfileTheme.accentDeep,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.item.icon,
                      color: _ProfileTheme.bgTop,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Text(
                      widget.item.label,
                      style: const TextStyle(
                        color: _ProfileTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: _ProfileTheme.textMuted,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

