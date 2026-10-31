import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';
import '../../../constant/Server_Database.dart';
import '../../../constant/Style.dart';

import '../../../constant/variable.dart';


import '../../../state management/getx/profile/provider/add_service_resources_getx.dart';
import '../../common method/Commmon_Method.dart';
import '../../common widget/GreenTextfield.dart';
import '../../common widget/getx_cont_pick_single_photo_int.dart';
import '../../common widget/single_video_pick_getx.dart';

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
  static const Color borderStrong = Color(0xFF2F5A43);
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

class _ProviderAddSeviceResourcesState extends State<ProviderAddSeviceResources>
    with SingleTickerProviderStateMixin {
  final change_photo_cont_getx = Get.put(pick_single_photo_getx_int());
  final change_video_cont_getx = Get.put(PickSingleVideoController());
  final TextEditingController ProviderServiceIdCont = TextEditingController();
  final resourcesGetx = Get.put(AddServiceResourcesGetx());

  final ResourceTitleTextCont = TextEditingController();

  // ============================================================
  // ENTRANCE ANIMATION (UI-only addition, no business logic)
  // ============================================================

  late final AnimationController _entranceController;
  late final Animation<double> _heroAnim;
  late final Animation<double> _idAnim;
  late final Animation<double> _detailsAnim;
  late final Animation<double> _mediaAnim;
  late final Animation<double> _submitAnim;

  @override
  void initState() {
    super.initState();
    Provider_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    Animation<double> seg(double a, double b) => CurvedAnimation(
      parent: _entranceController,
      curve: Interval(a, b, curve: Curves.easeOutCubic),
    );

    _heroAnim = seg(0.0, 0.50);
    _idAnim = seg(0.12, 0.62);
    _detailsAnim = seg(0.24, 0.74);
    _mediaAnim = seg(0.36, 0.86);
    _submitAnim = seg(0.48, 1.0);

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    // Reset picked photo / video / file with your common method.
    ClearFilesValues();
    super.dispose();
  }

  // ==========================================================================
  // BUSINESS LOGIC — UNCHANGED
  // ==========================================================================

  Future<int> AddServiceResources({
    required List<int>? ImageBytes,
    required List<int>? VideoBytes,
    required String SeviceId,
    required String? PhotoExtension,
    required String? VideoExtension,
    required String Title,
    required List<int> FileBytes,
    required String FileExtension,
  }) async {
    try {
      // Validate service title.
      if (Title.trim().isEmpty) {
        Toast.Toastmsg("Service title is required.");
        return 1;
      }

      // Validate mandatory service file.
      if (FileBytes.isEmpty) {
        Toast.Toastmsg("Service file is required.");
        return 2;
      }

      // Validate service ID.
      if (SeviceId.trim().isEmpty) {
        Toast.Toastmsg("Service ID is required.");
        return 3;
      }

      final int? serviceId = int.tryParse(SeviceId.trim());

      if (serviceId == null || serviceId <= 0) {
        Toast.Toastmsg("Invalid Service ID.");
        return 3;
      }

      // Validate file extension supplied by the frontend picker.
      final String fileExtension =
      FileExtension.trim().replaceFirst(RegExp(r'^\.'), '');

      if (fileExtension.isEmpty) {
        Toast.Toastmsg("Please select a valid service file.");
        return 2;
      }

      // Prepare optional extensions.
      String photoExtension =
      (PhotoExtension ?? "").trim().replaceFirst(RegExp(r'^\.'), '');

      String videoExtension =
      (VideoExtension ?? "").trim().replaceFirst(RegExp(r'^\.'), '');

      // API URL.
      const String url = Backend_Server_Url + "api/Profile/addserviceresources";

      // Create multipart request.
      final request = http.MultipartRequest(
        "POST",
        Uri.parse(url),
      );

      // Add authorization.
      request.headers["Authorization"] = "Bearer ${widget.User_JwtToken}";

      // Add required and normal fields.
      request.fields["ServiceTitle"] = Title.trim();
      request.fields["ProviderServiceId"] = serviceId.toString();
      request.fields["Email"] = widget.User_Email;

      // Add optional photo.
      if (ImageBytes != null && ImageBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "ServicePhoto",
            ImageBytes,
            filename: photoExtension.isNotEmpty
                ? "service_photo.$photoExtension"
                : "service_photo",
          ),
        );
      }

      // Add optional video.
      if (VideoBytes != null && VideoBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "ServiceVideo",
            VideoBytes,
            filename: videoExtension.isNotEmpty
                ? "service_video.$videoExtension"
                : "service_video",
          ),
        );
      }

      // Add mandatory service file.
      request.files.add(
        http.MultipartFile.fromBytes(
          "ServiceFile",
          FileBytes,
          filename: "service_file.$fileExtension",
        ),
      );

      // Send request.
      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      // Handle response.
      switch (response.statusCode) {
        case 200:
          Toast.Toastmsg("Service resources added successfully.");
          return 10;

        case 400:
          Toast.Toastmsg(
            "Invalid information. Check the title and selected file.",
          );
          return 4;

        case 401:
          Toast.Toastmsg("Unauthorized. Please log in again.");
          return 5;

        case 403:
          Toast.Toastmsg("You are not authorized to add service resources.");
          return 6;

        case 404:
          Toast.Toastmsg(
            "Service not found or does not belong to your account.",
          );
          return 7;

        case 502:
          Toast.Toastmsg("Provider account not found.");
          return 8;

        case 506:
          Toast.Toastmsg(
            "Your account has been blocked. Contact KaamMitra support.",
          );
          return 9;

        case 508:
          Toast.Toastmsg(
            "You can only add a maximum of 3 resources for this service.",
          );
          return 11;

        case 500:
          Toast.Toastmsg(
            "Server error while adding service resources. Please try again.",
          );
          return 12;

        default:
          Toast.Toastmsg(
            "Failed to add service resources. Please try again.",
          );
          return 13;
      }
    } catch (e) {
      Toast.Toastmsg(
        "Unable to add service resources. Check your connection and try again.",
      );
      return 0;
    }
  }

  // PICK PHOTO / VIDEO / FILE and CLEAR are your common methods:
  //   PickPhoto(), PickVideo(), PickFile(), ClearFilesValues()
  // (each one already shows its own success / format / size toasts).

  // ============================================================
  // SUBMIT — same logic/branches as before, wrapped with a GetX
  // loading state instead of any setState.
  // ============================================================

  Future<void> _onSubmitPressed() async {
    if (resourcesGetx.isSubmitting.value) return;

    resourcesGetx.setSubmitting(true);
    try {
      if (change_file_cont_getx.fileBytes.value != null ||
          ResourceTitleTextCont.text.toString().trim().isNotEmptyAndNotNull) {
        int Result = await AddServiceResources(
          ImageBytes: change_photo_cont_getx.imageBytes.value != null
              ? change_photo_cont_getx.imageBytes.value
              : null,
          VideoBytes: change_video_cont_getx.videoBytes.value != null
              ? change_video_cont_getx.videoBytes.value
              : null,
          SeviceId: ProviderServiceIdCont.text.trim(),
          PhotoExtension: change_photo_cont_getx.imageExtension.value != ""
              ? change_photo_cont_getx.imageExtension.value
              : "",
          VideoExtension: change_video_cont_getx.videoExtension.value != ""
              ? change_video_cont_getx.videoExtension.value
              : "",
          Title: ResourceTitleTextCont.text.trim(),
          FileBytes: change_file_cont_getx.fileBytes.value!,
          FileExtension: change_file_cont_getx.fileExtension.value!,
        );
        await ClearFilesValues();
        ResourceTitleTextCont.clear();

        if (Result == 1) {
          return;
        } else {
          return;
        }
      } else {
        Toast.Toastmsg(
            "Pick .pdf file and title and try again.Title and file are mandatory.Try again.");
        return;
      }
    } catch (exception) {
      return;
    } finally {
      resourcesGetx.setSubmitting(false);
    }
  }

  // ==========================================================================
  // UI-ONLY: confirm / cancel before adding (calls the unchanged logic above)
  // ==========================================================================

  Future<void> _confirmAndSubmit() async {
    try {
      if (resourcesGetx.isSubmitting.value) return;
      final bool ok = await _askConfirm();
      if (!ok) return;
      await _onSubmitPressed();
    } catch (e) {
      debugPrint('confirmAndSubmit error: $e');
    }
  }

  Future<bool> _askConfirm() async {
    try {
      final String id = ProviderServiceIdCont.text.trim();
      final String title = ResourceTitleTextCont.text.trim();
      final bool hasFile = change_file_cont_getx.fileBytes.value != null;
      final bool hasPhoto = change_photo_cont_getx.imageBytes.value != null;
      final bool hasVideo = change_video_cont_getx.videoBytes.value != null;

      Widget row(IconData icon, String label, String value, bool ok,
          {bool optional = false}) {
        final Color c = ok
            ? _Theme.emerald
            : (optional ? _Theme.mutedTextAlt : const Color(0xFFF87171));
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                ok
                    ? Icons.check_circle_rounded
                    : (optional
                    ? Icons.remove_circle_outline_rounded
                    : Icons.error_outline_rounded),
                color: c,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '$label  ',
                        style: const TextStyle(
                            color: _Theme.mutedTextAlt, fontSize: 12.5)),
                    TextSpan(
                        text: value,
                        style: const TextStyle(
                            color: _Theme.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }

      final bool? result = await Get.dialog<bool>(
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(18),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _Theme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _Theme.borderStrong),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _Theme.emerald.withOpacity(0.10),
                          border: Border.all(
                              color: _Theme.emerald.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.cloud_upload_rounded,
                            color: _Theme.mint, size: 26),
                      ),
                      const SizedBox(height: 14),
                      const Text('Add these resources?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _Theme.primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text(
                          'Please check the details below before uploading.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _Theme.mutedText,
                              fontSize: 13,
                              height: 1.4)),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _Theme.border),
                        ),
                        child: Column(
                          children: [
                            row(Icons.tag_rounded, 'Service ID',
                                id.isEmpty ? 'Missing' : id, id.isNotEmpty),
                            row(Icons.title_rounded, 'Title',
                                title.isEmpty ? 'Missing' : title,
                                title.isNotEmpty),
                            row(Icons.picture_as_pdf_rounded, 'File',
                                hasFile ? 'Selected' : 'Missing', hasFile),
                            row(Icons.image_rounded, 'Photo',
                                hasPhoto ? 'Selected' : 'Not added', hasPhoto,
                                optional: true),
                            row(Icons.videocam_rounded, 'Video',
                                hasVideo ? 'Selected' : 'Not added', hasVideo,
                                optional: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton(
                            onPressed: () => Get.back(result: false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _Theme.primaryText,
                              side: const BorderSide(
                                  color: _Theme.borderStrong, width: 1.3),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Get.back(result: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _Theme.emerald,
                              foregroundColor: _Theme.bgTop,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 13),
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Yes, add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );
      return result == true;
    } catch (e) {
      debugPrint('confirm dialog error: $e');
      return false;
    }
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final double topInset = media.padding.top + kToolbarHeight;

    return Scaffold(
      backgroundColor: _Theme.bgTop,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: _BorderIconButton(
            tooltip: 'Back',
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: const Text(
          'Add Service Resources',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: _Theme.primaryText,
              fontSize: 17,
              fontWeight: FontWeight.w700),
        ),
      ),
      body: _ForestBackdrop(
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: SafeArea(
            top: false,
            child: LayoutBuilder(builder: (context, c) {
              final double w = c.maxWidth.isFinite ? c.maxWidth : 360;
              final bool isMobile = w < 700;
              final bool wide = w >= 980;
              final double pad = isMobile ? 14 : (w < 1100 ? 28 : 40);
              const double minW = 280;

              final Widget page = SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints:
                    BoxConstraints(maxWidth: wide ? 1100 : 760),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          pad, 6, pad, isMobile ? 28 : 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _animatedSection(
                              animation: _heroAnim,
                              child: _buildHero(isMobile)),
                          SizedBox(height: isMobile ? 16 : 22),
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      _animatedSection(
                                          animation: _idAnim,
                                          child: _buildServiceIdCard(isMobile)),
                                      const SizedBox(height: 22),
                                      _animatedSection(
                                          animation: _detailsAnim,
                                          child: _buildDetailsCard(isMobile)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 22),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _animatedSection(
                                          animation: _mediaAnim,
                                          child: _buildMediaCard(isMobile)),
                                      const SizedBox(height: 22),
                                      _animatedSection(
                                          animation: _submitAnim,
                                          child: _buildSubmitCard(isMobile)),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _animatedSection(
                                animation: _idAnim,
                                child: _buildServiceIdCard(isMobile)),
                            SizedBox(height: isMobile ? 16 : 22),
                            _animatedSection(
                                animation: _detailsAnim,
                                child: _buildDetailsCard(isMobile)),
                            SizedBox(height: isMobile ? 16 : 22),
                            _animatedSection(
                                animation: _mediaAnim,
                                child: _buildMediaCard(isMobile)),
                            SizedBox(height: isMobile ? 16 : 22),
                            _animatedSection(
                                animation: _submitAnim,
                                child: _buildSubmitCard(isMobile)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );

              // Below the minimum width, allow sideways scroll instead of overflow.
              if (w >= minW) return page;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: minW, height: c.maxHeight, child: page),
              );
            }),
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
  // HERO
  // ============================================================

  Widget _buildHero(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 18 : 26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF193A29).withOpacity(0.85),
                const Color(0xFF12261C).withOpacity(0.75),
              ],
            ),
            border: Border.all(color: _Theme.borderStrong.withOpacity(0.8)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool compact = constraints.maxWidth < 560;

              final Widget texts = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _Theme.emerald.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(50),
                      border:
                      Border.all(color: _Theme.emerald.withOpacity(0.25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.perm_media_rounded,
                            color: _Theme.mint, size: 14),
                        SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            "Showcase your work",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _Theme.mint,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
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
                    "Add a title and a PDF file, plus an optional photo and "
                        "short video, so customers can see your work before they book.",
                    style: TextStyle(
                      color: _Theme.mutedText,
                      fontSize: isMobile ? 13 : 14.5,
                      height: 1.55,
                    ),
                  ),
                ],
              );

              if (compact) return texts;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: texts),
                  const SizedBox(width: 24),
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
                            color: _Theme.emerald.withOpacity(0.30),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _Theme.emerald.withOpacity(0.12),
                            blurRadius: 24,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.video_camera_back_rounded,
                          color: _Theme.mint, size: 32),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 1 — SERVICE ID
  // ============================================================

  Widget _buildServiceIdCard(bool isMobile) {
    return _StepCard(
      step: 1,
      icon: Icons.tag_rounded,
      title: "Service reference",
      subtitle: "Enter the ID of the service these resources belong to.",
      badge: "Required",
      isMobile: isMobile,
      child: GreenField(
        controller: ProviderServiceIdCont,
        label: "Enter service Id.",
        icon: Icons.tag_rounded,
      ),
    );
  }

  // ============================================================
  // STEP 2 — TITLE + FILE  (same card + same pick tile as photo/video)
  // ============================================================

  Widget _buildDetailsCard(bool isMobile) {
    return _StepCard(
      step: 2,
      icon: Icons.description_rounded,
      title: "Resource details",
      subtitle: "Give the resource a title and attach the PDF file.",
      badge: "Required",
      isMobile: isMobile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GreenField(
            controller: ResourceTitleTextCont,
            label: "Enter the title for resources.",
            icon: Icons.title,
          ),
          const SizedBox(height: 14),
          _pickTile(
            icon: Icons.picture_as_pdf_rounded,
            title: "Service file",
            subtitle: "Pick .pdf file for service resources",
            isPressedRx: resourcesGetx.isFileButtonPressed,
            onPressDown: () => resourcesGetx.setFileButtonPressed(true),
            onPressUp: () => resourcesGetx.setFileButtonPressed(false),
            onTap: PickFile,
            isSelected: () => change_file_cont_getx.fileBytes.value != null,
            selectedLabel: () {
              final String? e = change_file_cont_getx.fileExtension.value;
              return (e == null || e.isEmpty) ? "Selected" : "Selected  •  .${e.replaceFirst(RegExp(r'^\.'), '')}";
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 3 — PHOTO & VIDEO
  // ============================================================

  Widget _buildMediaCard(bool isMobile) {
    return _StepCard(
      step: 3,
      icon: Icons.perm_media_rounded,
      title: "Photo & video",
      subtitle: "Photo: .png .jpg .jpeg   •   Video: .mp4",
      badge: "Optional",
      optionalBadge: true,
      isMobile: isMobile,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool stack = constraints.maxWidth < 520;

          final Widget photoTile = _pickTile(
            icon: Icons.image_rounded,
            title: "Photo",
            subtitle: "Pick photo for service resources",
            isPressedRx: resourcesGetx.isPhotoButtonPressed,
            onPressDown: () => resourcesGetx.setPhotoButtonPressed(true),
            onPressUp: () => resourcesGetx.setPhotoButtonPressed(false),
            onTap: PickPhoto,
            isSelected: () => change_photo_cont_getx.imageBytes.value != null,
            selectedLabel: () {
              final String e = change_photo_cont_getx.imageExtension.value;
              return e.isEmpty ? "Selected" : "Selected  •  .${e.replaceFirst(RegExp(r'^\.'), '')}";
            },
          );

          final Widget videoTile = _pickTile(
            icon: Icons.videocam_rounded,
            title: "Showcase video",
            subtitle: "Pick video for service resources",
            isPressedRx: resourcesGetx.isVideoButtonPressed,
            onPressDown: () => resourcesGetx.setVideoButtonPressed(true),
            onPressUp: () => resourcesGetx.setVideoButtonPressed(false),
            onTap: PickVideo,
            isSelected: () => change_video_cont_getx.videoBytes.value != null,
            selectedLabel: () {
              final String e = change_video_cont_getx.videoExtension.value;
              return e.isEmpty ? "Selected" : "Selected  •  .${e.replaceFirst(RegExp(r'^\.'), '')}";
            },
          );

          if (stack) {
            return Column(
              children: [photoTile, const SizedBox(height: 12), videoTile],
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
    );
  }

  // ------------------------------------------------------------
  // ONE pick tile used for file, photo AND video — identical look.
  // Press feedback + selected state are fully reactive (GetX).
  // ------------------------------------------------------------

  Widget _pickTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required RxBool isPressedRx,
    required VoidCallback onPressDown,
    required VoidCallback onPressUp,
    required Future<void> Function() onTap,
    required bool Function() isSelected,
    required String Function() selectedLabel,
  }) {
    return Obx(() {
      final bool pressed = isPressedRx.value;
      final bool selected = isSelected();
      final String label = selected ? selectedLabel() : subtitle;

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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? _Theme.emerald.withOpacity(0.09)
                    : Colors.black.withOpacity(0.16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? _Theme.emerald.withOpacity(0.55)
                      : _Theme.borderStrong.withOpacity(0.7),
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                          colors: [_Theme.emerald, _Theme.mint])
                          : null,
                      color: selected ? null : _Theme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? null
                          : Border.all(color: _Theme.borderStrong),
                    ),
                    child: Icon(icon,
                        color: selected ? Colors.white : _Theme.mint,
                        size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _Theme.primaryText,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected ? _Theme.mint : _Theme.mutedText,
                            fontSize: 11.5,
                            height: 1.3,
                            fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.add_circle_outline_rounded,
                      key: ValueKey(selected),
                      color: selected ? _Theme.emerald : _Theme.mutedTextAlt,
                      size: 22,
                    ),
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
  // SUBMIT CARD — live checklist + confirm-before-add button
  // ============================================================

  Widget _buildSubmitCard(bool isMobile) {
    return _Glass(
      radius: 22,
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      tint: _Theme.emerald.withOpacity(0.07),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                child: Text(
                  "Upload resources",
                  style: TextStyle(
                    color: _Theme.primaryText,
                    fontSize: isMobile ? 15.5 : 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Live checklist (reacts to typing AND to picked files).
          AnimatedBuilder(
            animation: Listenable.merge(
                [ProviderServiceIdCont, ResourceTitleTextCont]),
            builder: (context, _) {
              return Obx(() {
                final bool hasId =
                    ProviderServiceIdCont.text.trim().isNotEmpty;
                final bool hasTitle =
                    ResourceTitleTextCont.text.trim().isNotEmpty;
                final bool hasFile =
                    change_file_cont_getx.fileBytes.value != null;
                final bool hasPhoto =
                    change_photo_cont_getx.imageBytes.value != null;
                final bool hasVideo =
                    change_video_cont_getx.videoBytes.value != null;

                final int done =
                    (hasId ? 1 : 0) + (hasTitle ? 1 : 0) + (hasFile ? 1 : 0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: done / 3),
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOut,
                              builder: (context, v, _) =>
                                  LinearProgressIndicator(
                                    value: v,
                                    minHeight: 6,
                                    color: _Theme.emerald,
                                    backgroundColor: _Theme.border,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          done == 3 ? "Ready" : "$done / 3 required",
                          style: TextStyle(
                            color: done == 3
                                ? _Theme.mint
                                : _Theme.mutedTextAlt,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ChecklistChip(label: "Service ID", ok: hasId),
                        _ChecklistChip(label: "Title", ok: hasTitle),
                        _ChecklistChip(label: "File", ok: hasFile),
                        _ChecklistChip(
                            label: "Photo", ok: hasPhoto, optional: true),
                        _ChecklistChip(
                            label: "Video", ok: hasVideo, optional: true),
                      ],
                    ),
                  ],
                );
              });
            },
          ),

          const SizedBox(height: 18),
          _submitButton(isMobile: isMobile),
          const SizedBox(height: 10),
          const Text(
            "You will be asked to confirm before anything is uploaded.",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _Theme.mutedTextAlt, fontSize: 11.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _submitButton({required bool isMobile}) {
    return Obx(() {
      final bool submitting = resourcesGetx.isSubmitting.value;
      final bool pressed = resourcesGetx.isSubmitButtonPressed.value;

      return AnimatedScale(
        scale: pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: submitting ? null : _confirmAndSubmit,
            onTapDown: (_) => resourcesGetx.setSubmitButtonPressed(true),
            onTapCancel: () => resourcesGetx.setSubmitButtonPressed(false),
            onTapUp: (_) => resourcesGetx.setSubmitButtonPressed(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 18 : 26,
                vertical: isMobile ? 15 : 16,
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
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
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
                    Flexible(
                      child: Text(
                        "Submitting...",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: semibold,
                          color: _Theme.primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 13.5 : 14.5,
                        ),
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.cloud_upload_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        "Add resources on service",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: semibold,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 13.5 : 14.5,
                        ),
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

// ===========================================================================
// REUSABLE UI PIECES
// ===========================================================================

/// Frosted-glass container.
class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (tint ?? Colors.white.withOpacity(0.08)),
                Colors.white.withOpacity(0.03),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A numbered section card: [1] Title + badge, subtitle, content.
class _StepCard extends StatelessWidget {
  final int step;
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final bool optionalBadge;
  final bool isMobile;
  final Widget child;

  const _StepCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.isMobile,
    required this.child,
    this.optionalBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return _Glass(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_Theme.emerald, _Theme.mint]),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text('$step',
                    style: const TextStyle(
                        color: _Theme.bgTop,
                        fontWeight: FontWeight.w900,
                        fontSize: 15)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _Theme.primaryText,
                        fontSize: isMobile ? 15.5 : 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: optionalBadge
                            ? Colors.white.withOpacity(0.06)
                            : _Theme.emerald.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: optionalBadge
                              ? _Theme.borderStrong
                              : _Theme.emerald.withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: optionalBadge
                              ? _Theme.mutedTextAlt
                              : _Theme.mint,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: _Theme.mint.withOpacity(0.7), size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: _Theme.mutedTextAlt,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ChecklistChip extends StatelessWidget {
  final String label;
  final bool ok;
  final bool optional;
  const _ChecklistChip(
      {required this.label, required this.ok, this.optional = false});

  @override
  Widget build(BuildContext context) {
    final Color c = ok
        ? _Theme.emerald
        : (optional ? _Theme.mutedTextAlt : const Color(0xFFF59E0B));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok
                ? Icons.check_circle_rounded
                : (optional
                ? Icons.remove_circle_outline_rounded
                : Icons.radio_button_unchecked_rounded),
            color: c,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            optional ? '$label (optional)' : label,
            style: TextStyle(
                color: ok ? _Theme.primaryText : c,
                fontSize: 11.5,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Bordered square icon button (used for the AppBar back arrow).
class _BorderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _BorderIconButton(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Theme.borderStrong, width: 1.3),
            ),
            child: Icon(icon, size: 18, color: _Theme.primaryText),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// BACKGROUND (private to this file)
// ===========================================================================

/// Dark forest base + soft emerald/mint ambient blobs + blurred glass bubbles.
/// - Purely decorative: wrapped in IgnorePointer, never blocks taps/text.
/// - Animation is driven by an AnimationController (no setState).
/// - Painted inside a RepaintBoundary so only the background repaints.
class _ForestBackdrop extends StatefulWidget {
  final Widget child;
  const _ForestBackdrop({super.key, required this.child});

  @override
  State<_ForestBackdrop> createState() => _ForestBackdropState();
}

class _ForestBackdropState extends State<_ForestBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 26))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF0F1F17)),
        IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: _ForestBackdropPainter(_ctrl), size: Size.infinite),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _ForestBackdropPainter extends CustomPainter {
  final Animation<double> t;
  _ForestBackdropPainter(this.t) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.width.isFinite || !size.height.isFinite) return;

    final double v = Curves.easeInOut.transform(t.value);
    final double rb = math.max(size.shortestSide, 360);

    // ---- Ambient blobs (radial gradients = cheap, very soft, no hard edge) ----
    void blob(double fx, double fy, double radius, Color c, double alpha,
        double dx, double dy) {
      final Offset center = Offset(
        size.width * fx + dx * v * rb * 0.08,
        size.height * fy + dy * v * rb * 0.08,
      );
      final Rect rect = Rect.fromCircle(center: center, radius: radius);
      final Paint p = Paint()
        ..shader = RadialGradient(
          colors: [
            c.withOpacity(alpha),
            c.withOpacity(alpha * 0.45),
            c.withOpacity(0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect);
      canvas.drawCircle(center, radius, p);
    }

    blob(-0.04, 0.04, rb * 0.80, const Color(0xFF22C55E), 0.22, 1.0, 0.7);
    blob(1.06, 0.32, rb * 0.70, const Color(0xFF34D399), 0.15, -1.0, 0.9);
    blob(0.08, 1.02, rb * 0.85, const Color(0xFF0F766E), 0.26, 0.8, -1.0);
    blob(0.96, 0.96, rb * 0.65, const Color(0xFF22C55E), 0.17, -0.9, -0.6);
    blob(0.50, 0.52, rb * 0.55, const Color(0xFF34D399), 0.05, 0.5, -0.5);

    // ---- Frosted glass bubbles ----
    void bubble(double fx, double fy, double r, double dy, double phase) {
      final double wave = math.sin((v + phase) * math.pi);
      final Offset c = Offset(
        size.width * fx,
        size.height * fy + wave * dy,
      );
      final Rect rect = Rect.fromCircle(center: c, radius: r);

      final Paint fill = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            Colors.white.withOpacity(0.12),
            const Color(0xFF34D399).withOpacity(0.05),
            Colors.white.withOpacity(0.015),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
      canvas.drawCircle(c, r, fill);

      final Paint ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withOpacity(0.09)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawCircle(c, r, ring);

      final Paint glint = Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(c.translate(-r * 0.35, -r * 0.38), r * 0.14, glint);
    }

    final double u = math.max(size.shortestSide, 320) / 400;
    bubble(0.12, 0.30, 46 * u, 18 * u, 0.0);
    bubble(0.86, 0.14, 30 * u, 14 * u, 0.3);
    bubble(0.92, 0.66, 64 * u, 22 * u, 0.55);
    bubble(0.20, 0.82, 36 * u, 16 * u, 0.8);
    bubble(0.62, 0.92, 22 * u, 10 * u, 0.15);
    bubble(0.05, 0.58, 18 * u, 10 * u, 0.65);
  }

  @override
  bool shouldRepaint(covariant _ForestBackdropPainter old) => false; // driven by `repaint`
}