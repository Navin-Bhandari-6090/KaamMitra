import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import '../../../constant/Server_Database.dart';
import '../../../state management/getx/profile/provider/add_fonepay_qr_getx.dart';
import '../../authentication/Error_page.dart';
import '../../common method/Commmon_Method.dart';
import '../../common widget/getx_cont_pick_single_photo_int.dart';
import '../../common widget/toast.dart';

/// =============================================================================
/// DARK GREEN PALETTE (kept identical across the app for brand consistency)
/// =============================================================================
class _Palette {
  static const Color bodyBg = Color(0xFF0F1F17);
  static const Color surface = Color(0xFF162E22);
  static const Color textPrimary = Color(0xFFE6F4EA);
  static const Color textMuted = Color(0xFF8A9A90);
  static const Color headerFooter = Color(0xFF12261C);
  static const Color accent = Color(0xFF22C55E);
  static const Color accentMint = Color(0xFF34D399);
  static const Color borderColor = Color(0xFF234232);
}

/// ---------------------------------------------------------------------------
/// GETX — UI-only reactive state for this screen. No setState anywhere.
/// isSubmitting drives the "Add photo" button's loading state; put/deleted
/// with a per-screen tag, same pattern used across the rest of the app.
/// ---------------------------------------------------------------------------


class AddUpdateFonepayQr extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;

  const AddUpdateFonepayQr({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});
  @override
  State<AddUpdateFonepayQr> createState() => _AddUpdateFonepayQrState();
}

class _AddUpdateFonepayQrState extends State<AddUpdateFonepayQr> with SingleTickerProviderStateMixin {
  final ImagePickCont=Get.put(pick_single_photo_getx_int());
  final Toast = Toastget();

  final String _tag = UniqueKey().toString();
  late final AddFonepayQrGetx submitCont;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;




  @override
  void initState() {
    super.initState();
    submitCont = Get.put(AddFonepayQrGetx(), tag: _tag);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));
    _entranceController.forward();

    Provider_Jwt_Verify(Jwt_Token: widget.User_JwtToken);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    Get.delete<AddFonepayQrGetx>(tag: _tag);
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
        context as BuildContext,
        MaterialPageRoute(builder: (context) => ErrorPage()),
            (route) => false,
      );
      Toastget().Toastmsg("Session End.Relogin please.");
      return;
    }
  }


  Future<int> AddFonepayQr({
    required String User_JwtToken,
    required String User_Email,
    required List<int> ImageBytes,
    required String PhotoExtension,
  }) async {
    try {
      // =========================================================
      // 1. Validate QR photo
      // =========================================================

      if (ImageBytes.isEmpty) {
        Toast.Toastmsg(
          'QR photo is required',
        );

        print(
          'QR photo data is required',
        );

        return 1;
      }

      // =========================================================
      // 2. Validate email
      // =========================================================

      if (User_Email.trim().isEmpty) {
        Toast.Toastmsg(
          'Provider email is required',
        );

        print(
          'Provider email is required',
        );

        return 3;
      }

      // =========================================================
      // 3. Validate photo extension
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
      // 4. Validate photo extension
      // =========================================================

      if (photoExtension != 'jpg' &&
          photoExtension != 'jpeg' &&
          photoExtension != 'png') {
        Toast.Toastmsg(
          'Invalid QR photo format.',
        );

        print(
          'Invalid QR photo extension: $photoExtension',
        );

        return 4;
      }

      // =========================================================
      // 5. Print information
      // =========================================================

      // print(
      //   "========== ADD FONEPAY QR ==========",
      // );
      //
      // print(
      //   "Provider Email: ${User_Email.trim()}",
      // );
      //
      // print(
      //   "QR Photo Size: ${ImageBytes.length} bytes",
      // );
      //
      // print(
      //   "QR Photo Extension: $photoExtension",
      // );
      //
      // print(
      //   "QR Photo Size: "
      //       "${(ImageBytes.length / (1024 * 1024)).toStringAsFixed(2)} MB",
      // );

      // =========================================================
      // 6. API URL
      // =========================================================

      const String url =
          Backend_Server_Url +
              "api/Profile/addfonepayqr";

      print(
        "API URL: $url",
      );

      // =========================================================
      // 7. Create multipart request
      // =========================================================

      final request = http.MultipartRequest(
        "POST",
        Uri.parse(url),
      );

      // =========================================================
      // 8. Authorization
      // =========================================================

      request.headers["Authorization"] =
      "Bearer $User_JwtToken";

      // =========================================================
      // 9. Normal form fields
      // =========================================================

      request.fields["ProviderEmail"] =
          User_Email.trim();

      // =========================================================
      // 10. Add QR photo
      // =========================================================

      request.files.add(
        http.MultipartFile.fromBytes(
          "QRPhoto",
          ImageBytes,
          filename: "qr_photo.$photoExtension",
        ),
      );

      // =========================================================
      // 11. Print multipart information
      // =========================================================

      print(
        "Multipart request created.",
      );

      print(
        "QR filename: qr_photo.$photoExtension",
      );

      print(
        "Uploading Fonepay QR...",
      );

      // =========================================================
      // 12. Send request
      // =========================================================

      final streamedResponse =
      await request.send();

      // =========================================================
      // 13. Convert response
      // =========================================================

      final response =
      await http.Response.fromStream(
        streamedResponse,
      );

      // =========================================================
      // 14. Print response
      // =========================================================

      // print(
      //   "Response status: ${response.statusCode}",
      // );
      //
      // print(
      //   "Response body: ${response.body}",
      // );

      // =========================================================
      // 15. Success
      // =========================================================

      if (response.statusCode == 200) {
        Toast.Toastmsg(
          'Fonepay QR added successfully.',
        );

        print(
          'Fonepay QR added successfully.',
        );

        ImagePickCont.imageExtension.value="";
        ImagePickCont.imageBytes.value=null;
        ImagePickCont.imagePath;

        return 1;
      }

      // =========================================================
      // 16. Bad request
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
      // 17. Provider not found
      // =========================================================

      if (response.statusCode == 404) {
        Toast.Toastmsg(
          response.body,
        );

        print(
          "Provider not found: ${response.body}",
        );

        return 5;
      }

      // =========================================================
      // 18. Unauthorized
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
      // 19. Forbidden
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
      // 20. Server error
      // =========================================================

      if (response.statusCode == 500) {
        Toast.Toastmsg(
          "Server error while saving Fonepay QR.",
        );

        print(
          "Server error: ${response.body}",
        );

        return 8;
      }

      // =========================================================
      // 21. Other status
      // =========================================================

      print(
        "Unexpected status code: ${response.statusCode}",
      );

      Toast.Toastmsg(
        'Add Fonepay QR failed.',
      );

      return 9;
    } catch (e) {
      // =========================================================
      // 22. Exception
      // =========================================================

      print(
        "Exception caught while adding Fonepay QR.",
      );

      print(
        "Exception: ${e.toString()}",
      );

      Toast.Toastmsg(
        'Add Fonepay QR failed.',
      );

      return 0;
    }
  }

  // ---------------------------------------------------------------------
  // Responsive helpers (identical pattern to the rest of the app)
  // ---------------------------------------------------------------------
  double _horizontalPadding(double width) {
    if (width < 420) return 18;
    if (width < 700) return 32;
    if (width < 1100) return 60;
    return (width - 1100) / 2 + 80;
  }

  double _cardMaxWidth(double width, Orientation orientation) {
    if (width < 500) return double.infinity;
    if (orientation == Orientation.landscape && width < 900) return 520;
    return 560;
  }

  Widget _glowBlob(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [BoxShadow(color: color, blurRadius: 130, spreadRadius: 46)],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF16301F),
                _Palette.bodyBg,
                Color(0xFF0B1712),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        Positioned(top: -70, right: -60, child: _glowBlob(_Palette.accent.withOpacity(0.15), 250)),
        Positioned(top: 260, left: -100, child: _glowBlob(_Palette.accentMint.withOpacity(0.09), 220)),
        Positioned(bottom: -100, right: -70, child: _glowBlob(_Palette.accent.withOpacity(0.11), 250)),
        Positioned(bottom: 120, left: -70, child: _glowBlob(_Palette.accentMint.withOpacity(0.09), 220)),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _Palette.headerFooter,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 14,
      leadingWidth: 64,
      leading: Builder(
        builder: (context) {
          if (!Navigator.of(context).canPop()) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Center(
              child: Material(
                color: _Palette.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _Palette.accent.withOpacity(0.55), width: 1.4),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    // Bordered container + primary-text-colored arrow so the
                    // back action stays clearly visible on the dark surface.
                    child: Icon(Icons.arrow_back_rounded, color: _Palette.textPrimary, size: 20),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_Palette.accent, _Palette.accentMint]),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(color: _Palette.accent.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 5)),
              ],
            ),
            child: const Icon(Icons.qr_code_2_rounded, color: _Palette.bodyBg, size: 19),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              'Fonepay QR',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: _Palette.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePickImage() async {
    try {
      final PhotoResult = await ImagePickCont.pickImage();
      if (PhotoResult == 1)
      {
        Toast.Toastmsg("Pick photo success.");
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
        Toast.Toastmsg("Pick photo  fail.");
        return;
      }
    }catch(e){
      Toast.Toastmsg("Pick photo  fail.");
      return;
    }
  }

  Future<void> _handleSubmit() async {
    if (submitCont.isSubmitting.value) return;
    submitCont.setSubmitting(true);
    try{
      int result= await AddFonepayQr
        (
          User_Email: widget.User_Email,
          ImageBytes: ImagePickCont.imageBytes.value!,
          User_JwtToken: widget.User_JwtToken,
          PhotoExtension: ImagePickCont.imageExtension.value
      );
    }catch(e){
      Toast.Toastmsg("Try again.Server error.");
    } finally {
      submitCont.setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bodyBg,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, outer) {
          final Orientation orientation = MediaQuery.of(context).orientation;
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final double horizontalPadding = _horizontalPadding(width);
                final double cardMaxWidth = _cardMaxWidth(width, orientation);

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: outer.maxHeight),
                    child: Stack(
                      children: [
                        Positioned.fill(child: _buildBackground()),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 28,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: cardMaxWidth),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildCard(width),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Preview / drop-zone for the picked QR image. Reactive on the existing
  // ImagePickCont Rx state — no setState.
  // ---------------------------------------------------------------------
  Widget _buildImagePreviewZone(double width) {
    return Obx(() {
      final bytes = ImagePickCont.imageBytes.value;
      final bool hasImage = bytes != null && bytes.isNotEmpty;
      final double zoneHeight = width < 420 ? 190 : 230;

      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _handlePickImage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: zoneHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _Palette.bodyBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasImage ? _Palette.accent.withOpacity(0.55) : _Palette.borderColor,
                width: hasImage ? 1.6 : 1.3,
              ),
              image: hasImage
                  ? DecorationImage(
                image: MemoryImage(Uint8List.fromList(bytes)),
                fit: BoxFit.contain,
              )
                  : null,
            ),
            child: hasImage
                ? Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _Palette.headerFooter.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _Palette.accentMint.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded, color: _Palette.accentMint, size: 14),
                      const SizedBox(width: 6),
                      const Text(
                        'Tap to change',
                        style: TextStyle(color: _Palette.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_Palette.accent.withOpacity(0.2), _Palette.accentMint.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _Palette.accent.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: _Palette.accentMint, size: 26),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tap to select your Fonepay QR',
                  style: TextStyle(
                    color: _Palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'PNG, JPG or JPEG',
                  style: TextStyle(color: _Palette.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCard(double width) {
    return Container(
      padding: EdgeInsets.all(width < 420 ? 20 : 30),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Palette.borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Icon badge ---
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_Palette.accent.withOpacity(0.22), _Palette.accentMint.withOpacity(0.12)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _Palette.accent.withOpacity(0.4)),
            ),
            child: const Icon(Icons.qr_code_2_rounded, color: _Palette.accentMint, size: 28),
          ),
          const SizedBox(height: 18),
          Text(
            'Add / Update Fonepay QR',
            style: TextStyle(
              color: _Palette.textPrimary,
              fontSize: width < 420 ? 20 : 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload a clear photo of your Fonepay QR code so customers can pay you directly.',
            style: TextStyle(color: _Palette.textMuted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 22),

          _fieldLabel('QR Photo'),
          const SizedBox(height: 8),
          _buildImagePreviewZone(width),

          const SizedBox(height: 14),

          // --- Hint ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: _Palette.textMuted.withOpacity(0.85), size: 15),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Use a well-lit, uncropped photo of the QR code for best scan accuracy.',
                  style: TextStyle(color: _Palette.textMuted, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // --- Pick image button (outlined, secondary) ---
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _handlePickImage,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: _Palette.bodyBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _Palette.accentMint.withOpacity(0.55), width: 1.4),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded, color: _Palette.accentMint, size: 18),
                      SizedBox(width: 9),
                      Text(
                        'Pick Fonepay QR Image',
                        style: TextStyle(
                          color: _Palette.accentMint,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // --- Submit button (primary, gradient) ---
          Obx(() {
            final bool submitting = submitCont.isSubmitting.value;
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: submitting ? null : _handleSubmit,
                child: Ink(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: submitting
                          ? [_Palette.accent.withOpacity(0.5), _Palette.accentMint.withOpacity(0.5)]
                          : [_Palette.accent, _Palette.accentMint],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: submitting
                        ? []
                        : [
                      BoxShadow(
                        color: _Palette.accent.withOpacity(0.32),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: submitting
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        valueColor: AlwaysStoppedAnimation<Color>(_Palette.bodyBg),
                      ),
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.cloud_upload_rounded, color: _Palette.bodyBg, size: 19),
                        SizedBox(width: 8),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            color: _Palette.bodyBg,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // --- Footer note ---
          Row(
            children: [
              Icon(Icons.verified_user_rounded, color: _Palette.textMuted.withOpacity(0.8), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "This QR is shown only to customers paying for your services.",
                  style: TextStyle(color: _Palette.textMuted, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: const TextStyle(color: _Palette.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600));
  }
}