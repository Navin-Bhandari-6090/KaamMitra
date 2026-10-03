import 'dart:convert';
import 'dart:math';

import 'package:app/web/common%20widget/GreenTextfield.dart';
import 'package:app/web/common%20widget/toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';

import '../../constant/Server_Database.dart';
import '../../constant/variable.dart';
import '../../models/BookingInfoModel.dart';
import '../../state management/getx/booking/user_booking_details_getx.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/getx_cont_pick_single_photo_int.dart';

// ============================================================
// PALETTE — Dark Forest / Emerald Glow theme
// ============================================================
class _Palette {
  static const bodyBg = Color(0xFF0F1F17);
  static const surface = Color(0xFF162E22);
  static const primaryText = Color(0xFFE6F4EA);
  static const mutedText = Color(0xFF8A9A90);
  static const headerFooter = Color(0xFF12261C);
  static const accent = Color(0xFF22C55E);
  static const accentMint = Color(0xFF34D399);
  static const borderColor = Color(0xFF234232);
}

class Userbookinginfodetailsscreen extends StatefulWidget {
  final String Current_User_Email;
  final String Current_User_JwtToken;
  final String Current_User_Role;
  final List<BookingInfoModel> BookingInfoListInfo;

  Userbookinginfodetailsscreen({super.key, required this.Current_User_Email, required this.Current_User_JwtToken, required this.Current_User_Role, required this.BookingInfoListInfo});

  @override
  State<Userbookinginfodetailsscreen> createState() => _UserbookinginfodetailsscreenState();
}

class _UserbookinginfodetailsscreenState extends State<Userbookinginfodetailsscreen>
    with TickerProviderStateMixin {

  final RatingValueCont=TextEditingController();

  final Toast=Toastget();



  final AdvancePayPhoGetxCont=Get.put(UserBookingDetailsGetx());

  // ---- UI-only additions below: entrance + ambient bubble animation ----
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final AnimationController _bubbleCtrl;
  final RxBool _ratingFocusedRx = false.obs;

  void initState() {
    // TODO: implement initState
    super.initState();
    User_Jwt_Verify(Jwt_Token: widget.Current_User_JwtToken);
    print("Booking info list length = ${widget.BookingInfoListInfo.length}");

    // ---- UI-only: entrance + bubble animation setup ----
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));
    _entranceCtrl.forward();

    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose()
  {
    change_photo_cont_getx.imageBytes.value=null;
    change_photo_cont_getx.imageExtension.value="";
    change_photo_cont_getx.imagePath.value="";

    // ---- UI-only: dispose animation controllers (must happen
    // before super.dispose(), or their Tickers leak/assert) ----
    _entranceCtrl.dispose();
    _bubbleCtrl.dispose();

    super.dispose();
  }

  Future<void> User_Jwt_Verify({required String Jwt_Token}) async {
    try {
      int Result = await UserJwtVerify(Jwt_Token: Jwt_Token);
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
    } catch (e) {
      // Defensive fallback only — an unexpected failure here shouldn't
      // crash the screen; surface a toast instead so the person knows
      // something went wrong.
      print("Unexpected error in Provider_Jwt_Verify: $e");
      Toastget().Toastmsg("Something went wrong. Please try again.");
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

  Future<int> UploadAdvancePaymentPhoto({
    required num BookId,
    required List<int> ImageBytes,
    required String UserJwtToken,
    required String PhotoExtension,
  }) async {
    try {
      // =========================================================
      // 1. Validate BookId
      // =========================================================

      if (BookId <= 0) {
        Toast.Toastmsg("Invalid BookId.");
        print("Invalid BookId: $BookId");
        return 1;
      }

      // =========================================================
      // 2. Validate photo
      // =========================================================

      if (ImageBytes.isEmpty) {
        Toast.Toastmsg("Payment photo is required.");
        print("Payment photo is required.");
        return 2;
      }

      // =========================================================
      // 3. Validate photo extension
      // =========================================================

      final String photoExtension =
      PhotoExtension.trim().toLowerCase().replaceFirst('.', '');

      if (photoExtension.isEmpty) {
        Toast.Toastmsg("Photo extension is required.");
        print("Photo extension is required.");
        return 3;
      }

      // =========================================================
      // 4. Validate allowed extension
      // =========================================================

      if (photoExtension != "jpg" &&
          photoExtension != "jpeg" &&
          photoExtension != "png") {
        Toast.Toastmsg(
          "Invalid photo format. Only JPG, JPEG and PNG are allowed.",
        );

        print(
          "Invalid photo format: $photoExtension",
        );

        return 3;
      }

      // =========================================================
      // 5. Print information
      // =========================================================

      print(
        "========== UPLOAD ADVANCE PAYMENT PHOTO ==========",
      );

      print("BookId: $BookId");
      print("Photo Size: ${ImageBytes.length} bytes");
      print("Photo Extension: $photoExtension");

      // =========================================================
      // 6. API URL
      // =========================================================

      const String url =
          Backend_Server_Url +
              "api/Booking/uploadadvancepaymentphoto";

      print("API URL: $url");

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
      "Bearer $UserJwtToken";

      // =========================================================
      // 9. Add BookId
      // =========================================================

      request.fields["BookId"] =
          BookId.toInt().toString();

      // =========================================================
      // 10. Add payment photo
      // =========================================================

      request.files.add(
        http.MultipartFile.fromBytes(
          "PaymentPhoto",
          ImageBytes,
          filename: "payment_photo.$photoExtension",
        ),
      );

      print(
        "Payment photo filename: payment_photo.$photoExtension",
      );

      print("Uploading advance payment photo...");

      // =========================================================
      // 11. Send request
      // =========================================================

      final streamedResponse =
      await request.send();

      // =========================================================
      // 12. Convert response
      // =========================================================

      final response =
      await http.Response.fromStream(
        streamedResponse,
      );

      // =========================================================
      // 13. Print response
      // =========================================================

      print(
        "Response status: ${response.statusCode}",
      );

      print(
        "Response body: ${response.body}",
      );

      // =========================================================
      // 14. Success
      // =========================================================

      if (response.statusCode == 200) {
        Toast.Toastmsg(
          "Advance payment photo uploaded successfully.",
        );

        print(
          "Advance payment photo uploaded successfully.",
        );

        change_photo_cont_getx.imageBytes.value=null;
        change_photo_cont_getx.imageExtension.value="";
        change_photo_cont_getx.imagePath.value="";

        return 0;
      }

      // =========================================================
      // 15. Invalid data
      // =========================================================

      if (response.statusCode == 400) {
        Toast.Toastmsg(response.body);

        print(
          "Invalid data: ${response.body}",
        );

        return 4;
      }

      // =========================================================
      // 16. Booking not found
      // =========================================================

      if (response.statusCode == 404) {
        Toast.Toastmsg(response.body);

        print(
          "Booking not found: ${response.body}",
        );

        return 5;
      }

      // =========================================================
      // 17. Unauthorized
      // =========================================================

      if (response.statusCode == 401) {
        Toast.Toastmsg(
          "Unauthorized. Please login again.",
        );

        print("Unauthorized.");

        return 6;
      }

      // =========================================================
      // 18. Forbidden
      // =========================================================

      if (response.statusCode == 403) {
        Toast.Toastmsg(
          "You are not authorized.",
        );

        print("Forbidden.");

        return 7;
      }

      // =========================================================
      // 19. Server error
      // =========================================================

      if (response.statusCode == 500) {
        Toast.Toastmsg(
          "Server error while uploading payment photo.",
        );

        print(
          "Server error: ${response.body}",
        );

        return 8;
      }

      // =========================================================
      // 20. Other status
      // =========================================================

      print(
        "Unexpected status code: ${response.statusCode}",
      );

      Toast.Toastmsg(
        "Upload failed. Try again.",
      );

      return 9;
    } catch (obj) {
      print(
        "Exception caught while uploading advance payment photo.",
      );

      print(obj.toString());

      Toast.Toastmsg(
        "Upload failed. Try again.",
      );

      return 10;
    }
  }


  Future<int> UpdateRating({
    required String RatingGiver,
    required num BookId,
    required String RatingReceiver,
    required int RatingValue,
    required String ServiceName,
  }) async {
    try {
      final Map<String, dynamic> userData = {
        "RatingGiver": RatingGiver,
        "BookId": BookId,
        "RatingReceiver":RatingReceiver,
        "RatingValue":RatingValue,
        "ServiceName":ServiceName
      };
      const String url =
          Backend_Server_Url + "api/Booking/updateuserrating";
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.Current_User_JwtToken}',
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        print("Update success");
        Toast.Toastmsg("Update success.");
        return 1;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg(
          "Update fail.Try again.Server error.",
        );
        print("Update  fail.Try again.Server error.");
        print("SERVER ERROR: ${response.body}");
        return 2;
      } else if (response.statusCode == 502) {
        Toast.Toastmsg("Current user doesn't match.");
        print("Current user doesn't match.");
        await Clear_User_Data();
        await Random_token_Clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ErrorPage()),
              (route) => false,
        );
        Toastget().Toastmsg("Session End.Relogin please.");
        return 3;
      } else if (response.statusCode == 503) {
        Toast.Toastmsg(
          "No booking available of that book id.",
        );
        print("No  data available of that book id.");
        return 4;
      }
      else if (response.statusCode == 501) {
        Toast.Toastmsg(
          "Invalid data format.Please provide data in correct format.",
        );
        print(
          "Invalid data format.Please provide data in correct format.",
        );
        return 5;
      } else {
        print("Other status code.Error.");
        print("Status code = ${response.statusCode}");
        print("Response body = ${response.body}");
        Toast.Toastmsg(
          "Update fail.Try again.Server error.",
        );
        return 6;
      }
    } catch (Obj) {
      print("Exception caught.");
      print(Obj.toString());
      Toast.Toastmsg(
        "Update fail.Try again.Server error.",
      );
      return 7;
    }
  }



  Future<int> UpdateUserApprovalStatus({
    required String UserEmail,
    required num BookId,
  }) async {
    try {
      final Map<String, dynamic> userData = {
        "UserEmail": UserEmail,
        "BookId": BookId,
      };
      const String url =
          Backend_Server_Url + "api/Booking/updateuserapprovalstatus";
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.Current_User_JwtToken}',
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        print("Update success");
        Toast.Toastmsg("Update success.");
        return 1;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg(
          "Update fail.Try again.Server error.",
        );
        print("Update  fail.Try again.Server error.");
        print("SERVER ERROR: ${response.body}");
        return 2;
      } else if (response.statusCode == 502) {
        Toast.Toastmsg("Current user doesn't match.");
        print("Current user doesn't match.");
        await Clear_User_Data();
        await Random_token_Clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ErrorPage()),
              (route) => false,
        );
        Toastget().Toastmsg("Session End.Relogin please.");
        return 3;
      } else if (response.statusCode == 503) {
        Toast.Toastmsg(
          "No booking available of that book id.",
        );
        print("No  data available of that book id.");
        return 4;
      }
      else if (response.statusCode == 504) {
        Toast.Toastmsg("You have already accept it.You cannot update approval status.");
        print("You have already accept it.You cannot update approval status.");
        return 8;
      }
      else if (response.statusCode == 501) {
        Toast.Toastmsg(
          "Invalid  approval status data format.Please provide data in correct format.",
        );
        print(
          "Invalid  approval status data format.Please provide data in correct format.",
        );
        return 5;
      } else {
        print("Other status code.Error.");
        print("Status code = ${response.statusCode}");
        Toast.Toastmsg(
          "Update fail.Try again.Server error.",
        );
        return 6;
      }
    } catch (Obj) {
      print("Exception caught while Updating  approval status .");
      print(Obj.toString());
      Toast.Toastmsg(
        "Update  approval status  fail.Try again.Server error.",
      );
      return 7;
    }
  }

  Future<int> UserRequestTaskComplete({
    required String UserEmail,
    required num BookId,
  }) async {
    try {
      final Map<String, dynamic> userData = {
        "UserEmail": UserEmail,
        "BookId": BookId,
      };
      const String url =
          Backend_Server_Url + "api/Booking/userupdatetaskcompletestatus";
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.Current_User_JwtToken}',
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        print("Update  task complete status info success");
        Toast.Toastmsg("Update  task complete status success.");
        return 1;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg(
          "Update  task complete status   fail.Try again.Server error.",
        );
        print(
          "Update  task complete status   fail.Try again.Server error.",
        );
        print("SERVER ERROR: ${response.body}");
        return 2;
      } else if (response.statusCode == 502) {
        Toast.Toastmsg("Current user doesn't match.");
        print("Current user doesn't match.");
        await Clear_User_Data();
        await Random_token_Clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ErrorPage()),
              (route) => false,
        );
        Toastget().Toastmsg("Session End.Relogin please.");
        return 3;
      } else if (response.statusCode == 503) {
        Toast.Toastmsg("No booking data  available of that book id.");
        print("No booking data   data available of taht book id.");
        return 4;
      }
      else if (response.statusCode == 504) {
        Toast.Toastmsg("You have already change.You cannot update task complete status.");
        print("You have already change.You cannot update task complete status.");
        return 8;
      }

      else if (response.statusCode == 501) {
        Toast.Toastmsg(
          "Invalid  task complete data format.Please provide data in correct format.",
        );
        print(
          "Invalid  task complete data format.Please provide data in correct format.",
        );
        return 5;
      } else {
        print("Other status code.Error.");
        print("Status code = ${response.statusCode}");
        Toast.Toastmsg(
          "Update  task complete status  fail.Try again.Server error.",
        );
        return 6;
      }
    } catch (Obj) {
      print("Exception caught while Updating  task complete status .");
      print(Obj.toString());
      Toast.Toastmsg(
        "Update  task complete status  fail.Try again.Server error.",
      );
      return 7;
    }
  }

  // ============================================================
  // BUILD — visual redesign only. Every onPressed body below is
  // the exact original logic, just wrapped in new UI containers.
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final cardMaxWidth = min(size.width * 0.94, 640.0);
    final horizontalPad = size.width < 420 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: _Palette.bodyBg,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // ---- ambient organic bubble background ----
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bubbleCtrl,
              builder: (context, _) => CustomPaint(
                painter: _BubblePainter(progress: _bubbleCtrl.value),
              ),
            ),
          ),

          // ---- main responsive scroll content ----
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPad,
                    vertical: orientation == Orientation.portrait ? 26 : 14,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: max(
                        0.0,
                        constraints.maxHeight -
                            (orientation == Orientation.portrait ? 52 : 28),
                      ),
                    ),
                    child: Center(
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: cardMaxWidth),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildScreenHeader(),
                                const SizedBox(height: 22),

                                _buildSectionCard(
                                  icon: Icons.info_outline_rounded,
                                  title: "Booking Details",
                                  subtitle: "Everything about this booking at a glance.",
                                  child: _buildBookingInfoSection(),
                                ),
                                const SizedBox(height: 16),

                                _buildSectionCard(
                                  icon: Icons.star_rate_rounded,
                                  title: "Rate this service",
                                  subtitle: "Share feedback from 1 to 10.",
                                  child: _buildRatingSection(),
                                ),
                                const SizedBox(height: 16),

                                _buildSectionCard(
                                  icon: Icons.verified_rounded,
                                  title: "Booking Approval",
                                  subtitle: "Confirm you approve this booking.",
                                  child: _buildApprovalSection(),
                                ),
                                const SizedBox(height: 16),

                                _buildSectionCard(
                                  icon: Icons.task_alt_rounded,
                                  title: "Task Completion",
                                  subtitle: "Let the provider know the task is done.",
                                  child: _buildTaskCompleteSection(),
                                ),
                                const SizedBox(height: 16),

                                _buildSectionCard(
                                  icon: Icons.receipt_long_rounded,
                                  title: "Advance Payment Photo",
                                  subtitle: "Upload proof of your advance payment.",
                                  child: _buildAdvancePaymentUploadSection(),
                                ),
                                const SizedBox(height: 16),

                                _buildSectionCard(
                                  icon: Icons.qr_code_2_rounded,
                                  title: "Payment QR Code",
                                  subtitle: "Scan to pay the service provider.",
                                  child: _buildQrPreview(),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // App bar — bordered, clearly visible back arrow
  // ---------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _Palette.headerFooter,
      elevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _Palette.primaryText, width: 1.4),
                  color: _Palette.surface,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: _Palette.primaryText,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
      title: const Text(
        "Booking Details",
        style: TextStyle(
          color: _Palette.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 19,
          letterSpacing: 0.2,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _Palette.borderColor),
      ),
    );
  }

  // ---------------------------------------------------------
  // Screen header badge + title
  // ---------------------------------------------------------
  Widget _buildScreenHeader() {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (context, value, child) =>
              Transform.scale(scale: 0.7 + (0.3 * value), child: child),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_Palette.accent, _Palette.accentMint],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _Palette.accent.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.event_note_rounded, color: _Palette.bodyBg, size: 28),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          "Manage Your Booking",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _Palette.primaryText,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Rate, approve, complete and upload payment proof —\nall in one place.",
          textAlign: TextAlign.center,
          style: TextStyle(color: _Palette.mutedText, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // Reusable glass-style section card
  // ---------------------------------------------------------
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: _Palette.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Palette.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: LinearGradient(
                    colors: [
                      _Palette.accent.withOpacity(0.22),
                      _Palette.accentMint.withOpacity(0.16),
                    ],
                  ),
                  border: Border.all(color: _Palette.borderColor),
                ),
                child: Icon(icon, color: _Palette.accentMint, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _Palette.primaryText,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _Palette.mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // Booking Details — read-only display of every field on
  // BookingInfoModel except userEmail / providerEmail.
  // ---------------------------------------------------------
  Widget _buildBookingInfoSection() {
    final booking = widget.BookingInfoListInfo[0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoGroupHeader("Service"),
        _buildInfoRow("Service name", booking.serviceName?.toString()),
        _buildInfoRow("Booking ID", booking.bookId?.toString()),
        _buildInfoRow("Distance", booking.distance != null ? "${booking.distance} km" : null),
        _buildInfoRow("Created at", booking.createdAt?.toString()),

        _buildInfoGroupHeader("Schedule & Payment"),
        _buildInfoRow("Start date", booking.startDate?.toString()),
        _buildInfoRow("End date", booking.endDate?.toString()),
        _buildInfoRow("Advance payment amount", booking.advancePaymentAmount?.toString()),
        _buildStatusRow("Advance payment required", booking.requiredAdvancePayment),

        _buildInfoGroupHeader("Status"),
        _buildStatusRow("Provider approval status", booking.providerApprovalStatus),
        _buildStatusRow("User approval status", booking.userApprovalStatus),
        _buildStatusRow("Provider task complete status", booking.providerTaskCompleteStatus),
        _buildStatusRow("User task complete status", booking.userTaskCompleteStatus),

        _buildInfoGroupHeader("Your Details"),
        _buildInfoRow("Address", booking.userAddress?.toString()),
        _buildInfoRow("Phone number", booking.userPhoneNumber?.toString()),
        _buildInfoRow("WhatsApp number", booking.userWhatsappPhoneNumber?.toString()),
        _buildInfoRow("Contact number", booking.userNumber?.toString()),
        _buildInfoRow("Latitude", booking.userLatitude?.toString()),
        _buildInfoRow("Longitude", booking.userLongitude?.toString()),
        _buildInfoRow("Booking description", booking.userBookingDescription?.toString()),

        _buildInfoGroupHeader("Provider Details"),
        _buildInfoRow("Address", booking.providerAddress?.toString()),
        _buildInfoRow("Phone number", booking.providerPhoneNumber?.toString()),
        _buildInfoRow("WhatsApp number", booking.providerWhatsappPhoneNumber?.toString()),
        _buildInfoRow("Contact number", booking.providerNumber?.toString()),
        _buildInfoRow("Latitude", booking.providerLatitude?.toString()),
        _buildInfoRow("Longitude", booking.providerLongitude?.toString()),
        _buildInfoRow("Booking description", booking.providerBookingDescription?.toString(), isLast: true),
      ],
    );
  }

  Widget _buildInfoGroupHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _Palette.accentMint,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: _Palette.accentMint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, {bool isLast = false}) {
    final displayValue = (value == null || value.trim().isEmpty || value == "null")
        ? "Not provided"
        : value;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(color: _Palette.borderColor.withOpacity(0.6), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(color: _Palette.mutedText, fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _Palette.primaryText,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool? value) {
    final known = value != null;
    final isTrue = value == true;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _Palette.borderColor.withOpacity(0.6), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _Palette.mutedText, fontSize: 12.5),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: known
                  ? (isTrue ? _Palette.accent.withOpacity(0.16) : _Palette.headerFooter)
                  : _Palette.headerFooter,
              border: Border.all(
                color: known && isTrue ? _Palette.accentMint : _Palette.borderColor,
              ),
            ),
            child: Text(
              known ? (isTrue ? "Yes" : "No") : "N/A",
              style: TextStyle(
                color: known && isTrue ? _Palette.accentMint : _Palette.mutedText,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // Rating section — logic identical to original onPressed body
  // ---------------------------------------------------------
  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextInput(
          controller: RatingValueCont,
          label: "Enter rating value (1-10)",
          icon: Icons.rate_review_rounded,
          focusedRx: _ratingFocusedRx,
          onFocusChange: (v) => _ratingFocusedRx.value = v,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        _buildPrimaryButton(
          label: "Submit rating",
          icon: Icons.send_rounded,
          onTap: () async {
            try {
              int? RtaingValue = int.tryParse(RatingValueCont.text.trim());

              if (RtaingValue! <= 0 || RtaingValue >= 11) {
                Toast.Toastmsg("Enter rating value from 1-10.");
                return;
              }

              if (RatingValueCont.text
                  .trim()
                  .isEmptyOrNull) {
                Toast.Toastmsg("Enter rating value from 1-10.");
                return;
              }

              final RatingAddResult = await UpdateRating(
                  RatingGiver: widget.Current_User_Email,
                  BookId: widget.BookingInfoListInfo[0].bookId!,
                  RatingReceiver: widget.BookingInfoListInfo[0]
                      .providerEmail!,
                  RatingValue: RtaingValue,
                  ServiceName: widget.BookingInfoListInfo[0].serviceName!);
            }catch(obj){
              print(obj.toString());
              return;
            }
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // Approval section — logic identical to original onPressed body
  // ---------------------------------------------------------
  Widget _buildApprovalSection() {
    return _buildPrimaryButton(
      label: "Change user approval status",
      icon: Icons.check_circle_outline_rounded,
      onTap: () async {
        try {
          final BookIdValue=widget.BookingInfoListInfo[0].bookId!;

          final ApprovalResult =await UpdateUserApprovalStatus(
            UserEmail: widget.Current_User_Email,
            BookId: BookIdValue,
          );

          print(
            " approval update result = ${ApprovalResult}",
          );

          final AddNotificationsResult = await AddNotifications(
            ReceiverNumber: widget.BookingInfoListInfo[0].providerNumber!,
            Message:
            "User have change approval status for the booking id = ${BookIdValue}.",
            Current_User_JwtToken: widget.Current_User_JwtToken,
            context: context,
          );

          final AddNewNotificationsResult = await AddNewNotifications(

            ReceiverNumber: widget.BookingInfoListInfo[0].providerNumber!,
            Status: true,
            Current_User_JwtToken: widget.Current_User_JwtToken,
            context: context,
          );

        }catch(obj){
          print(obj.toString());
          return;
        }
      },
    );
  }

  // ---------------------------------------------------------
  // Task complete section — logic identical to original onPressed body
  // ---------------------------------------------------------
  Widget _buildTaskCompleteSection() {
    return _buildPrimaryButton(
      label: "Change user task complete status",
      icon: Icons.done_all_rounded,
      onTap: () async {
        try{

          final BookIdValue=widget.BookingInfoListInfo[0].bookId!;

          final UserTaskResult =
          await UserRequestTaskComplete(
            UserEmail: widget.Current_User_Email,
            BookId: BookIdValue,
          );

          final AddNotificationsResult = await AddNotifications(

            ReceiverNumber: widget.BookingInfoListInfo[0].providerNumber!,
            Message:
            "User have change task complete status make sure task is finish for the booking id = ${BookIdValue}.",
            Current_User_JwtToken: widget.Current_User_JwtToken,
            context: context,
          );

          final AddNewNotificationsResult = await AddNewNotifications(

            ReceiverNumber: widget.BookingInfoListInfo[0].providerNumber!,
            Status: true,
            Current_User_JwtToken: widget.Current_User_JwtToken,
            context: context,
          );

        }catch(obj){
          print(obj.toString());
          return;
        }
      },
    );
  }

  // ---------------------------------------------------------
  // Advance payment: status chip + pick/upload buttons + preview.
  // Every action body below matches the original logic exactly.
  // ---------------------------------------------------------
  Widget _buildAdvancePaymentUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          final hasPhoto = change_photo_cont_getx.imageBytes.value != null;
          return _buildStatusChip(
            selected: hasPhoto,
            selectedText: "Photo ready to upload",
            emptyText: "No payment photo selected",
          );
        }),
        const SizedBox(height: 14),
        _buildPrimaryButton(
          outlined: true,
          label: "Pick advance payment photo",
          icon: Icons.add_photo_alternate_rounded,
          onTap: () async {
            try{
              int PhotoResult= await change_photo_cont_getx.pickImage();
              if (PhotoResult == 1)
              {
                Toast.Toastmsg("Pick photo success.");
                return;
              }
              else if(PhotoResult==2){
                Toast.Toastmsg("Only $PhotoExtension format accepted.");
                return;
              }
              else if(PhotoResult==5){
                Toast.Toastmsg("Image is larger than $PhotoSize.Please compressed and upload..");
                return;
              }
              else {
                Toast.Toastmsg("Pick photo fail.");
                return;
              }
            }
            catch(obj)
            {
              print(obj.toString());
              return;
            }
          },
        ),
        const SizedBox(height: 12),
        _buildPrimaryButton(
          label: "Upload advance payment photo",
          icon: Icons.cloud_upload_rounded,
          onTap: () async {
            try{

              if(change_photo_cont_getx.imageBytes.value==null)
              {
                Toast.Toastmsg("Please pick advance payment photo.");
                return;
              }

              num BookId=widget.BookingInfoListInfo[0].bookId!;

              final AddPhoto=await UploadAdvancePaymentPhoto(
                  BookId: BookId,
                  ImageBytes: change_photo_cont_getx.imageBytes.value!,
                  UserJwtToken: widget.Current_User_JwtToken,
                  PhotoExtension: change_photo_cont_getx.imageExtension.value!
              );

              final AddNotificationsResult = await AddNotifications(
                ReceiverNumber: widget.BookingInfoListInfo[0].providerNumber!,
                Message:
                "User have upload the advance amount payment photo for the booking id = ${BookId}.",
                Current_User_JwtToken: widget.Current_User_JwtToken,
                context: context,
              );

              final AddNewNotificationsResult = await AddNewNotifications(
                ReceiverNumber: widget.BookingInfoListInfo[0].providerNumber!,
                Status: true,
                Current_User_JwtToken: widget.Current_User_JwtToken,
                context: context,
              );
              AdvancePayPhoGetxCont.ChangeUpdateStatePhotoUpload();

            }
            catch(obj)
            {
              print(obj.toString());
              return;
            }
          },
        ),
        const SizedBox(height: 16),
        Obx(
              ()=>FutureBuilder<int>(
            future: GetAdvancePaymentPhoto(
              BookId: widget.BookingInfoListInfo[0].bookId!.toString(),
              UserEmail: widget.Current_User_Email,
              context: context,
              Current_User_JwtToken:
              widget.Current_User_JwtToken,
              UpdateStatePhotoUpload: AdvancePayPhoGetxCont.UpdateStatePhotoUpload.value,
            ),
            builder: (context, snapshot) {
              // =====================================================
              // Loading
              // =====================================================

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return _buildMediaFrame(
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(_Palette.accentMint),
                    ),
                  ),
                );
              }

              // =====================================================
              // Future error
              // =====================================================

              if (snapshot.hasError) {
                print(
                  "Advance payment photo Future error: "
                      "${snapshot.error}",
                );

                return _buildMediaFrame(
                  child: _buildMediaMessage("Unable to load advance payment photo."),
                );
              }

              // =====================================================
              // Check list
              // =====================================================

              if (AdvancePaymentPhotoList.isEmpty) {
                return _buildMediaFrame(
                  child: _buildMediaMessage("No advance payment photo available."),
                );
              }

              // =====================================================
              // Get model
              // =====================================================

              final advancePayment =
              AdvancePaymentPhotoList[0];

              // =====================================================
              // Get photo path safely
              // =====================================================

              final String photoPath =
                  advancePayment.paymentPhoto ?? "";

              // =====================================================
              // Get URL
              // =====================================================

              final String photoUrl =
              GetPhotoUrl(photoPath);

              // =====================================================
              // Empty URL
              // =====================================================

              if (photoUrl.isEmpty) {
                return _buildMediaFrame(
                  child: _buildMediaMessage("No advance payment photo available."),
                );
              }

              // =====================================================
              // Show image
              // =====================================================

              return _buildMediaFrame(
                child: Image.network(
                  photoUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,

                  loadingBuilder:
                      (
                      context,
                      child,
                      loadingProgress,
                      ) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return const SizedBox(
                      height: 220,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(_Palette.accentMint),
                        ),
                      ),
                    );
                  },

                  errorBuilder:
                      (
                      context,
                      error,
                      stackTrace,
                      ) {
                    print(
                      "Advance payment photo loading failed: "
                          "$error",
                    );

                    return _buildMediaMessage("Unable to load advance payment photo.");
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // QR preview — logic identical to original FutureBuilder body
  // ---------------------------------------------------------
  Widget _buildQrPreview() {
    return FutureBuilder<int>(
      future: GetAdvancePaymentQRPhoto(
        UserNumber: widget.BookingInfoListInfo[0].providerNumber!,
        context: context,
        Current_User_JwtToken:
        widget.Current_User_JwtToken,
      ),
      builder: (context, snapshot) {
        // =====================================================
        // Loading
        // =====================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return _buildMediaFrame(
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(_Palette.accentMint),
              ),
            ),
          );
        }

        // =====================================================
        // Future error
        // =====================================================

        if (snapshot.hasError) {
          print(
            "Advance payment QR Future error: "
                "${snapshot.error}",
          );

          return _buildMediaFrame(
            child: _buildMediaMessage("Unable to load advance payment QR."),
          );
        }

        // =====================================================
        // Check list
        // =====================================================

        if (AdvancePaymentQrPhotoList.isEmpty) {
          return _buildMediaFrame(
            child: _buildMediaMessage("No advance payment QR photo available."),
          );
        }

        // =====================================================
        // Get model
        // =====================================================

        final advancePaymentQr =
        AdvancePaymentQrPhotoList[0];

        // =====================================================
        // Get QR photo path safely
        // =====================================================

        final String qrPhotoPath =
            advancePaymentQr.qrPhoto ?? "";

        // =====================================================
        // Get URL
        // =====================================================

        final String qrPhotoUrl =
        GetPhotoUrl(qrPhotoPath);

        // =====================================================
        // Empty URL
        // =====================================================

        if (qrPhotoUrl.isEmpty) {
          return _buildMediaFrame(
            child: _buildMediaMessage("No advance payment QR available."),
          );
        }

        // =====================================================
        // Show QR image
        // =====================================================

        return _buildMediaFrame(
          padding: const EdgeInsets.all(12),
          child: Image.network(
            qrPhotoUrl,
            width: double.infinity,
            height: 220,
            fit: BoxFit.contain,

            loadingBuilder:
                (
                context,
                child,
                loadingProgress,
                ) {
              if (loadingProgress == null) {
                return child;
              }

              return const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(_Palette.accentMint),
                  ),
                ),
              );
            },

            errorBuilder:
                (
                context,
                error,
                stackTrace,
                ) {
              print(
                "Advance payment QR photo loading failed: "
                    "$error",
              );

              return _buildMediaMessage("Unable to load advance payment QR.");
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // SHARED UI HELPERS
  // ============================================================

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required RxBool focusedRx,
    required ValueChanged<bool> onFocusChange,
    TextInputType? keyboardType,
  }) {
    return Focus(
      onFocusChange: onFocusChange,
      child: Obx(() {
        final focused = focusedRx.value;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: focused ? _Palette.accentMint : _Palette.borderColor,
              width: focused ? 1.6 : 1,
            ),
            boxShadow: focused
                ? [
              BoxShadow(
                color: _Palette.accentMint.withOpacity(0.18),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ]
                : [],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: _Palette.primaryText, fontSize: 15),
            cursorColor: _Palette.accentMint,
            decoration: InputDecoration(
              filled: true,
              fillColor: _Palette.headerFooter,
              labelText: label,
              labelStyle: TextStyle(
                color: focused ? _Palette.accentMint : _Palette.mutedText,
                fontSize: 13.5,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  icon,
                  color: focused ? _Palette.accentMint : _Palette.mutedText,
                  size: 19,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    bool outlined = false,
  }) {
    return SizedBox(
      height: 50,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: outlined
                  ? null
                  : const LinearGradient(
                colors: [_Palette.accent, _Palette.accentMint],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              color: outlined ? _Palette.surface : null,
              border: outlined ? Border.all(color: _Palette.borderColor) : null,
              boxShadow: outlined
                  ? []
                  : [
                BoxShadow(
                  color: _Palette.accent.withOpacity(0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: outlined ? _Palette.accentMint : _Palette.bodyBg,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: outlined ? _Palette.primaryText : _Palette.bodyBg,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required bool selected,
    required String selectedText,
    required String emptyText,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _Palette.headerFooter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? _Palette.accentMint : _Palette.borderColor,
          width: selected ? 1.4 : 1,
        ),
        boxShadow: selected
            ? [
          BoxShadow(
            color: _Palette.accentMint.withOpacity(0.16),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ]
            : [],
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle_rounded : Icons.image_not_supported_outlined,
            color: selected ? _Palette.accentMint : _Palette.mutedText,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selected ? selectedText : emptyText,
              style: TextStyle(
                color: selected ? _Palette.primaryText : _Palette.mutedText,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaFrame({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _Palette.headerFooter,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.borderColor),
      ),
      child: child,
    );
  }

  Widget _buildMediaMessage(String message) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_outlined, color: _Palette.mutedText, size: 26),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _Palette.mutedText, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Ambient organic bubble / blob background painter.
// Soft, low-opacity, heavily blurred shapes with extremely slow
// drift — purely decorative, never intercepts touch input.
// ============================================================
class _BubblePainter extends CustomPainter {
  final double progress; // 0..1 looping

  _BubblePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final blobs = <_BlobSpec>[
      _BlobSpec(rx: -0.08, ry: 0.05, radius: w * 0.42, color: _Palette.accent, speed: 0.6, opacity: 0.10, blur: 90),
      _BlobSpec(rx: 1.05, ry: 0.10, radius: w * 0.34, color: _Palette.accentMint, speed: -0.5, opacity: 0.08, blur: 80),
      _BlobSpec(rx: 0.92, ry: 0.55, radius: w * 0.30, color: _Palette.accent, speed: 0.4, opacity: 0.07, blur: 70),
      _BlobSpec(rx: 0.06, ry: 0.62, radius: w * 0.28, color: _Palette.accentMint, speed: -0.35, opacity: 0.07, blur: 75),
      _BlobSpec(rx: 0.55, ry: 0.95, radius: w * 0.36, color: _Palette.accent, speed: 0.5, opacity: 0.09, blur: 85),
      _BlobSpec(rx: 0.35, ry: 0.30, radius: w * 0.14, color: _Palette.accentMint, speed: 0.8, opacity: 0.05, blur: 40),
      _BlobSpec(rx: 0.78, ry: 0.78, radius: w * 0.10, color: _Palette.accent, speed: -0.9, opacity: 0.05, blur: 35),
    ];

    for (final b in blobs) {
      final dx = sin(progress * 2 * pi * b.speed) * w * 0.015;
      final dy = cos(progress * 2 * pi * b.speed) * h * 0.012;
      final center = Offset(b.rx * w + dx, b.ry * h + dy);

      final paint = Paint()
        ..color = b.color.withOpacity(b.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, b.blur);

      canvas.drawCircle(center, b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BlobSpec {
  final double rx;
  final double ry;
  final double radius;
  final Color color;
  final double speed;
  final double opacity;
  final double blur;

  _BlobSpec({
    required this.rx,
    required this.ry,
    required this.radius,
    required this.color,
    required this.speed,
    required this.opacity,
    required this.blur,
  });
}