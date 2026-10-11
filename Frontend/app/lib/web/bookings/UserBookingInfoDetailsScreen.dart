import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:app/web/common%20widget/toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';

import '../../constant/Server_Database.dart';
import '../../constant/variable.dart';
import '../../models/BookingInfoModel.dart';
import '../../state management/getx/booking/user_booking_details_getx.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';


// PALETTE — Dark Forest / Emerald Glow

class _C {
  static const Color bg = Color(0xFF0F1F17);
  static const Color surface = Color(0xFF162E22);
  static const Color bar = Color(0xFF12261C);
  static const Color text = Color(0xFFE6F4EA);
  static const Color muted = Color(0xFF8A9A90);
  static const Color accent = Color(0xFF22C55E);
  static const Color mint = Color(0xFF34D399);
  static const Color border = Color(0xFF234232);
  static const Color warn = Color(0xFFFBBF24);
  static const Color frame = Color(0xFF0B1711);
}

// =============================================================================
// SCREEN
// =============================================================================
class Userbookinginfodetailsscreen extends StatefulWidget {
  final String Current_User_Email;
  final String Current_User_JwtToken;
  final String Current_User_Role;
  final List<BookingInfoModel> BookingInfoListInfo;

  Userbookinginfodetailsscreen(
      {super.key,
        required this.Current_User_Email,
        required this.Current_User_JwtToken,
        required this.Current_User_Role,
        required this.BookingInfoListInfo});

  @override
  State<Userbookinginfodetailsscreen> createState() =>
      _UserbookinginfodetailsscreenState();
}

class _UserbookinginfodetailsscreenState
    extends State<Userbookinginfodetailsscreen> {
  final RatingValueCont = TextEditingController();



  late final UserBookingDetailsGetx c;
  final String _tag = UniqueKey().toString();

  // Cached futures: the network call runs once (and again only when the photo
  // reload flag toggles), not on every resize / rebuild.
  bool? _photoFutureKey;
  Future<int>? _photoFuture;
  Future<int>? _qrFuture;

  BookingInfoModel? get _booking => widget.BookingInfoListInfo.isEmpty
      ? null
      : widget.BookingInfoListInfo[0];

  @override
  void initState() {
    super.initState();
    User_Jwt_Verify(Jwt_Token: widget.Current_User_JwtToken, context: context);
    c = Get.put(UserBookingDetailsGetx(), tag: _tag);
    c.seed(_booking);
  }

  @override
  void dispose() {
    try {
      change_photo_cont_getx.imageBytes.value = null;
      change_photo_cont_getx.imageExtension.value = "";
      change_photo_cont_getx.imagePath.value = "";
    } catch (obj) {
      print(obj.toString());
    }
    try {
      RatingValueCont.dispose();
    } catch (obj) {
      print(obj.toString());
    }
    try {
      Get.delete<UserBookingDetailsGetx>(tag: _tag);
    } catch (obj) {
      print(obj.toString());
    }
    super.dispose();
  }





  Future<int> UploadAdvancePaymentPhoto({
    required num BookId,
    required List<int> ImageBytes,
    required String UserJwtToken,
    required String PhotoExtension,
  }) async {
    try {
      if (BookId <= 0) {
        Toast.Toastmsg("Invalid BookId.");
        print("Invalid BookId: $BookId");
        return 1;
      }

      if (ImageBytes.isEmpty) {
        Toast.Toastmsg("Payment photo is required.");
        print("Payment photo is required.");
        return 2;
      }

      final String photoExtension =
      PhotoExtension.trim().toLowerCase().replaceFirst('.', '');

      if (photoExtension.isEmpty) {
        Toast.Toastmsg("Photo extension is required.");
        print("Photo extension is required.");
        return 3;
      }

      if (photoExtension != "jpg" &&
          photoExtension != "jpeg" &&
          photoExtension != "png") {
        Toast.Toastmsg(
          "Invalid photo format. Only JPG, JPEG and PNG are allowed.",
        );
        print("Invalid photo format: $photoExtension");
        return 3;
      }

      const String url =
          Backend_Server_Url + "api/Booking/uploadadvancepaymentphoto";

      print("API URL: $url");

      final request = http.MultipartRequest(
        "POST",
        Uri.parse(url),
      );

      request.headers["Authorization"] = "Bearer $UserJwtToken";

      request.fields["BookId"] = BookId.toInt().toString();

      request.files.add(
        http.MultipartFile.fromBytes(
          "PaymentPhoto",
          ImageBytes,
          filename: "payment_photo.$photoExtension",
        ),
      );

      print("Payment photo filename: payment_photo.$photoExtension");
      print("Uploading advance payment photo...");

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        Toast.Toastmsg("Advance payment photo uploaded successfully.");
        print("Advance payment photo uploaded successfully.");

        change_photo_cont_getx.imageBytes.value = null;
        change_photo_cont_getx.imageExtension.value = "";
        change_photo_cont_getx.imagePath.value = "";

        return 0;
      }

      if (response.statusCode == 400) {
        Toast.Toastmsg(response.body);
        print("Invalid data: ${response.body}");
        return 4;
      }

      if (response.statusCode == 404) {
        Toast.Toastmsg(response.body);
        print("Booking not found: ${response.body}");
        return 5;
      }

      if (response.statusCode == 401) {
        Toast.Toastmsg("Unauthorized. Please login again.");
        print("Unauthorized.");
        return 6;
      }

      if (response.statusCode == 403) {
        Toast.Toastmsg("You are not authorized.");
        print("Forbidden.");
        return 7;
      }

      if (response.statusCode == 500) {
        Toast.Toastmsg("Server error while uploading payment photo.");
        print("Server error: ${response.body}");
        return 8;
      }

      print("Unexpected status code: ${response.statusCode}");
      Toast.Toastmsg("Upload failed. Try again.");
      return 9;
    } catch (obj) {
      print("Exception caught while uploading advance payment photo.");
      print(obj.toString());
      Toast.Toastmsg("Upload failed. Try again.");
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
        "RatingReceiver": RatingReceiver,
        "RatingValue": RatingValue,
        "ServiceName": ServiceName
      };
      const String url = Backend_Server_Url + "api/Booking/updateuserrating";
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
        Toast.Toastmsg("Update fail.Try again.Server error.");
        print("Update  fail.Try again.Server error.");
        print("SERVER ERROR: ${response.body}");
        return 2;
      } else if (response.statusCode == 502) {
        Toast.Toastmsg("Current user doesn't match.");
        Logout(context: context);
        return 3;
      } else if (response.statusCode == 503) {
        Toast.Toastmsg("No booking available of that book id.");
        print("No  data available of that book id.");
        return 4;
      } else if (response.statusCode == 501) {
        Toast.Toastmsg(
          "Invalid data format.Please provide data in correct format.",
        );
        print("Invalid data format.Please provide data in correct format.");
        return 5;
      }
      else if (response.statusCode == 507) {
        Toast.Toastmsg(
          "Rating value already updated.",
        );
        print("Rating value already updated.");
        return 5;
      }
      else {
        Toast.Toastmsg("Update fail.Try again.Server error.");
        return 6;
      }
    } catch (Obj) {
      print("Exception caught.");
      print(Obj.toString());
      Toast.Toastmsg("Update fail.Try again.Server error.");
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
        Toast.Toastmsg("Update fail.Try again.Server error.");
        print("Update  fail.Try again.Server error.");
        print("SERVER ERROR: ${response.body}");
        return 2;
      } else if (response.statusCode == 502) {
        Toast.Toastmsg("Current user doesn't match.");
        print("Current user doesn't match.");
        Logout(context: context);
        return 3;
      } else if (response.statusCode == 503) {
        Toast.Toastmsg("No booking available of that book id.");
        print("No  data available of that book id.");
        return 4;
      } else if (response.statusCode == 504) {
        Toast.Toastmsg(
            "You have already accept it.You cannot update approval status.");
        print("You have already accept it.You cannot update approval status.");
        return 8;
      } else if (response.statusCode == 501) {
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
        Toast.Toastmsg("Update fail.Try again.Server error.");
        return 6;
      }
    } catch (Obj) {
      print("Exception caught while Updating  approval status .");
      print(Obj.toString());
      Toast.Toastmsg("Update  approval status  fail.Try again.Server error.");
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
        print("Update  task complete status   fail.Try again.Server error.");
        print("SERVER ERROR: ${response.body}");
        return 2;
      } else if (response.statusCode == 502) {
        Toast.Toastmsg("Current user doesn't match.");
        Logout(context: context);
        return 3;
      } else if (response.statusCode == 503) {
        Toast.Toastmsg("No booking data  available of that book id.");
        print("No booking data   data available of taht book id.");
        return 4;
      } else if (response.statusCode == 504) {
        Toast.Toastmsg(
            "You have already change.You cannot update task complete status.");
        print(
            "You have already change.You cannot update task complete status.");
        return 8;
      } else if (response.statusCode == 501) {
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

  Future<void> _onSubmitRating() async {
    if (c.busyKey.value.isNotEmpty) return;
    try {
      final b = _booking;
      if (b == null ||
          b.bookId == null ||
          b.providerEmail == null ||
          b.serviceName == null) {
        Toast.Toastmsg("No booking data available.");
        return;
      }

      final int? RtaingValue = int.tryParse(RatingValueCont.text.trim());

      if (RtaingValue == null || RtaingValue <= 0 || RtaingValue >= 11) {
        Toast.Toastmsg("Enter rating value from 1-10.");
        return;
      }

      if (RatingValueCont.text.trim().isEmptyOrNull) {
        Toast.Toastmsg("Enter rating value from 1-10.");
        return;
      }

      final bool ok = await _confirm(
        title: "Submit rating?",
        message:
        "Your rating of $RtaingValue / 10 for \"${b.serviceName}\" will be saved.",
        confirmLabel: "Submit",
        icon: Icons.star_rounded,
      );
      if (!ok) return;

      c.busyKey.value = 'rate';
      final RatingAddResult = await UpdateRating(
          RatingGiver: widget.Current_User_Email,
          BookId: b.bookId!,
          RatingReceiver: b.providerEmail!,
          RatingValue: RtaingValue,
          ServiceName: b.serviceName!);

      if (RatingAddResult == 1) {
        c.ratingValue.value = RtaingValue; // live update
        RatingValueCont.clear();
      }
    } catch (obj) {
      print(obj.toString());
      return;
    } finally {
      c.busyKey.value = '';
    }
  }

  Future<void> _onApproval() async {
    if (c.busyKey.value.isNotEmpty) return;
    try {
      final b = _booking;
      if (b == null || b.bookId == null || b.providerNumber == null) {
        Toast.Toastmsg("No booking data available.");
        return;
      }

      final bool ok = await _confirm(
        title: "Change approval status?",
        message:
        "Your approval status for booking #${b.bookId} will be changed and the provider will be notified.",
        confirmLabel: "Confirm",
        icon: Icons.check_circle_outline_rounded,
      );
      if (!ok) return;

      c.busyKey.value = 'approve';
      final BookIdValue = b.bookId!;

      final ApprovalResult = await UpdateUserApprovalStatus(
        UserEmail: widget.Current_User_Email,
        BookId: BookIdValue,
      );

      print(" approval update result = ${ApprovalResult}");

      if (ApprovalResult == 1) c.userApproval.value = true; // live update

      final AddNotificationsResult = await AddNotifications(
        ReceiverNumber: b.providerNumber!,
        Message:
        "User have change approval status for the booking id = ${BookIdValue}.",
        Current_User_JwtToken: widget.Current_User_JwtToken,
        context: context,
      );

      final AddNewNotificationsResult = await AddNewNotifications(
        ReceiverNumber: b.providerNumber!,
        Status: true,
        Current_User_JwtToken: widget.Current_User_JwtToken,
        context: context,
      );
    } catch (obj) {
      print(obj.toString());
      return;
    } finally {
      c.busyKey.value = '';
    }
  }

  Future<void> _onTaskComplete() async {
    if (c.busyKey.value.isNotEmpty) return;
    try {
      final b = _booking;
      if (b == null || b.bookId == null || b.providerNumber == null) {
        Toast.Toastmsg("No booking data available.");
        return;
      }

      final bool ok = await _confirm(
        title: "Change task complete status?",
        message:
        "Only confirm if the task for booking #${b.bookId} is finished. The provider will be notified.",
        confirmLabel: "Confirm",
        icon: Icons.done_all_rounded,
      );
      if (!ok) return;

      c.busyKey.value = 'task';
      final BookIdValue = b.bookId!;

      final UserTaskResult = await UserRequestTaskComplete(
        UserEmail: widget.Current_User_Email,
        BookId: BookIdValue,
      );

      if (UserTaskResult == 1) c.userTaskComplete.value = true; // live update

      final AddNotificationsResult = await AddNotifications(
        ReceiverNumber: b.providerNumber!,
        Message:
        "User have change task complete status make sure task is finish for the booking id = ${BookIdValue}.",
        Current_User_JwtToken: widget.Current_User_JwtToken,
        context: context,
      );

      final AddNewNotificationsResult = await AddNewNotifications(
        ReceiverNumber: b.providerNumber!,
        Status: true,
        Current_User_JwtToken: widget.Current_User_JwtToken,
        context: context,
      );
    } catch (obj) {
      print(obj.toString());
      return;
    } finally {
      c.busyKey.value = '';
    }
  }

  Future<void> _onPickPhoto() async {
    try {
      int PhotoResult = await change_photo_cont_getx.pickImage();
      if (PhotoResult == 1) {
        Toast.Toastmsg("Pick photo success.");
        return;
      } else if (PhotoResult == 2) {
        Toast.Toastmsg("Only $PhotoExtension format accepted.");
        return;
      } else if (PhotoResult == 5) {
        Toast.Toastmsg(
            "Image is larger than $PhotoSize.Please compressed and upload..");
        return;
      } else {
        Toast.Toastmsg("Pick photo fail.");
        return;
      }
    } catch (obj) {
      print(obj.toString());
      return;
    }
  }

  Future<void> _onUploadPhoto() async {
    if (c.busyKey.value.isNotEmpty) return;
    try {
      final b = _booking;
      if (b == null || b.bookId == null || b.providerNumber == null) {
        Toast.Toastmsg("No booking data available.");
        return;
      }

      if (change_photo_cont_getx.imageBytes.value == null) {
        Toast.Toastmsg("Please pick advance payment photo.");
        return;
      }

      final bool ok = await _confirm(
        title: "Upload payment photo?",
        message:
        "The selected photo will be uploaded as the advance payment proof for booking #${b.bookId} and the provider will be notified.",
        confirmLabel: "Upload",
        icon: Icons.cloud_upload_rounded,
      );
      if (!ok) return;

      c.busyKey.value = 'upload';
      num BookId = b.bookId!;

      final AddPhoto = await UploadAdvancePaymentPhoto(
          BookId: BookId,
          ImageBytes: change_photo_cont_getx.imageBytes.value!,
          UserJwtToken: widget.Current_User_JwtToken,
          PhotoExtension: change_photo_cont_getx.imageExtension.value!);

      final AddNotificationsResult = await AddNotifications(
        ReceiverNumber: b.providerNumber!,
        Message:
        "User have upload the advance amount payment photo for the booking id = ${BookId}.",
        Current_User_JwtToken: widget.Current_User_JwtToken,
        context: context,
      );

      final AddNewNotificationsResult = await AddNewNotifications(
        ReceiverNumber: b.providerNumber!,
        Status: true,
        Current_User_JwtToken: widget.Current_User_JwtToken,
        context: context,
      );
      c.ChangeUpdateStatePhotoUpload();
    } catch (obj) {
      print(obj.toString());
      return;
    } finally {
      c.busyKey.value = '';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bar,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leadingWidth: 64,
        leading: Center(
          child: Tooltip(
            message: "Back",
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.text, width: 1.4),
                ),
                child: const Icon(Icons.arrow_back, color: _C.text, size: 20),
              ),
            ),
          ),
        ),
        title: const Text(
          "Booking Details",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: _C.text, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.border),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: _AmbientBackground())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final double w = box.maxWidth;
                final double hPad =
                w >= 1100 ? (w - 1100) / 2 : (w >= 700 ? 24.0 : 14.0);
                final bool wide = w >= 980;
                final BookingInfoModel? b = _booking;

                Widget body;
                if (b == null) {
                  body = const _EmptyState(text: "No booking data available.");
                } else {
                  final Widget details = _Entrance(
                    index: 0,
                    child: _SectionCard(
                      icon: Icons.info_outline_rounded,
                      title: "Booking Details",
                      subtitle: "Everything about this booking at a glance.",
                      child: _buildBookingInfoSection(b),
                    ),
                  );

                  final List<Widget> others = [
                    _Entrance(
                      index: 1,
                      child: _SectionCard(
                        icon: Icons.star_rate_rounded,
                        title: "Rate this service.Refresh booking screen to see latest update.",
                        subtitle: "Share feedback from 1 to 10.",
                        child: _buildRatingSection(),
                      ),
                    ),
                    _Entrance(
                      index: 2,
                      child: _SectionCard(
                        icon: Icons.verified_rounded,
                        title: "Booking Approval.Refresh booking screen to see latest update.",
                        subtitle: "Update you approve this booking.",
                        child: _buildApprovalSection(),
                      ),
                    ),
                    _Entrance(
                      index: 3,
                      child: _SectionCard(
                        icon: Icons.task_alt_rounded,
                        title: "Task Completion.Refresh booking screen to see latest update.",
                        subtitle: "Let the provider know the task is done.",
                        child: _buildTaskCompleteSection(),
                      ),
                    ),
                    _Entrance(
                      index: 4,
                      child: _SectionCard(
                        icon: Icons.photo_library_rounded,
                        title: "Advance Payment Photo Examples",
                        subtitle:
                        "Your advance payment photo should look like these.",
                        child: _buildExamplesSection(),
                      ),
                    ),

                    _Entrance(
                      index: 6,
                      child: _SectionCard(
                        icon: Icons.qr_code_2_rounded,
                        title: "Advance Payment QR Code",
                        subtitle: "Scan to pay the service provider.",
                        child: _buildQrPreview(b),
                      ),
                    ),

                    _Entrance(
                      index: 5,
                      child: _SectionCard(
                        icon: Icons.receipt_long_rounded,
                        title: "Advance Payment Photo",
                        subtitle: "Upload proof of your advance payment.",
                        child: _buildAdvancePaymentUploadSection(b),
                      ),
                    ),



                  ];

                  if (wide) {
                    body = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: details),
                        const SizedBox(width: 18),
                        Expanded(
                            flex: 5,
                            child: Column(
                                children: _spaced(others, 16))),
                      ],
                    );
                  } else {
                    body = Column(
                      children: _spaced([details, ...others], 16),
                    );
                  }
                }

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 40),
                  child: Column(
                    children: [
                      _buildHeader(b),
                      const SizedBox(height: 22),
                      body,
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _spaced(List<Widget> items, double gap) {
    final List<Widget> out = [];
    for (int i = 0; i < items.length; i++) {
      if (i != 0) out.add(SizedBox(height: gap));
      out.add(items[i]);
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // HEADER (reactive chips)
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BookingInfoModel? b) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (context, v, child) =>
              Transform.scale(scale: 0.7 + (0.3 * v), child: child),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_C.accent, _C.mint],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                    color: _C.accent.withOpacity(.4),
                    blurRadius: 20,
                    spreadRadius: 1),
              ],
            ),
            child:
            const Icon(Icons.event_note_rounded, color: _C.bg, size: 30),
          ),
        ),
        const SizedBox(height: 14),
        const Text("Manage Your Booking",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _C.text, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
          "Rate, approve, complete and upload payment proof — all in one place.",
          textAlign: TextAlign.center,
          style: TextStyle(color: _C.muted, fontSize: 13, height: 1.4),
        ),
        if (b != null) ...[
          const SizedBox(height: 12),
          Obx(() {
            final bool? appr = c.userApproval.value;
            final bool? done = c.userTaskComplete.value;
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(
                    icon: Icons.tag_rounded,
                    text: "Booking #${_n(b.bookId) ?? '—'}"),
                _Chip(
                  icon: appr == true
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_empty_rounded,
                  text: appr == true ? "Approved" : "Approval pending",
                  color: appr == true ? _C.mint : _C.warn,
                ),
                _Chip(
                  icon: done == true
                      ? Icons.task_alt_rounded
                      : Icons.hourglass_empty_rounded,
                  text: done == true ? "Task completed" : "Task pending",
                  color: done == true ? _C.mint : _C.warn,
                ),
              ],
            );
          }),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BOOKING DETAILS — every field; missing data shows "No data available"
  // ---------------------------------------------------------------------------
  Widget _buildBookingInfoSection(BookingInfoModel b) {
    String? coords(num? lat, num? lon) =>
        (lat == null || lon == null) ? null : "$lat, $lon";

    String? price(num? p, num? d) {
      if (p == null) return null;
      return d == null ? _n(p) : "${_n(p)}  •  ${_n(d)}% off";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoGroup(title: "Service", icon: Icons.handyman_rounded, children: [
          _InfoTile(Icons.design_services_rounded, "Service name",
              _s(b.serviceName)),
          _InfoTile(Icons.tag_rounded, "Booking ID", _n(b.bookId)),

          _InfoTile(Icons.straighten_rounded, "Distance",
              b.distance == null ? null : "${_n(b.distance)} km"),
          _InfoTile(Icons.schedule_rounded, "Created at", _d(b.createdAt)),
        ]),
        _InfoGroup(
            title: "Schedule & Payment",
            icon: Icons.payments_rounded,
            children: [
              _InfoTile(Icons.play_arrow_rounded, "Start date", _d(b.startDate)),
              _InfoTile(Icons.stop_rounded, "End date", _d(b.endDate)),
              _InfoTile(Icons.account_balance_wallet_rounded,
                  "Advance payment amount", _n(b.advancePaymentAmount)),
              _StatusTile("Advance payment required", b.requiredAdvancePayment),

            ]),
        _InfoGroup(title: "Rating", icon: Icons.star_rounded, children: [
          Obx(() => _RatingTile(
              label: "Your rating for this service",
              value: c.ratingValue.value)),
        ]),
        _InfoGroup(title: "Status", icon: Icons.fact_check_rounded, children: [
          _StatusTile("Provider approval", b.providerApprovalStatus),
          Obx(() => _StatusTile("Your approval", c.userApproval.value)),
          _StatusTile(
              "Provider task complete", b.providerTaskCompleteStatus),
          Obx(() =>
              _StatusTile("Your task complete", c.userTaskComplete.value)),
        ]),
        _InfoGroup(title: "Your details", icon: Icons.person_rounded, children: [
          _InfoTile(Icons.tag_rounded, "Contact number", _n(b.userNumber)),
          _InfoTile(Icons.phone_rounded, "Phone number", _s(b.userPhoneNumber)),
          // _InfoTile(Icons.chat_rounded, "WhatsApp number",
          //     _s(b.userWhatsappPhoneNumber)),
          _InfoTile(Icons.location_on_rounded, "Address", _s(b.userAddress)),
          _InfoTile(Icons.my_location_rounded, "Latitude,Longitude",
              coords(b.userLatitude, b.userLongitude)),
          _InfoTile(Icons.notes_rounded, "Booking description",
              _s(b.userBookingDescription)),
        ]),
        _InfoGroup(
            title: "Provider details",
            icon: Icons.engineering_rounded,
            children: [
              _InfoTile(
                  Icons.tag_rounded, "Contact number", _n(b.providerNumber)),
              _InfoTile(Icons.phone_rounded, "Phone number",
                  _s(b.providerPhoneNumber)),
              // _InfoTile(Icons.chat_rounded, "WhatsApp number",
              //     _s(b.providerWhatsappPhoneNumber)),
              _InfoTile(
                  Icons.location_on_rounded, "Address", _s(b.providerAddress)),
              _InfoTile(Icons.my_location_rounded, "Latitude,Longitude",
                  coords(b.providerLatitude, b.providerLongitude)),
              _InfoTile(Icons.notes_rounded, "Booking description",
                  _s(b.providerBookingDescription)),
            ]),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RATING
  // ---------------------------------------------------------------------------
  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() => _RatingTile(
            label: "Current rating", value: c.ratingValue.value)),
        const SizedBox(height: 14),
        // quick-pick circles 1..10 (they only fill the text box)
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: RatingValueCont,
          builder: (context, v, _) {
            final String cur = v.text.trim();
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (int i = 1; i <= 10; i++)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      RatingValueCont.text = "$i";
                      RatingValueCont.selection = TextSelection.collapsed(
                          offset: RatingValueCont.text.length);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: cur == "$i"
                            ? const LinearGradient(
                            colors: [_C.accent, _C.mint])
                            : null,
                        color: cur == "$i" ? null : _C.bar,
                        border: Border.all(
                            color: cur == "$i" ? Colors.transparent : _C.border),
                      ),
                      child: Text("$i",
                          style: TextStyle(
                              color: cur == "$i" ? _C.bg : _C.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5)),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Focus(
          onFocusChange: (v) => c.ratingFocused.value = v,
          child: Obx(() {
            final bool f = c.ratingFocused.value;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: f
                    ? [
                  BoxShadow(
                      color: _C.mint.withOpacity(.18),
                      blurRadius: 14,
                      spreadRadius: 1)
                ]
                    : [],
              ),
              child: TextField(
                controller: RatingValueCont,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: _C.text, fontSize: 15),
                cursorColor: _C.mint,
                decoration: InputDecoration(
                  labelText: "Enter rating value (1-10)",
                  labelStyle: const TextStyle(color: _C.muted, fontSize: 13.5),
                  floatingLabelStyle: const TextStyle(
                      color: _C.mint, fontWeight: FontWeight.w600),
                  filled: true,
                  fillColor: _C.bg.withOpacity(.6),
                  prefixIcon: const Icon(Icons.rate_review_rounded,
                      color: _C.mint, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _C.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _C.mint, width: 1.5),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        Obx(() => _GradientButton(
          label: "Submit rating",
          icon: Icons.send_rounded,
          loading: c.busyKey.value == 'rate',
          onTap: c.busyKey.value.isNotEmpty ? null : _onSubmitRating,
        )),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // APPROVAL / TASK COMPLETE
  // ---------------------------------------------------------------------------
  Widget _buildApprovalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() => _StateBanner(
          done: c.userApproval.value == true,
          doneText: "You have approved this booking.",
          pendingText: "You have not approved this booking yet.",
        )),
        const SizedBox(height: 14),
        Obx(() => _GradientButton(
          label: "Change user approval status",
          icon: Icons.check_circle_outline_rounded,
          loading: c.busyKey.value == 'approve',
          onTap: c.busyKey.value.isNotEmpty ? null : _onApproval,
        )),
      ],
    );
  }

  Widget _buildTaskCompleteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() => _StateBanner(
          done: c.userTaskComplete.value == true,
          doneText: "You marked this task as completed.",
          pendingText: "Task not marked as completed yet.",
        )),
        const SizedBox(height: 14),
        Obx(() => _GradientButton(
          label: "Change user task complete status",
          icon: Icons.done_all_rounded,
          loading: c.busyKey.value == 'task',
          onTap: c.busyKey.value.isNotEmpty ? null : _onTaskComplete,
        )),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PAYMENT PHOTO EXAMPLES (assets/images/payment/) — normal + full screen
  // ---------------------------------------------------------------------------
  Widget _buildExamplesSection() {
    const examples = [
      ["Nepal payment example", "assets/images/payment/nepal.jpg"],
      ["PayPal payment example", "assets/images/payment/paypal.jpg"],
    ];

    return LayoutBuilder(builder: (context, box) {
      const double gap = 14;
      final int cols = box.maxWidth >= 440 ? 2 : 1;
      final double tileW =
      math.max(0.0, (box.maxWidth - gap * (cols - 1)) / cols);
      final double hLimit =
      (MediaQuery.of(context).size.height * 0.4).clamp(200.0, 380.0).toDouble();
      final double side = math.max(0.0, math.min(tileW, hLimit));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: gap,
            runSpacing: 18,
            alignment: WrapAlignment.center,
            children: [
              for (final e in examples)
                SizedBox(
                  width: side,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(e[0],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: _C.text,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: side,
                        height: side,
                        child: _PhotoFrame(
                          onTap: () => _openFullscreen(
                              e[0], _AssetPhoto(path: e[1])),
                          child: _AssetPhoto(path: e[1]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () => _openFullscreen(
                              e[0], _AssetPhoto(path: e[1])),
                          icon: const Icon(Icons.fullscreen_rounded, size: 20),
                          label: const Text("Full screen"),
                          style: _outlinedStyle(),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const _Hint(
              text:
              "Make sure the amount, date and transaction details are clearly visible in your photo."),
        ],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // ADVANCE PAYMENT: status + picked preview + pick/upload + uploaded photo
  // ---------------------------------------------------------------------------
  Future<int> _photoFutureFor(bool key, BookingInfoModel b) {
    if (_photoFuture == null || _photoFutureKey != key) {
      _photoFutureKey = key;
      _photoFuture = GetAdvancePaymentPhoto(
        BookId: b.bookId!.toString(),
        UserEmail: widget.Current_User_Email,
        context: context,
        Current_User_JwtToken: widget.Current_User_JwtToken,
        UpdateStatePhotoUpload: key,
      );
    }
    return _photoFuture!;
  }

  Widget _buildAdvancePaymentUploadSection(BookingInfoModel b) {
    return LayoutBuilder(builder: (context, box) {
      final double hLimit =
      (MediaQuery.of(context).size.height * 0.4).clamp(200.0, 380.0).toDouble();
      final double side = math.max(0.0, math.min(box.maxWidth, hLimit));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- status chip ----
          Obx(() {
            final bool hasPhoto =
                change_photo_cont_getx.imageBytes.value != null;
            return _StateBanner(
              done: hasPhoto,
              doneText: "Photo ready to upload",
              pendingText: "No payment photo selected",
              pendingIcon: Icons.image_not_supported_outlined,
            );
          }),

          // ---- picked (not yet uploaded) preview ----
          Obx(() {
            final bytes = change_photo_cont_getx.imageBytes.value;
            return AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: bytes == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _MiniLabel("Selected photo (not uploaded yet)"),
                    const SizedBox(height: 8),
                    Center(
                      child: SizedBox(
                        width: side,
                        height: side,
                        child: _PhotoFrame(
                          onTap: () => _openFullscreen("Selected photo",
                              _MemoryPhoto(bytes: Uint8List.fromList(bytes.toList()))),
                          child: _MemoryPhoto(
                              bytes: Uint8List.fromList(bytes.toList())),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () => _openFullscreen(
                            "Selected photo",
                            _MemoryPhoto(
                                bytes: Uint8List.fromList(bytes.toList()))),
                        icon: const Icon(Icons.fullscreen_rounded, size: 20),
                        label: const Text("Full screen"),
                        style: _outlinedStyle(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // ---- buttons ----
          LayoutBuilder(builder: (context, bb) {
            final pick = Obx(() => _GradientButton(
              outlined: true,
              label: "Pick advance payment photo",
              icon: Icons.add_photo_alternate_rounded,
              onTap: c.busyKey.value.isNotEmpty ? null : _onPickPhoto,
            ));
            final upload = Obx(() => _GradientButton(
              label: "Upload advance payment photo",
              icon: Icons.cloud_upload_rounded,
              loading: c.busyKey.value == 'upload',
              onTap: c.busyKey.value.isNotEmpty ? null : _onUploadPhoto,
            ));
            if (bb.maxWidth >= 520) {
              return Row(children: [
                Expanded(child: pick),
                const SizedBox(width: 10),
                Expanded(child: upload),
              ]);
            }
            return Column(children: [
              pick,
              const SizedBox(height: 10),
              upload,
            ]);
          }),

          const SizedBox(height: 18),
          Container(height: 1, color: _C.border),
          const SizedBox(height: 16),

          // ---- uploaded photo (from server) ----
          Row(
            children: [
              const Expanded(child: _MiniLabel("Uploaded photo")),
              Tooltip(
                message: "Reload photo",
                child: IconButton(
                  onPressed: c.ChangeUpdateStatePhotoUpload,
                  icon: const Icon(Icons.refresh_rounded,
                      color: _C.mint, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Obx(() {
            final bool key = c.UpdateStatePhotoUpload.value;
            if (b.bookId == null) {
              return _MediaMessage(
                  side: side, text: "No data available. Booking ID is missing.");
            }
            return FutureBuilder<int>(
              future: _photoFutureFor(key, b),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                      width: double.infinity,
                      height: side,
                      child: const Center(child: _SkeletonBox()));
                }

                if (snapshot.hasError) {
                  print("Advance payment photo Future error: ${snapshot.error}");
                  return _MediaMessage(
                      side: side, text: "Unable to load advance payment photo.");
                }

                if (AdvancePaymentPhotoList.isEmpty) {
                  return _MediaMessage(
                      side: side,
                      text:
                      "No data available. No advance payment photo uploaded yet.");
                }

                final advancePayment = AdvancePaymentPhotoList[0];
                final String photoPath = advancePayment.paymentPhoto ?? "";
                final String photoUrl = GetPhotoUrl(photoPath);

                if (photoUrl.isEmpty) {
                  return _MediaMessage(
                      side: side,
                      text:
                      "No data available. No advance payment photo uploaded yet.");
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SizedBox(
                        width: side,
                        height: side,
                        child: _PhotoFrame(
                          onTap: () => _openFullscreen("Advance payment photo",
                              _NetPhoto(url: photoUrl)),
                          child: _NetPhoto(url: photoUrl),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () => _openFullscreen(
                            "Advance payment photo", _NetPhoto(url: photoUrl)),
                        icon: const Icon(Icons.fullscreen_rounded, size: 20),
                        label: const Text("Full screen"),
                        style: _outlinedStyle(),
                      ),
                    ),
                  ],
                );
              },
            );
          }),
        ],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // QR PREVIEW
  // ---------------------------------------------------------------------------
  Widget _buildQrPreview(BookingInfoModel b) {
    return LayoutBuilder(builder: (context, box) {
      final double hLimit =
      (MediaQuery.of(context).size.height * 0.4).clamp(200.0, 380.0).toDouble();
      final double side = math.max(0.0, math.min(box.maxWidth, hLimit));

      if (b.providerNumber == null) {
        return _MediaMessage(
            side: side, text: "No data available. Provider number is missing.");
      }

      _qrFuture ??= GetAdvancePaymentQRPhoto(
        UserNumber: b.providerNumber!,
        context: context,
        Current_User_JwtToken: widget.Current_User_JwtToken,
      );

      return FutureBuilder<int>(
        future: _qrFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
                width: double.infinity,
                height: side,
                child: const Center(child: _SkeletonBox()));
          }

          if (snapshot.hasError) {
            print("Advance payment QR Future error: ${snapshot.error}");
            return _MediaMessage(
                side: side, text: "Unable to load advance payment QR.");
          }

          if (AdvancePaymentQrPhotoList.isEmpty) {
            return _MediaMessage(
                side: side, text: "No data available. No payment QR uploaded.");
          }

          final advancePaymentQr = AdvancePaymentQrPhotoList[0];
          final String qrPhotoPath = advancePaymentQr.qrPhoto ?? "";
          final String qrPhotoUrl = GetPhotoUrl(qrPhotoPath);

          if (qrPhotoUrl.isEmpty) {
            return _MediaMessage(
                side: side, text: "No data available. No payment QR uploaded.");
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SizedBox(
                  width: side,
                  height: side,
                  child: _PhotoFrame(
                    white: true,
                    onTap: () => _openFullscreen("Payment QR",
                        _PhotoFrame(white: true, child: _NetPhoto(url: qrPhotoUrl))),
                    child: _NetPhoto(url: qrPhotoUrl),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => _openFullscreen("Payment QR",
                      _PhotoFrame(white: true, child: _NetPhoto(url: qrPhotoUrl))),
                  icon: const Icon(Icons.fullscreen_rounded, size: 20),
                  label: const Text("Full screen"),
                  style: _outlinedStyle(),
                ),
              ),
            ],
          );
        },
      );
    });
  }
}

// =============================================================================
// DATA HELPERS — null / empty -> null (UI then prints "No data available")
// =============================================================================
String? _s(Object? v) {
  if (v == null) return null;
  final String t = v.toString().trim();
  if (t.isEmpty || t == "null") return null;
  return t;
}

String? _n(num? n) {
  if (n == null) return null;
  return n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(2);
}

String? _d(dynamic v) {
  try {
    final String? raw = _s(v);
    if (raw == null) return null;
    final DateTime? d = DateTime.tryParse(raw);
    if (d == null) return raw;
    final DateTime l = d.toLocal();
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(l.day)} ${m[l.month - 1]} ${l.year}, ${two(l.hour)}:${two(l.minute)}';
  } catch (_) {
    return null;
  }
}

// =============================================================================
// CONFIRM DIALOG / FULLSCREEN
// =============================================================================
Future<bool> _confirm({
  required String title,
  required String message,
  required String confirmLabel,
  required IconData icon,
}) async {
  try {
    final bool? r = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: _C.surface,
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _C.border),
        ),
        title: Row(
          children: [
            Icon(icon, color: _C.mint),
            const SizedBox(width: 10),
            Flexible(
              child: Text(title,
                  style: const TextStyle(
                      color: _C.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Text(message,
            style: const TextStyle(color: _C.muted, height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel", style: TextStyle(color: _C.muted)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.accent,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return r == true;
  } catch (obj) {
    print(obj.toString());
    return false;
  }
}

void _openFullscreen(String label, Widget child) {
  try {
    Get.dialog(
      _FullscreenViewer(label: label, child: child),
      barrierColor: Colors.black87,
      useSafeArea: false,
    );
  } catch (obj) {
    print(obj.toString());
  }
}

ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
  foregroundColor: _C.text,
  minimumSize: const Size(0, 42),
  side: const BorderSide(color: _C.border, width: 1.2),
  textStyle: const TextStyle(fontWeight: FontWeight.w600),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

// =============================================================================
// SHARED UI PIECES
// =============================================================================
class _Entrance extends StatelessWidget {
  final int index;
  final Widget child;
  const _Entrance({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + (index * 90).clamp(0, 450)),
      curve: Curves.easeOutCubic,
      builder: (context, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: ch),
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: _C.surface.withOpacity(.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.28),
              blurRadius: 22,
              offset: const Offset(0, 9)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _C.mint.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.mint.withOpacity(.35)),
                ),
                child: Icon(icon, color: _C.mint, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: _C.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                        const TextStyle(color: _C.muted, fontSize: 12.5)),
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
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Chip({required this.icon, required this.text, this.color = _C.mint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  final String text;
  const _MiniLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: _C.text, fontSize: 13.5, fontWeight: FontWeight.w700));
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.mint.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.mint.withOpacity(.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: _C.mint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: _C.muted, fontSize: 12.5, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _StateBanner extends StatelessWidget {
  final bool done;
  final String doneText;
  final String pendingText;
  final IconData pendingIcon;
  const _StateBanner({
    required this.done,
    required this.doneText,
    required this.pendingText,
    this.pendingIcon = Icons.hourglass_empty_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.bar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: done ? _C.mint : _C.border, width: done ? 1.4 : 1),
        boxShadow: done
            ? [
          BoxShadow(
              color: _C.mint.withOpacity(.16),
              blurRadius: 12,
              spreadRadius: 1)
        ]
            : [],
      ),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle_rounded : pendingIcon,
              color: done ? _C.mint : _C.warn, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(done ? doneText : pendingText,
                style: TextStyle(
                    color: done ? _C.text : _C.muted,
                    fontSize: 13,
                    fontWeight: done ? FontWeight.w600 : FontWeight.w400)),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  final bool outlined;
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null && !loading;
    return SizedBox(
      height: 50,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loading ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: outlined
                  ? null
                  : LinearGradient(colors: [
                _C.accent.withOpacity(disabled ? .45 : 1),
                _C.mint.withOpacity(disabled ? .45 : 1),
              ]),
              color: outlined ? _C.surface : null,
              border: outlined ? Border.all(color: _C.border) : null,
              boxShadow: outlined || disabled
                  ? []
                  : [
                BoxShadow(
                    color: _C.accent.withOpacity(.32),
                    blurRadius: 16,
                    offset: const Offset(0, 7)),
              ],
            ),
            child: loading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(_C.bg)),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 18,
                    color: outlined
                        ? _C.mint.withOpacity(disabled ? .5 : 1)
                        : _C.bg),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                          color: outlined
                              ? _C.text.withOpacity(disabled ? .5 : 1)
                              : _C.bg,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- info pieces
class _InfoGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _InfoGroup(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _C.mint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _C.mint,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, b) {
            final int cols = b.maxWidth >= 520 ? 2 : 1;
            final double w =
            math.max(0.0, (b.maxWidth - (cols - 1) * 10) / cols);
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final ch in children) SizedBox(width: w, child: ch)],
            );
          }),
        ],
      ),
    );
  }
}

BoxDecoration _tileDeco() => BoxDecoration(
  color: _C.bg.withOpacity(.55),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: _C.border),
);

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  const _InfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final bool empty = value == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _tileDeco(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _C.mint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: _C.muted, fontSize: 11.5)),
                const SizedBox(height: 2),
                Text(empty ? "No data available" : value!,
                    softWrap: true,
                    style: TextStyle(
                        color: empty ? _C.muted : _C.text,
                        fontSize: 13.5,
                        height: 1.35,
                        fontStyle: empty ? FontStyle.italic : FontStyle.normal,
                        fontWeight:
                        empty ? FontWeight.w400 : FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final String label;
  final bool? value;
  const _StatusTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final bool known = value != null;
    final bool yes = value == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _tileDeco(),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: _C.muted, fontSize: 12.5)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: _Chip(
              icon: !known
                  ? Icons.help_outline_rounded
                  : (yes ? Icons.check_circle_rounded : Icons.cancel_rounded),
              text: !known ? "No data available" : (yes ? "Yes" : "No"),
              color: !known ? _C.muted : (yes ? _C.mint : _C.warn),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingTile extends StatelessWidget {
  final String label;
  final num? value;
  const _RatingTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final num? v = value;
    final bool none = v == null;
    final bool unrated = v != null && v <= 0;
    final double frac = (v == null ? 0.0 : (v / 10).clamp(0.0, 1.0)).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: _tileDeco(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star_rounded, size: 20, color: _C.warn),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: _C.muted, fontSize: 11.5)),
                const SizedBox(height: 3),
                Text(
                  none
                      ? "No data available"
                      : (unrated ? "Not rated yet" : "${_n(v)} / 10"),
                  style: TextStyle(
                      color: none || unrated ? _C.muted : _C.text,
                      fontSize: none || unrated ? 13.5 : 17,
                      fontStyle:
                      none ? FontStyle.italic : FontStyle.normal,
                      fontWeight: FontWeight.w800),
                ),
                if (!none && !unrated) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: frac),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, _) => LinearProgressIndicator(
                        value: t,
                        minHeight: 7,
                        backgroundColor: _C.border,
                        valueColor:
                        const AlwaysStoppedAnimation<Color>(_C.warn),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- photo pieces
class _PhotoFrame extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool white;
  const _PhotoFrame({required this.child, this.onTap, this.white = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(white ? 10 : 8),
      decoration: BoxDecoration(
        color: white ? Colors.white : _C.frame,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
              color: _C.accent.withOpacity(.14),
              blurRadius: 22,
              spreadRadius: 1),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (onTap != null) ...[
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _C.bar.withOpacity(.85),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _C.border),
                  ),
                  child: const Icon(Icons.zoom_out_map_rounded,
                      color: _C.mint, size: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BrokenIcon extends StatelessWidget {
  const _BrokenIcon();

  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(Icons.broken_image_outlined, color: _C.muted, size: 36),
  );
}

class _NetPhoto extends StatelessWidget {
  final String url;
  const _NetPhoto({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, p) => p == null
          ? child
          : const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: _C.accent),
        ),
      ),
      errorBuilder: (context, e, st) {
        print("Photo loading failed: $e");
        return const _BrokenIcon();
      },
    );
  }
}

class _AssetPhoto extends StatelessWidget {
  final String path;
  const _AssetPhoto({required this.path});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (context, e, st) {
        print("Asset loading failed ($path): $e");
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_not_supported_rounded,
                    color: _C.muted, size: 34),
                SizedBox(height: 8),
                Text("Example not available",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _C.muted, fontSize: 12.5)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MemoryPhoto extends StatelessWidget {
  final Uint8List bytes;
  const _MemoryPhoto({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, e, st) => const _BrokenIcon(),
    );
  }
}

class _MediaMessage extends StatelessWidget {
  final double side;
  final String text;
  const _MediaMessage({required this.side, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: side,
        height: math.min(side, 220.0),
        child: Container(
          decoration: BoxDecoration(
            color: _C.frame,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.image_outlined, color: _C.muted, size: 36),
                    const SizedBox(height: 10),
                    Text(text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: _C.muted, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      decoration: BoxDecoration(
        color: _C.surface.withOpacity(.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, color: _C.muted, size: 46),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _C.muted, fontSize: 14)),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox();

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: .4, end: 1)
          .animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border),
        ),
      ),
    );
  }
}

// =============================================================================
// FULLSCREEN VIEWER
// =============================================================================
class _FullscreenViewer extends StatelessWidget {
  final String label;
  final Widget child;
  const _FullscreenViewer({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Material(
        color: _C.bg,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: _C.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: "Close",
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Get.back(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.text, width: 1.2),
                          ),
                          child:
                          const Icon(Icons.close_rounded, color: _C.text),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: InteractiveViewer(
                    minScale: .8,
                    maxScale: 5,
                    child: Center(child: child),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// AMBIENT BACKGROUND — heavily blurred emerald/mint blobs + glass bubbles.
// Wrapped in IgnorePointer by the caller, so it can never block taps.
// =============================================================================
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  Widget _blob({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: ImageFiltered(
        imageFilter:
        ImageFilter.blur(sigmaX: 45, sigmaY: 45, tileMode: TileMode.decal),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withOpacity(opacity), color.withOpacity(0)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(.07),
              Colors.white.withOpacity(.01)
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(.07)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(builder: (context, box) {
        final double w = box.hasBoundedWidth ? box.maxWidth : 800;
        final double h = box.hasBoundedHeight ? box.maxHeight : 800;
        final double base = math.max(w, h);
        final double small = math.min(w, h);

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            _blob(left: -w * .18, top: -h * .12, size: base * .70, color: _C.accent, opacity: .16),
            _blob(right: -w * .22, top: h * .28, size: base * .60, color: _C.mint, opacity: .12),
            _blob(left: w * .08, bottom: -h * .22, size: base * .75, color: _C.accent, opacity: .12),
            _bubble(right: w * .10, top: h * .06, size: (small * .16).clamp(40.0, 150.0).toDouble()),
            _bubble(left: w * .06, top: h * .42, size: (small * .10).clamp(28.0, 100.0).toDouble()),
            _bubble(right: w * .18, bottom: h * .10, size: (small * .20).clamp(50.0, 190.0).toDouble()),
            _bubble(left: w * .40, bottom: h * .04, size: (small * .07).clamp(20.0, 70.0).toDouble()),
          ],
        );
      }),
    );
  }
}