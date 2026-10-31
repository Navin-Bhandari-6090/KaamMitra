import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:app/web/bookings/pro_task_complete_status.dart';
import 'package:app/web/bookings/view_book_file.dart';
import 'package:app/web/bookings/view_book_video.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../constant/Server_Database.dart';
import '../../models/BookingInfoModel.dart';
import '../../state management/getx/booking/ProviderBookingDetalsGetX.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/getx_cont_pick_single_photo_int.dart';
import '../common widget/toast.dart';

// =============================================================================
// PALETTE — Dark Forest / Emerald Glow
// =============================================================================
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
// DATA HELPERS — null / empty -> null (UI then shows "No data available")
// =============================================================================
String? _s(Object? v) {
  if (v == null) return null;
  final String t = v.toString().trim();
  return (t.isEmpty || t == "null") ? null : t;
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(l.day)} ${m[l.month - 1]} ${l.year}, ${two(l.hour)}:${two(l.minute)}';
  } catch (_) {
    return null;
  }
}

// =============================================================================
// SCREEN
// =============================================================================
class Providerbookinginfodetailsscreen extends StatefulWidget {
  final String Current_User_Email;
  final String Current_User_JwtToken;
  final String Current_User_Role;
  final int Current_User_Number;
  final List<BookingInfoModel> BookingInfoListInfo;

  const Providerbookinginfodetailsscreen({
    super.key,
    required this.Current_User_Email,
    required this.Current_User_JwtToken,
    required this.Current_User_Role,
    required this.BookingInfoListInfo,
    required this.Current_User_Number,
  });

  @override
  State<Providerbookinginfodetailsscreen> createState() =>
      _ProviderbookinginfodetailsscreenState();
}

class _ProviderbookinginfodetailsscreenState
    extends State<Providerbookinginfodetailsscreen> {
  final StartDateController = TextEditingController();
  final EndDateController = TextEditingController();
  final StartDateAmOrPmController = TextEditingController();
  final EndDateAmOrPmController = TextEditingController();
  final AdvanceAmountController = TextEditingController();
  final ProviderDescriptionCont = TextEditingController();

  final Toast = Toastget();

  final PickPhotoCont = Get.put(pick_single_photo_getx_int());
  final c = Get.put(Providerbookingdetalsgetx());

  // Cached futures: the network call runs once per refresh toggle, not per rebuild.
  bool? _photoFutureKey;
  Future<int>? _photoFuture;
  Future<int>? _qrFuture;

  BookingInfoModel? get _booking =>
      widget.BookingInfoListInfo.isEmpty ? null : widget.BookingInfoListInfo[0];

  @override
  void initState() {
    super.initState();
    Provider_Jwt_Verify(Jwt_Token: widget.Current_User_JwtToken);
    final b = _booking;
    c.seed(
      providerApproval: b?.providerApprovalStatus,
      providerTaskComplete: b?.providerTaskCompleteStatus,
      customerApproval: b?.userApprovalStatus,
      customerTaskComplete: b?.userTaskCompleteStatus,
      advanceAmount: b?.advancePaymentAmount,
    );
  }

  @override
  void dispose() {
    try {
      PickPhotoCont.imageBytes.value = null;
      PickPhotoCont.imageExtension.value = "";
      PickPhotoCont.imagePath.value = "";
    } catch (e) {
      print(e);
    }
    for (final t in [
      StartDateController,
      EndDateController,
      StartDateAmOrPmController,
      EndDateAmOrPmController,
      AdvanceAmountController,
      ProviderDescriptionCont,
    ]) {
      try {
        t.dispose();
      } catch (e) {
        print(e);
      }
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // SESSION
  // ---------------------------------------------------------------------------
  Future<void> _forceRelogin() async {
    try {
      await Clear_User_Data();
      await Random_token_Clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => ErrorPage()),
        (route) => false,
      );
      Toast.Toastmsg("Session ended. Please log in again.");
    } catch (e) {
      print(e);
    }
  }

  Future<void> Provider_Jwt_Verify({required String Jwt_Token}) async {
    try {
      final int result = await ProviderJwtVerify(Jwt_Token: Jwt_Token);
      if (result != 1) await _forceRelogin();
    } catch (e) {
      print("Unexpected error in Provider_Jwt_Verify: $e");
      Toast.Toastmsg("Something went wrong. Please try again.");
      await _forceRelogin();
    }
  }

  // ---------------------------------------------------------------------------
  // NETWORK
  // ---------------------------------------------------------------------------
  Future<http.Response> _putJson(String path, Map<String, dynamic> body) {
    return http.put(
      Uri.parse(Backend_Server_Url + path),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer ${widget.Current_User_JwtToken}',
      },
      body: json.encode(body),
    );
  }

  DateTime? parseDateTimeWithAmPm(String dateTimeText, String amPm) {
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$');
    if (!regex.hasMatch(dateTimeText)) return null;

    final period = amPm.trim().toLowerCase();
    if (period != 'am' && period != 'pm') return null;

    final parts = dateTimeText.split(' ');
    final dateParts = parts[0].split('-');
    final timeParts = parts[1].split(':');

    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);

    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    if (hour < 1 || hour > 12) return null;
    if (minute < 0 || minute > 59) return null;

    if (period == 'am') {
      if (hour == 12) hour = 0;
    } else {
      if (hour != 12) hour += 12;
    }

    try {
      final dateTime = DateTime(year, month, day, hour, minute);
      // DateTime() normalises invalid dates, so verify the parts match exactly.
      if (dateTime.year != year ||
          dateTime.month != month ||
          dateTime.day != day ||
          dateTime.hour != hour ||
          dateTime.minute != minute) {
        return null;
      }
      return dateTime;
    } catch (e) {
      return null;
    }
  }

  Future<int> UpdateDate({
    required String UserEmail,
    required num BookId,
    required String StartDate,
    required String EndDate,
  }) async {
    try {
      final r = await _putJson("api/Booking/updatedate", {
        "UserEmail": UserEmail,
        "BookId": BookId,
        "StartDate": StartDate,
        "EndDate": EndDate,
      });
      switch (r.statusCode) {
        case 200:
          Toast.Toastmsg("Schedule updated.");
          return 1;
        case 500:
          Toast.Toastmsg("Server error. Please try again.");
          return 2;
        case 502:
          await _forceRelogin();
          return 3;
        case 503:
          Toast.Toastmsg("No booking found for this ID.");
          return 4;
        case 501:
          Toast.Toastmsg("Invalid data format.");
          return 5;
        default:
          Toast.Toastmsg("Update failed. Try again.");
          return 6;
      }
    } catch (e) {
      print(e);
      Toast.Toastmsg("Update failed. Try again.");
      return 7;
    }
  }

  Future<int> UpdateAdvanceAmount({
    required String UserEmail,
    required num BookId,
    required double AdvanceAmount,
  }) async {
    try {
      final r = await _putJson("api/Booking/updateadvanceamount", {
        "UserEmail": UserEmail,
        "BookId": BookId,
        "AdvancePaymentAmount": AdvanceAmount,
      });
      switch (r.statusCode) {
        case 200:
          Toast.Toastmsg("Advance amount updated.");
          return 1;
        case 500:
          Toast.Toastmsg("Server error. Please try again.");
          return 2;
        case 502:
          await _forceRelogin();
          return 3;
        case 503:
          Toast.Toastmsg("No booking found for this ID.");
          return 4;
        case 501:
          Toast.Toastmsg("Invalid data format.");
          return 5;
        case 504:
          Toast.Toastmsg("Advance amount was already changed.");
          return 8;
        default:
          Toast.Toastmsg("Update failed. Try again.");
          return 6;
      }
    } catch (e) {
      print(e);
      Toast.Toastmsg("Update failed. Try again.");
      return 7;
    }
  }

  Future<int> UpdateProviderApprovalStatus({
    required String UserEmail,
    required num BookId,
  }) async {
    try {
      final r = await _putJson("api/Booking/updateproviderapprovalstatus", {
        "UserEmail": UserEmail,
        "BookId": BookId,
      });
      switch (r.statusCode) {
        case 200:
          Toast.Toastmsg("Approval updated.");
          return 1;
        case 500:
          Toast.Toastmsg("Server error. Please try again.");
          return 2;
        case 502:
          await _forceRelogin();
          return 3;
        case 503:
          Toast.Toastmsg("No booking found for this ID.");
          return 4;
        case 504:
          Toast.Toastmsg("You have already approved this booking.");
          return 8;
        case 501:
          Toast.Toastmsg("Invalid data format.");
          return 5;
        default:
          Toast.Toastmsg("Update failed. Try again.");
          return 6;
      }
    } catch (e) {
      print(e);
      Toast.Toastmsg("Update failed. Try again.");
      return 7;
    }
  }

  Future<int> UpdateDescription({
    required String UserEmail,
    required num BookId,
    required String UserBookingDescription,
  }) async {
    try {
      final r = await _putJson("api/Booking/updateproviderdescp", {
        "UserEmail": UserEmail,
        "BookId": BookId,
        "UserBookingDescription": UserBookingDescription,
      });
      switch (r.statusCode) {
        case 200:
          Toast.Toastmsg("Description updated.");
          return 1;
        case 500:
          Toast.Toastmsg("Server error. Please try again.");
          return 2;
        case 502:
          await _forceRelogin();
          return 3;
        case 503:
          Toast.Toastmsg("No booking found for this ID.");
          return 4;
        case 501:
          Toast.Toastmsg("Invalid data format.");
          return 5;
        default:
          Toast.Toastmsg("Update failed. Try again.");
          return 6;
      }
    } catch (e) {
      print(e);
      Toast.Toastmsg("Update failed. Try again.");
      return 7;
    }
  }

  // ---------------------------------------------------------------------------
  // ACTIONS (each one asks for confirmation first)
  // ---------------------------------------------------------------------------
  Future<void> _onSaveSchedule() async {
    if (c.busyKey.value.isNotEmpty) return;
    try {
      final b = _booking;
      if (b == null || b.bookId == null) {
        Toast.Toastmsg("No booking data available.");
        return;
      }
      if ([
        StartDateController,
        EndDateController,
        StartDateAmOrPmController,
        EndDateAmOrPmController,
      ].any((t) => t.text.trim().isEmpty)) {
        Toast.Toastmsg("All date and time fields are required.");
        return;
      }

      final start = parseDateTimeWithAmPm(
        StartDateController.text.trim(),
        StartDateAmOrPmController.text,
      );
      if (start == null) {
        Toast.Toastmsg(
          "Invalid start date/time. Use yyyy-MM-dd hh:mm and AM/PM.",
        );
        return;
      }
      final end = parseDateTimeWithAmPm(
        EndDateController.text.trim(),
        EndDateAmOrPmController.text,
      );
      if (end == null) {
        Toast.Toastmsg(
          "Invalid end date/time. Use yyyy-MM-dd hh:mm and AM/PM.",
        );
        return;
      }
      if (end.isBefore(start)) {
        Toast.Toastmsg("End date/time cannot be before start date/time.");
        return;
      }

      final ok = await _confirm(
        title: "Update schedule?",
        message:
            "Booking #${b.bookId} will start ${StartDateController.text.trim()} ${StartDateAmOrPmController.text.trim().toUpperCase()} "
            "and end ${EndDateController.text.trim()} ${EndDateAmOrPmController.text.trim().toUpperCase()}.",
        confirmLabel: "Update",
        icon: Icons.event_available_rounded,
      );
      if (!ok) return;

      c.busyKey.value = 'date';
      await UpdateDate(
        UserEmail: widget.Current_User_Email,
        BookId: b.bookId!,
        StartDate: start.toIso8601String(),
        EndDate: end.toIso8601String(),
      );
    } catch (e) {
      print(e);
      Toast.Toastmsg("Something went wrong.");
    } finally {
      c.busyKey.value = '';
    }
  }

  Future<void> _onSaveAdvance() async {
    if (c.busyKey.value.isNotEmpty) return;
    try {
      final b = _booking;
      if (b == null || b.bookId == null || b.userNumber == null) {
        Toast.Toastmsg("No booking data available.");
        return;
      }
      final double? amount = double.tryParse(
        AdvanceAmountController.text.trim(),
      );
      if (amount == null || amount <= 0) {
        Toast.Toastmsg("Advance amount should be greater than 0.");
        return;
      }

      final ok = await _confirm(
        title: "Update advance amount?",
        message:
            "Advance amount for booking #${b.bookId} will be set to $amount. The customer will be notified.",
        confirmLabel: "Update",
        icon: Icons.account_balance_wallet_rounded,
      );
      if (!ok) return;

      c.busyKey.value = 'advance';
      final result = await UpdateAdvanceAmount(
        UserEmail: widget.Current_User_Email,
        BookId: b.bookId!,
        AdvanceAmount: amount,
      );
      if (result == 1) {
        c.advanceAmount.value = amount;
        AdvanceAmountController.clear();
      }

      await AddNotifications(
        ReceiverNumber: b.userNumber!,
        Message:
            "Provider updated the advance amount to $amount for booking #${b.bookId}.",
        Current_User_JwtToken: widget.Current_User_JwtToken,
        context: context,
      );
      await AddNewNotifications(
        ReceiverNumber: b.userNumber!,
        Status: true,
        Current_User_JwtToken: widget.Current_User_JwtToken,
        context: context,
      );
    } catch (e) {
      print(e);
      Toast.Toastmsg("Something went wrong.");
    } finally {
      c.busyKey.value = '';
    }
  }

  Future<void> _onApproval() async {
    if (c.busyKey.value.isNotEmpty) return;
    try {
      final b = _booking;
      if (b == null || b.bookId == null || b.userNumber == null) {
        Toast.Toastmsg("No booking data available.");
        return;
      }

      final ok = await _confirm(
        title: "Approve booking?",
        message:
            "Your approval for booking #${b.bookId} will be saved and the customer will be notified.",
        confirmLabel: "Approve",
        icon: Icons.verified_rounded,
      );
      if (!ok) return;

      c.busyKey.value = 'approval';
      final result = await UpdateProviderApprovalStatus(
        UserEmail: widget.Current_User_Email,
        BookId: b.bookId!,
      );
      if (result == 1 || result == 8) c.providerApproval.value = true;

      await AddNotifications(
        ReceiverNumber: b.userNumber!,
        Message:
            "Provider changed the approval status for booking #${b.bookId}.",
        Current_User_JwtToken: widget.Current_User_JwtToken,
        context: context,
      );
      await AddNewNotifications(
        ReceiverNumber: b.userNumber!,
        Status: true,
        Current_User_JwtToken: widget.Current_User_JwtToken,
        context: context,
      );
    } catch (e) {
      print(e);
      Toast.Toastmsg("Something went wrong.");
    } finally {
      c.busyKey.value = '';
    }
  }

  Future<void> _onSaveDescription() async {
    if (c.busyKey.value.isNotEmpty) return;
    try {
      final b = _booking;
      if (b == null || b.bookId == null) {
        Toast.Toastmsg("No booking data available.");
        return;
      }
      final text = ProviderDescriptionCont.text.trim();
      if (text.isEmpty) {
        Toast.Toastmsg("Description field is required.");
        return;
      }

      final ok = await _confirm(
        title: "Update description?",
        message:
            "The service description for booking #${b.bookId} will be saved.",
        confirmLabel: "Save",
        icon: Icons.description_rounded,
      );
      if (!ok) return;

      c.busyKey.value = 'desc';
      await UpdateDescription(
        UserEmail: widget.Current_User_Email,
        BookId: b.bookId!,
        UserBookingDescription: text,
      );
    } catch (e) {
      print(e);
      Toast.Toastmsg("Something went wrong.");
    } finally {
      c.busyKey.value = '';
    }
  }

  Future<void> _openTaskComplete() async {
    try {
      final bool? changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ProTaskCompleteStatus(
            Current_User_Email: widget.Current_User_Email,
            Current_User_JwtToken: widget.Current_User_JwtToken,
            Current_User_Role: widget.Current_User_Role,
            Current_User_Number: widget.Current_User_Number,
            BookingInfoListInfo: widget.BookingInfoListInfo,
          ),
        ),
      );
      // ProTaskCompleteStatus pops with `true` after a successful update.
      if (changed == true) c.providerTaskComplete.value = true;
    } catch (e) {
      print(e);
    }
  }

  // ---------------------------------------------------------------------------
  // PHOTO FUTURES (cached)
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

  Future<int> _qrFutureFor(BookingInfoModel b) {
    _qrFuture ??= GetAdvancePaymentQRPhoto(
      UserNumber: b.providerNumber!,
      context: context,
      Current_User_JwtToken: widget.Current_User_JwtToken,
    );
    return _qrFuture!;
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
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
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: _C.text,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          "Provider Booking",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _C.text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.border),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: _AmbientBackground()),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final double hPad = box.maxWidth >= 700 ? 24 : 14;
                final bool wide = box.maxWidth >= 980;
                final BookingInfoModel? b = _booking;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        children: [
                          _buildHeader(b),
                          const SizedBox(height: 22),
                          if (b == null)
                            const _EmptyState(
                              text: "No booking data available.",
                            )
                          else
                            _buildContent(b, wide),
                        ],
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

  Widget _buildContent(BookingInfoModel b, bool wide) {
    final details = _Entrance(
      index: 0,
      child: _SectionCard(
        icon: Icons.info_outline_rounded,
        title: "Booking details",
        subtitle: "Service, schedule and customer information.",
        child: _buildDetailsGrid(b),
      ),
    );

    final schedule = _Entrance(index: 1, child: _buildScheduleCard());
    final advance = _Entrance(index: 2, child: _buildAdvanceAmountCard());
    final approval = _Entrance(index: 3, child: _buildApprovalCard());
    final description = _Entrance(index: 4, child: _buildDescriptionCard());
    final task = _Entrance(index: 5, child: _buildTaskCard());
    final photo = _Entrance(index: 6, child: _buildAdvancePhotoCard(b));
    final qr = _Entrance(index: 7, child: _buildQrCard(b));

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(children: _spaced([details, photo, qr], 16)),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 5,
            child: Column(
              children: _spaced([
                schedule,
                advance,
                approval,
                description,
                task,
              ], 16),
            ),
          ),
        ],
      );
    }
    return Column(
      children: _spaced([
        details,
        schedule,
        advance,
        approval,
        description,
        task,
        photo,
        qr,
      ], 16),
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
  // HEADER
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
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.handyman_rounded, color: _C.bg, size: 30),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          "Manage Your Booking",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _C.text,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Schedule, pricing, approval and payment proof — all in one place.",
          textAlign: TextAlign.center,
          style: TextStyle(color: _C.muted, fontSize: 13, height: 1.4),
        ),
        if (b != null) ...[
          const SizedBox(height: 12),
          Obx(() {
            final bool? appr = c.providerApproval.value;
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(
                  icon: Icons.tag_rounded,
                  text: "Booking #${_n(b.bookId) ?? '—'}",
                ),
                _Chip(
                  icon: appr == true
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_empty_rounded,
                  text: appr == true ? "Approved" : "Approval pending",
                  color: appr == true ? _C.mint : _C.warn,
                ),
              ],
            );
          }),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // DETAILS — same groups and fields as the user details screen
  // ---------------------------------------------------------------------------
  Widget _buildDetailsGrid(BookingInfoModel b) {
    String? coords(num? lat, num? lon) =>
        (lat == null || lon == null) ? null : "$lat, $lon";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoGroup(
          title: "Service",
          icon: Icons.handyman_rounded,
          children: [
            _InfoTile(
              Icons.design_services_rounded,
              "Service name",
              _s(b.serviceName),
            ),
            _InfoTile(Icons.tag_rounded, "Booking ID", _n(b.bookId)),
            _InfoTile(
              Icons.straighten_rounded,
              "Distance",
              b.distance == null ? null : "${_n(b.distance)} km",
            ),
            _InfoTile(Icons.schedule_rounded, "Created at", _d(b.createdAt)),
          ],
        ),
        _InfoGroup(
          title: "Schedule & payment",
          icon: Icons.payments_rounded,
          children: [
            _InfoTile(Icons.play_arrow_rounded, "Start date", _d(b.startDate)),
            _InfoTile(Icons.stop_rounded, "End date", _d(b.endDate)),
            Obx(
              () => _InfoTile(
                Icons.account_balance_wallet_rounded,
                "Advance payment amount",
                _n(c.advanceAmount.value),
              ),
            ),
            _StatusTile("Advance payment required", b.requiredAdvancePayment),
          ],
        ),
        _InfoGroup(
          title: "Status",
          icon: Icons.fact_check_rounded,
          children: [
            Obx(() => _StatusTile("Your approval", c.providerApproval.value)),
            Obx(
              () => _StatusTile(
                "Your task complete",
                c.providerTaskComplete.value,
              ),
            ),
            Obx(
              () => _StatusTile("Customer approval", c.customerApproval.value),
            ),
            Obx(
              () => _StatusTile(
                "Customer task complete",
                c.customerTaskComplete.value,
              ),
            ),
          ],
        ),
        _InfoGroup(
          title: "Customer details",
          icon: Icons.person_rounded,
          children: [
            _InfoTile(Icons.tag_rounded, "ID", _n(b.userNumber)),
            _InfoTile(
              Icons.phone_rounded,
              "Phone number",
              _s(b.userPhoneNumber),
            ),
            // _InfoTile(
            //   Icons.chat_rounded,
            //   "WhatsApp number",
            //   _s(b.userWhatsappPhoneNumber),
            // ),
            _InfoTile(Icons.location_on_rounded, "Address", _s(b.userAddress)),
            _InfoTile(
              Icons.my_location_rounded,
              "Latitude,Longitude",
              coords(b.userLatitude, b.userLongitude),
            ),
            _InfoTile(
              Icons.notes_rounded,
              "Booking description",
              _s(b.userBookingDescription),
            ),
          ],
        ),
        _InfoGroup(
          title: "Provider details",
          icon: Icons.engineering_rounded,
          children: [
            _InfoTile(
              Icons.tag_rounded,
              "ID",
              _n(b.providerNumber),
            ),
            _InfoTile(
              Icons.phone_rounded,
              "Phone number",
              _s(b.providerPhoneNumber),
            ),
            // _InfoTile(
            //   Icons.chat_rounded,
            //   "WhatsApp number",
            //   _s(b.providerWhatsappPhoneNumber),
            // ),
            _InfoTile(
              Icons.location_on_rounded,
              "Address",
              _s(b.providerAddress),
            ),
            _InfoTile(
              Icons.my_location_rounded,
              "Latitude,Longitude",
              coords(b.providerLatitude, b.providerLongitude),
            ),
            _InfoTile(
              Icons.notes_rounded,
              "Booking description",
              _s(b.providerBookingDescription),
            ),
          ],
        ),

        SizedBox(height: 10,),
        ElevatedButton(onPressed: (){
          try{
            if(b.bookingFile==null || b.bookingFile!.isEmpty)
            {
              Toast.Toastmsg("No file available.");
              return;
            }
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ViewBookFile(Current_User_JwtToken: widget.Current_User_JwtToken, FilePath: b.bookingFile!,);
            },
            )
            );

          }catch(obj){
            return;
          }

        }, child: Text("View file.")),

        SizedBox(height: 10,),
        ElevatedButton(onPressed: (){
          try{

            if(
            b.bookingVideo==null || b.bookingVideo!.isEmpty){
              Toast.Toastmsg("No video available.");
              return;
            }

            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ViewBookVideo(Current_User_JwtToken: widget.Current_User_JwtToken, VideoPath: b.bookingVideo!,);
          },
          )
          );

          }catch(obj){
            return;
          }
        }, child: Text("View video.")),
        SizedBox(height: 10,),

      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ACTION CARDS
  // ---------------------------------------------------------------------------
  Widget _buildScheduleCard() {
    return _SectionCard(
      icon: Icons.event_available_rounded,
      title: "Update schedule.Refresh booking screen to see changes.",
      subtitle: "Format yyyy-MM-dd hh:mm(2016-02-13 03:09), then choose AM or PM.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            controller: StartDateController,
            label: "Start date & time",
            hint: "2026-06-30 01:03",
            icon: Icons.play_arrow_rounded,
            type: TextInputType.datetime,
          ),
          const SizedBox(height: 8),
          _PeriodSelector(controller: StartDateAmOrPmController),
          const SizedBox(height: 14),
          _field(
            controller: EndDateController,
            label: "End date & time",
            hint: "2026-06-30 05:00",
            icon: Icons.stop_rounded,
            type: TextInputType.datetime,
          ),
          const SizedBox(height: 8),
          _PeriodSelector(controller: EndDateAmOrPmController),
          const SizedBox(height: 16),
          Obx(
            () => _GradientButton(
              label: "Save schedule",
              icon: Icons.save_rounded,
              loading: c.busyKey.value == 'date',
              onTap: c.busyKey.value.isNotEmpty ? null : _onSaveSchedule,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvanceAmountCard() {
    return _SectionCard(
      icon: Icons.payments_rounded,
      title: "Advance payment amount.Refresh booking screen to see changes.",
      subtitle: "Amount the customer should pay in advance.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            controller: AdvanceAmountController,
            label: "Enter advance amount",
            icon: Icons.money_rounded,
            type: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          Obx(
            () => _GradientButton(
              label: "Update advance amount",
              icon: Icons.save_rounded,
              loading: c.busyKey.value == 'advance',
              onTap: c.busyKey.value.isNotEmpty ? null : _onSaveAdvance,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard() {
    return _SectionCard(
      icon: Icons.verified_rounded,
      title: "Provider approvalRefresh booking screen to see changes.",
      subtitle: "Confirm that you accept this booking.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => _StateBanner(
              value: c.providerApproval.value,
              doneText: "You have approved this booking.",
              pendingText: "You have not approved this booking yet.",
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => _GradientButton(
              label: "Approve booking",
              icon: Icons.check_circle_outline_rounded,
              loading: c.busyKey.value == 'approval',
              onTap: c.busyKey.value.isNotEmpty ? null : _onApproval,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return _SectionCard(
      icon: Icons.description_rounded,
      title: "Service description.Refresh booking screen to see changes.",
      subtitle: "Describe the service you will provide.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            controller: ProviderDescriptionCont,
            label: "Enter your service description",
            icon: Icons.notes_rounded,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          Obx(
            () => _GradientButton(
              label: "Save description",
              icon: Icons.save_rounded,
              loading: c.busyKey.value == 'desc',
              onTap: c.busyKey.value.isNotEmpty ? null : _onSaveDescription,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard() {
    return _SectionCard(
      icon: Icons.task_alt_rounded,
      title: "Task completion",
      subtitle: "Mark the task as finished when the work is done.",
      child: _GradientButton(
        outlined: true,
        label: "Open task complete status",
        icon: Icons.arrow_forward_rounded,
        onTap: _openTaskComplete,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PHOTO CARDS
  // ---------------------------------------------------------------------------
  Widget _buildAdvancePhotoCard(BookingInfoModel b) {
    return _SectionCard(
      icon: Icons.receipt_long_rounded,
      title: "Advance payment photo",
      subtitle: "Payment proof uploaded by the customer.",
      trailing: Tooltip(
        message: "Reload photo",
        child: IconButton(
          onPressed: c.ChangeUpdateStatePhotoUpload,
          icon: const Icon(Icons.refresh_rounded, color: _C.mint, size: 20),
        ),
      ),
      child: Obx(() {
        final bool key = c.UpdateStatePhotoUpload.value;
        if (b.bookId == null) {
          return const _MediaMessage(
            text: "No data available. Booking ID is missing.",
          );
        }
        return FutureBuilder<int>(
          future: _photoFutureFor(key, b),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _SkeletonBox(height: 240);
            }
            if (snapshot.hasError) {
              print("Advance payment photo error: ${snapshot.error}");
              return const _MediaMessage(
                text: "Unable to load advance payment photo.",
              );
            }
            if (AdvancePaymentPhotoList.isEmpty) {
              return const _MediaMessage(
                text:
                    "No data available. No advance payment photo uploaded yet.",
              );
            }
            final String url = GetPhotoUrl(
              AdvancePaymentPhotoList[0].paymentPhoto ?? "",
            );
            if (url.isEmpty) {
              return const _MediaMessage(
                text:
                    "No data available. No advance payment photo uploaded yet.",
              );
            }
            return _PhotoBlock(url: url, label: "Advance payment photo");
          },
        );
      }),
    );
  }

  Widget _buildQrCard(BookingInfoModel b) {
    return _SectionCard(
      icon: Icons.qr_code_2_rounded,
      title: "Payment QR code",
      subtitle: "Customer scans this to pay you.",
      child: b.providerNumber == null
          ? const _MediaMessage(
              text: "No data available. Provider number is missing.",
            )
          : FutureBuilder<int>(
              future: _qrFutureFor(b),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _SkeletonBox(height: 240);
                }
                if (snapshot.hasError) {
                  print("Advance payment QR error: ${snapshot.error}");
                  return const _MediaMessage(
                    text: "Unable to load payment QR.",
                  );
                }
                if (AdvancePaymentQrPhotoList.isEmpty) {
                  return const _MediaMessage(
                    text: "No data available. No payment QR uploaded.",
                  );
                }
                final String url = GetPhotoUrl(
                  AdvancePaymentQrPhotoList[0].qrPhoto ?? "",
                );
                if (url.isEmpty) {
                  return const _MediaMessage(
                    text: "No data available. No payment QR uploaded.",
                  );
                }
                return _PhotoBlock(url: url, label: "Payment QR", white: true);
              },
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // FORM FIELD
  // ---------------------------------------------------------------------------
  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? type,
    int maxLines = 1,
  }) {
    OutlineInputBorder border(Color color, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: w),
    );
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(color: _C.text, fontSize: 15),
      cursorColor: _C.mint,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: _C.muted, fontSize: 13),
        labelStyle: const TextStyle(color: _C.muted, fontSize: 13.5),
        floatingLabelStyle: const TextStyle(
          color: _C.mint,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: _C.mint, size: 20),
        filled: true,
        fillColor: _C.bg.withOpacity(.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        enabledBorder: border(_C.border, 1),
        focusedBorder: border(_C.mint, 1.5),
        border: border(_C.border, 1),
      ),
    );
  }
}

// =============================================================================
// SHARED HELPERS
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
              child: Text(
                title,
                style: const TextStyle(
                  color: _C.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: _C.muted, height: 1.5),
        ),
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return r == true;
  } catch (e) {
    print(e);
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
  } catch (e) {
    print(e);
  }
}

ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
  foregroundColor: _C.text,
  minimumSize: const Size(0, 42),
  side: const BorderSide(color: _C.border, width: 1.2),
  textStyle: const TextStyle(fontWeight: FontWeight.w600),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

BoxDecoration _tileDeco() => BoxDecoration(
  color: _C.bg.withOpacity(.55),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: _C.border),
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
      duration: Duration(milliseconds: 420 + math.min(index * 90, 450)),
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
  final Widget? trailing;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
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
            offset: const Offset(0, 9),
          ),
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
                    Text(
                      title,
                      style: const TextStyle(
                        color: _C.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _C.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
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
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _InfoGroup({
    required this.title,
    required this.icon,
    required this.children,
  });

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
                child: Text(
                  title.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _C.mint,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, b) {
              final int cols = b.maxWidth >= 520 ? 2 : 1;
              final double w = math.max(
                0.0,
                (b.maxWidth - (cols - 1) * 10) / cols,
              );
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final ch in children) SizedBox(width: w, child: ch),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

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
                Text(
                  label,
                  style: const TextStyle(color: _C.muted, fontSize: 11.5),
                ),
                const SizedBox(height: 2),
                Text(
                  empty ? "No data available" : value!,
                  softWrap: true,
                  style: TextStyle(
                    color: empty ? _C.muted : _C.text,
                    fontSize: 13.5,
                    height: 1.35,
                    fontStyle: empty ? FontStyle.italic : FontStyle.normal,
                    fontWeight: empty ? FontWeight.w400 : FontWeight.w600,
                  ),
                ),
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
            child: Text(
              label,
              style: const TextStyle(color: _C.muted, fontSize: 12.5),
            ),
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

class _StateBanner extends StatelessWidget {
  final bool? value;
  final String doneText;
  final String pendingText;
  const _StateBanner({
    required this.value,
    required this.doneText,
    required this.pendingText,
  });

  @override
  Widget build(BuildContext context) {
    final bool done = value == true;
    final bool known = value != null;
    final String text = !known
        ? "No data available"
        : (done ? doneText : pendingText);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.bar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done ? _C.mint : _C.border,
          width: done ? 1.4 : 1,
        ),
        boxShadow: done
            ? [
                BoxShadow(
                  color: _C.mint.withOpacity(.16),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
            color: done ? _C.mint : _C.warn,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: done ? _C.text : _C.muted,
                fontSize: 13,
                fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                fontStyle: known ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final TextEditingController controller;
  const _PeriodSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, v, _) {
        final String cur = v.text.trim().toLowerCase();

        Widget seg(String label) {
          final bool on = cur == label.toLowerCase();
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                controller.text = label.toLowerCase();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: on
                      ? const LinearGradient(colors: [_C.accent, _C.mint])
                      : null,
                  color: on ? null : _C.bar,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: on ? Colors.transparent : _C.border,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: on ? _C.bg : _C.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          );
        }

        return Row(children: [seg("AM"), const SizedBox(width: 8), seg("PM")]);
      },
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
                  : LinearGradient(
                      colors: [
                        _C.accent.withOpacity(disabled ? .45 : 1),
                        _C.mint.withOpacity(disabled ? .45 : 1),
                      ],
                    ),
              color: outlined ? _C.surface : null,
              border: outlined ? Border.all(color: _C.border) : null,
              boxShadow: outlined || disabled
                  ? []
                  : [
                      BoxShadow(
                        color: _C.accent.withOpacity(.32),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(_C.bg),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: outlined
                            ? _C.mint.withOpacity(disabled ? .5 : 1)
                            : _C.bg,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            color: outlined
                                ? _C.text.withOpacity(disabled ? .5 : 1)
                                : _C.bg,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
}

// ---------------------------------------------------------------- photo pieces
class _PhotoBlock extends StatelessWidget {
  final String url;
  final String label;
  final bool white;
  const _PhotoBlock({
    required this.url,
    required this.label,
    this.white = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: AspectRatio(
              aspectRatio: 1,
              child: _PhotoFrame(
                white: white,
                onTap: () => _openFullscreen(
                  label,
                  _PhotoFrame(
                    white: white,
                    child: _NetPhoto(url: url),
                  ),
                ),
                child: _NetPhoto(url: url),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => _openFullscreen(
              label,
              _PhotoFrame(
                white: white,
                child: _NetPhoto(url: url),
              ),
            ),
            icon: const Icon(Icons.fullscreen_rounded, size: 20),
            label: const Text("Full screen"),
            style: _outlinedStyle(),
          ),
        ),
      ],
    );
  }
}

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
            spreadRadius: 1,
          ),
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
              right: 6,
              bottom: 6,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _C.bar.withOpacity(.85),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _C.border),
                  ),
                  child: const Icon(
                    Icons.zoom_out_map_rounded,
                    color: _C.mint,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
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
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _C.accent,
                ),
              ),
            ),
      errorBuilder: (context, e, st) {
        print("Photo loading failed: $e");
        return const Center(
          child: Icon(Icons.broken_image_outlined, color: _C.muted, size: 36),
        );
      },
    );
  }
}

class _MediaMessage extends StatelessWidget {
  final String text;
  const _MediaMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.frame,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, color: _C.muted, size: 36),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _C.muted, fontSize: 13, height: 1.4),
          ),
        ],
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
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _C.muted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  final double height;
  const _SkeletonBox({this.height = 120});

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: FadeTransition(
        opacity: Tween<double>(
          begin: .4,
          end: 1,
        ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// FULLSCREEN VIEWER — pinch / zoom, close button
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
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _C.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                          child: const Icon(
                            Icons.close_rounded,
                            color: _C.text,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: LayoutBuilder(
                    builder: (context, box) => InteractiveViewer(
                      minScale: .8,
                      maxScale: 5,
                      child: SizedBox(
                        width: box.maxWidth,
                        height: box.maxHeight,
                        child: child,
                      ),
                    ),
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
// AMBIENT BACKGROUND — blurred emerald/mint blobs + glass bubbles.
// Wrapped in IgnorePointer by the caller, so it never blocks taps.
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
        imageFilter: ImageFilter.blur(
          sigmaX: 45,
          sigmaY: 45,
          tileMode: TileMode.decal,
        ),
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
              Colors.white.withOpacity(.01),
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
      child: LayoutBuilder(
        builder: (context, box) {
          final double w = box.hasBoundedWidth ? box.maxWidth : 800;
          final double h = box.hasBoundedHeight ? box.maxHeight : 800;
          final double base = math.max(w, h);
          final double small = math.min(w, h);

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              _blob(
                left: -w * .18,
                top: -h * .12,
                size: base * .70,
                color: _C.accent,
                opacity: .16,
              ),
              _blob(
                right: -w * .22,
                top: h * .28,
                size: base * .60,
                color: _C.mint,
                opacity: .12,
              ),
              _blob(
                left: w * .08,
                bottom: -h * .22,
                size: base * .75,
                color: _C.accent,
                opacity: .12,
              ),
              _bubble(
                right: w * .10,
                top: h * .06,
                size: (small * .16).clamp(40.0, 150.0).toDouble(),
              ),
              _bubble(
                left: w * .06,
                top: h * .42,
                size: (small * .10).clamp(28.0, 100.0).toDouble(),
              ),
              _bubble(
                right: w * .18,
                bottom: h * .10,
                size: (small * .20).clamp(50.0, 190.0).toDouble(),
              ),
            ],
          );
        },
      ),
    );
  }
}
