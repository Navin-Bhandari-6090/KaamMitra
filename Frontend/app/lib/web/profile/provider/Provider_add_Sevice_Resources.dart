import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:http/http.dart' as http;
import '../../../constant/Server_Database.dart';
import '../../../constant/Style.dart';
// NOTE: adjust this path if your AddServiceResources controller file
// lives elsewhere — mirrored after the add_service_getx import pattern.
import '../../../state management/getx/profile/provider/add_service_resources.dart';
import '../../authentication/Error_page.dart';
import '../../common method/Commmon_Method.dart';
import '../../common widget/GreenTextfield.dart';
import '../../common widget/getx_cont_pick_single_photo_int.dart';
import '../../common widget/single_video_pick_getx.dart';
import '../../common widget/toast.dart';

/// ---------------------------------------------------------------------------
/// THEME TOKENS (dark green, modern) — matches Header.dart / ProviderProfile.dart
/// ---------------------------------------------------------------------------
class _Theme {
  static const Color bgTop = Color(0xFF0F1F17);
  static const Color bgMid = Color(0xFF12261C);
  static const Color bgBottom = Color(0xFF0A160F);

  static const Color surface = Color(0xFF162E22);
  static const Color surfaceBar = Color(0xFF12261C);

  static const Color primaryText = Color(0xFFE6F4EA);
  static const Color mutedText = Color(0xFF9AA0A6);
  static const Color mutedTextAlt = Color(0xFF8A9A90);

  static const Color emerald = Color(0xFF22C55E);
  static const Color mint = Color(0xFF34D399);

  static const Color border = Color(0xFF234232);
}

class ProviderAddSeviceResources extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  const ProviderAddSeviceResources(
      {super.key,
        required this.User_Email,
        required this.User_JwtToken,
        required this.User_Role});

  @override
  State<ProviderAddSeviceResources> createState() =>
      _ProviderAddSeviceResourcesState();
}

class _ProviderAddSeviceResourcesState
    extends State<ProviderAddSeviceResources>
    with SingleTickerProviderStateMixin {
  final Toast = Toastget();
  final change_photo_cont_getx = Get.put(pick_single_photo_getx_int());
  final change_video_cont_getx = Get.put(PickSingleVideoController());
  final TextEditingController ProviderServiceIdCont = TextEditingController();
  final resourcesGetx = Get.put(AddServiceResourcesGetx());

  // ============================================================
  // ENTRANCE ANIMATION (UI-only addition, no business logic)
  // ============================================================

  late final AnimationController _entranceController;
  late final Animation<double> _heroAnim;
  late final Animation<double> _idAnim;
  late final Animation<double> _mediaAnim;
  late final Animation<double> _submitAnim;

  @override
  void initState() {
    super.initState();
    Provider_Jwt_Verify(Jwt_Token: widget.User_JwtToken);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _heroAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _idAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.70, curve: Curves.easeOutCubic),
    );
    _mediaAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.30, 0.85, curve: Curves.easeOutCubic),
    );
    _submitAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    change_video_cont_getx.videoExtension.value="";
    change_video_cont_getx.videoBytes.value=null;
    change_video_cont_getx.videoPath.value="";
    change_photo_cont_getx.imageExtension.value="";
    change_photo_cont_getx.imageBytes.value=null;
    change_photo_cont_getx.imagePath.value="";
    super.dispose();
  }

  Future<void> Provider_Jwt_Verify({required String Jwt_Token}) async
  {
    int Result = await ProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result == 1) {
      return;
    } else {
      await Clear_User_Data();
      await Random_token_Clear();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => ErrorPage()));
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

      final int? serviceId = int.tryParse(SeviceId.trim());

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
      PhotoExtension.trim().toLowerCase().replaceFirst('.', '');

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
      VideoExtension.trim().toLowerCase().replaceFirst('.', '');

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

      const String url = Backend_Server_Url + "api/Profile/addserviceresources";

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

      request.headers["Authorization"] = "Bearer ${widget.User_JwtToken}";

      // =========================================================
      // 11. Normal form fields
      // =========================================================

      request.fields["ProviderServiceId"] = serviceId.toString();

      request.fields["Email"] = widget.User_Email;

      request.fields["PhotoExtension"] = photoExtension;

      request.fields["VideoExtension"] = videoExtension;

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

      final streamedResponse = await request.send();

      // =========================================================
      // 16. Convert response
      // =========================================================

      final response = await http.Response.fromStream(
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

        change_video_cont_getx.videoExtension.value="";
        change_video_cont_getx.videoBytes.value=null;
        change_video_cont_getx.videoPath.value="";
        change_photo_cont_getx.imageExtension.value="";
        change_photo_cont_getx.imageBytes.value=null;
        change_photo_cont_getx.imagePath.value="";

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

  // ============================================================
  // PICK PHOTO — same logic, loading/press state via GetX
  // ============================================================

  Future<void> _onPickPhotoPressed() async {
    try {
      int PhotoResult = await change_photo_cont_getx.pickImage();
      if (PhotoResult == 1) {
        Toast.Toastmsg("Pick photo for service resources success.");
        return;
      }
      else if(PhotoResult==2){
        Toast.Toastmsg("Only .png,.jpg,.jpeg format accepted.");
        return;
      }
      else if(PhotoResult==5){
        Toast.Toastmsg("Image is larger then 100mb.Please compressed and upload..");
        return;
      }
      else {
        Toast.Toastmsg("Pick photo for service resources fail.");
        return;
      }
    } catch (e) {
      Toast.Toastmsg("Pick photo for service resources fail.");
      return;
    }
  }

  // ============================================================
  // PICK VIDEO — same logic, loading/press state via GetX
  // ============================================================

  Future<void> _onPickVideoPressed() async {
    try {
      int PhotoResult = await change_video_cont_getx.pickVideo();
      if (PhotoResult == 1) {
        Toast.Toastmsg("Pick video for service resources success.");
        return;
      } else {
        Toast.Toastmsg("Pick video for service resources fail.");
        return;
      }
    } catch (e) {
      Toast.Toastmsg("Pick photo for service resources fail.");
      return;
    }
  }

  // ============================================================
  // SUBMIT — same logic/branches as before, wrapped with a GetX
  // loading state instead of any setState.
  // ============================================================

  Future<void> _onSubmitPressed() async {
    if (resourcesGetx.isSubmitting.value) return;

    resourcesGetx.setSubmitting(true);
    try {
      if (change_video_cont_getx.videoBytes.value != null &&
          change_photo_cont_getx.imageBytes.value != null) {
        int Result = await AddServiceResources(
            ImageBytes: change_photo_cont_getx.imageBytes.value!,
            VideoBytes: change_video_cont_getx.videoBytes.value!,
            SeviceId: ProviderServiceIdCont.text.trim(),
            PhotoExtension: change_photo_cont_getx.imageExtension.value!,
            VideoExtension: change_video_cont_getx.videoExtension.value!);
        if (Result == 1) {
          return;
        } else {
          return;
        }
      } else {
        Toast.Toastmsg(
            "Pick photo(.png,.jpg,.jpeg) and video(.mp4) in correct format and then try again.");
        return;
      }
    } catch (exception) {
      return;
    } finally {
      resourcesGetx.setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final double widthval = media.size.width;

    final bool isMobile = widthval < 700;
    final bool isTablet = widthval >= 700 && widthval < 1100;

    final double horizontalPadding = isMobile ? 18 : (isTablet ? 32 : 48);
    final double contentMaxWidth = widthval > 1100 ? 880 : double.infinity;

    return Scaffold(
      backgroundColor: _Theme.bgTop,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_Theme.bgTop, _Theme.bgMid, _Theme.bgBottom],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, outerConstraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints:
                  BoxConstraints(minHeight: outerConstraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: isMobile ? 20 : 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ================================================
                            // TOP BAR
                            // ================================================
                            _buildTopBar(isMobile),

                            SizedBox(height: isMobile ? 20 : 28),

                            // ================================================
                            // HERO SECTION
                            // ================================================
                            _animatedSection(
                              animation: _heroAnim,
                              child: _buildHero(isMobile),
                            ),

                            SizedBox(height: isMobile ? 22 : 30),

                            // ================================================
                            // SERVICE ID CARD
                            // ================================================
                            _animatedSection(
                              animation: _idAnim,
                              child: _buildServiceIdCard(isMobile),
                            ),

                            SizedBox(height: isMobile ? 22 : 30),

                            // ================================================
                            // MEDIA UPLOAD CARD
                            // ================================================
                            _animatedSection(
                              animation: _mediaAnim,
                              child: _buildMediaCard(isMobile),
                            ),

                            SizedBox(height: isMobile ? 22 : 30),

                            // ================================================
                            // SUBMIT ACTION
                            // ================================================
                            _animatedSection(
                              animation: _submitAnim,
                              child: _buildSubmitCard(isMobile),
                            ),

                            SizedBox(height: isMobile ? 24 : 36),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ANIMATED SECTION WRAPPER
  // ============================================================

  Widget _animatedSection({
    required Animation<double> animation,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, builtChild) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 22),
            child: builtChild,
          ),
        );
      },
      child: child,
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(bool isMobile) {
    return Row(
      children: [
        Material(
          color: _Theme.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _Theme.border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _Theme.primaryText,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            "Add Service Resources",
            style: TextStyle(
              color: _Theme.primaryText,
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF193A29), Color(0xFF12261C), Color(0xFF101F18)],
        ),
        border: Border.all(color: _Theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 560;

          return Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment:
            compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: compact ? 0 : 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _Theme.emerald.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                            color: _Theme.emerald.withOpacity(0.20)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.perm_media_rounded,
                              color: _Theme.mint, size: 14),
                          SizedBox(width: 7),
                          Text(
                            "Showcase your work",
                            style: TextStyle(
                              color: _Theme.mint,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Add service resources",
                      style: TextStyle(
                        color: _Theme.primaryText,
                        fontSize: isMobile ? 24 : 32,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Attach a photo and a short video to an existing "
                          "service so customers can see your work before they book.",
                      style: TextStyle(
                        color: _Theme.mutedText,
                        fontSize: isMobile ? 13 : 14.5,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) const SizedBox(width: 26),
              if (compact) const SizedBox(height: 20),
              if (!compact)
                Container(
                  height: 108,
                  width: 108,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _Theme.emerald.withOpacity(0.22),
                        _Theme.emerald.withOpacity(0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Container(
                    height: 76,
                    width: 76,
                    decoration: BoxDecoration(
                      color: _Theme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: _Theme.emerald.withOpacity(0.30), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _Theme.emerald.withOpacity(0.12),
                          blurRadius: 24,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.video_camera_back_rounded,
                      color: _Theme.mint,
                      size: 32,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // SERVICE ID CARD
  // ============================================================

  Widget _buildServiceIdCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: _Theme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _Theme.emerald.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tag_rounded,
                    color: _Theme.mint, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Service reference",
                  style: TextStyle(
                    color: _Theme.primaryText,
                    fontSize: isMobile ? 15.5 : 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Enter the ID of the service these resources belong to.",
            style: TextStyle(
              color: _Theme.mutedTextAlt,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          GreenField(
            controller: ProviderServiceIdCont,
            label: "Enter service Id.",
            icon: Icons.tag_rounded,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MEDIA UPLOAD CARD
  // ============================================================

  Widget _buildMediaCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: _Theme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _Theme.emerald.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.perm_media_rounded,
                    color: _Theme.mint, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Photo & video",
                  style: TextStyle(
                    color: _Theme.primaryText,
                    fontSize: isMobile ? 15.5 : 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Accepted formats — photo: .png, .jpg, .jpeg  •  video: .mp4",
            style: TextStyle(
              color: _Theme.mutedTextAlt,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool stack = constraints.maxWidth < 560;

              final Widget photoTile = _mediaPickTile(
                icon: Icons.image_rounded,
                title: "Photo",
                subtitle: "Pick photo for service resources",
                isPressedRx: resourcesGetx.isPhotoButtonPressed,
                onPressDown: () =>
                    resourcesGetx.setPhotoButtonPressed(true),
                onPressUp: () =>
                    resourcesGetx.setPhotoButtonPressed(false),
                onTap: _onPickPhotoPressed,
                isSelected: () =>
                change_photo_cont_getx.imageBytes.value != null,
              );

              final Widget videoTile = _mediaPickTile(
                icon: Icons.videocam_rounded,
                title: "Showcase video",
                subtitle: "Pick video for service resources",
                isPressedRx: resourcesGetx.isVideoButtonPressed,
                onPressDown: () =>
                    resourcesGetx.setVideoButtonPressed(true),
                onPressUp: () =>
                    resourcesGetx.setVideoButtonPressed(false),
                onTap: _onPickVideoPressed,
                isSelected: () =>
                change_video_cont_getx.videoBytes.value != null,
              );

              if (stack) {
                return Column(
                  children: [
                    photoTile,
                    const SizedBox(height: 14),
                    videoTile,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: photoTile),
                  const SizedBox(width: 14),
                  Expanded(child: videoTile),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // A single pick tile (photo or video) — press feedback via
  // GetX, selection checkmark via Obx on the existing Rx fields.
  // ------------------------------------------------------------

  Widget _mediaPickTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required RxBool isPressedRx,
    required VoidCallback onPressDown,
    required VoidCallback onPressUp,
    required Future<void> Function() onTap,
    required bool Function() isSelected,
  }) {
    return Obx(() {
      final bool pressed = isPressedRx.value;
      final bool selected = isSelected();

      return AnimatedScale(
        scale: pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            onTapDown: (_) => onPressDown(),
            onTapCancel: onPressUp,
            onTapUp: (_) => onPressUp(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected
                    ? _Theme.emerald.withOpacity(0.08)
                    : _Theme.surfaceBar,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? _Theme.emerald.withOpacity(0.45)
                      : _Theme.border,
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                        colors: [_Theme.emerald, _Theme.mint],
                      )
                          : null,
                      color: selected ? null : _Theme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? null
                          : Border.all(color: _Theme.border),
                    ),
                    child: Icon(
                      icon,
                      color: selected ? Colors.white : _Theme.mint,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: _Theme.primaryText,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          selected ? "Selected" : subtitle,
                          style: TextStyle(
                            color: selected
                                ? _Theme.mint
                                : _Theme.mutedText,
                            fontSize: 11.5,
                            fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    color: selected ? _Theme.emerald : _Theme.mutedTextAlt,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ============================================================
  // SUBMIT CARD
  // ============================================================

  Widget _buildSubmitCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            _Theme.emerald.withOpacity(0.12),
            _Theme.mint.withOpacity(0.03),
          ],
        ),
        border: Border.all(color: _Theme.emerald.withOpacity(0.18)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 480;

          final Widget info = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _Theme.emerald.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_upload_rounded,
                    color: _Theme.mint, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upload resources",
                      style: TextStyle(
                        color: _Theme.primaryText,
                        fontSize: isMobile ? 14.5 : 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Make sure both a photo and a video are selected "
                          "above before submitting.",
                      style: TextStyle(
                        color: _Theme.mutedText,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final Widget button = _submitButton(isMobile: isMobile);

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 18),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _submitButton({required bool isMobile}) {
    return Obx(() {
      final bool submitting = resourcesGetx.isSubmitting.value;
      final bool pressed = resourcesGetx.isSubmitButtonPressed.value;

      return AnimatedScale(
        scale: pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: submitting ? null : _onSubmitPressed,
            onTapDown: (_) => resourcesGetx.setSubmitButtonPressed(true),
            onTapCancel: () => resourcesGetx.setSubmitButtonPressed(false),
            onTapUp: (_) => resourcesGetx.setSubmitButtonPressed(false),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 26,
                vertical: isMobile ? 14 : 15,
              ),
              decoration: BoxDecoration(
                gradient: submitting
                    ? null
                    : const LinearGradient(
                  colors: [_Theme.emerald, _Theme.mint],
                ),
                color: submitting ? _Theme.surface : null,
                borderRadius: BorderRadius.circular(14),
                border: submitting ? Border.all(color: _Theme.border) : null,
                boxShadow: submitting
                    ? []
                    : [
                  BoxShadow(
                    color: _Theme.emerald.withOpacity(0.30),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (submitting) ...[
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: _Theme.mint,
                        strokeWidth: 2.2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Submitting...",
                      style: TextStyle(
                        fontFamily: semibold,
                        color: _Theme.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 13.5 : 14.5,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.cloud_upload_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 9),
                    Text(
                      "Add resources on service",
                      style: TextStyle(
                        fontFamily: semibold,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 13.5 : 14.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}