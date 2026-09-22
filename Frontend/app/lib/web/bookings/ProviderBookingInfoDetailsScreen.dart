import 'dart:convert';

import 'package:app/web/common%20widget/GreenTextfield.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';

import '../../constant/Server_Database.dart';
import '../../models/BookingInfoModel.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/toast.dart';

class Providerbookinginfodetailsscreen extends StatefulWidget {
  final String Current_User_Email;
  final String Current_User_JwtToken;
  final String Current_User_Role;
  final List<BookingInfoModel> BookingInfoListInfo;

  Providerbookinginfodetailsscreen({
    super.key,
    required this.Current_User_Email,
    required this.Current_User_JwtToken,
    required this.Current_User_Role,
    required this.BookingInfoListInfo,
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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Provider_Jwt_Verify(Jwt_Token: widget.Current_User_JwtToken);
    print("Booking info list length = ${widget.BookingInfoListInfo.length}");
  }

  Future<void> Provider_Jwt_Verify({required String Jwt_Token}) async {
    try {
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

  Future<int> UpdateDate({
    required String UserEmail,
    required num BookId,
    required String StartDate,
    required String EndDate,
  }) async {
    try {
      final Map<String, dynamic> userData = {
        "UserEmail": UserEmail,
        "BookId": BookId,
        "StartDate": StartDate,
        "EndDate": EndDate,
      };
      const String url = Backend_Server_Url + "api/Booking/updatedate";
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.Current_User_JwtToken}',
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        print("Update date info success");
        Toast.Toastmsg("Update date success.");
        return 1;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg("Update date fail.Try again.Server error.");
        print("Update date fail.Try again.Server error.");
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
        Toast.Toastmsg("No booking data available of taht book id.");
        print("No booking data available of taht book id.");
        return 4;
      } else if (response.statusCode == 501) {
        Toast.Toastmsg(
          "Invalid data format.Please provide data in correct format.",
        );
        print("Invalid data format.Please provide data in correct format.");
        return 5;
      } else {
        print("Other status code.Error.");
        print("Status code = ${response.statusCode}");
        Toast.Toastmsg("Update date fail.Try again.Server error.");
        return 6;
      }
    } catch (Obj) {
      print("Exception caught while Updating date.");
      print(Obj.toString());
      Toast.Toastmsg("Update date fail.Try again.Server error.");
      return 7;
    }
  }

  DateTime? parseDateTimeWithAmPm(String dateTimeText, String amPm) {
    // Expected format: yyyy-MM-dd HH:mm
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$');

    if (!regex.hasMatch(dateTimeText)) {
      return null;
    }

    final period = amPm.trim().toLowerCase();

    if (period != 'am' && period != 'pm') {
      return null;
    }

    final parts = dateTimeText.split(' ');

    final datePart = parts[0];
    final timePart = parts[1];

    final dateParts = datePart.split('-');
    final timeParts = timePart.split(':');

    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);

    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // 12-hour clock validation
    if (hour < 1 || hour > 12) {
      return null;
    }

    if (minute < 0 || minute > 59) {
      return null;
    }

    // Convert 12-hour time to 24-hour time
    if (period == 'am') {
      if (hour == 12) {
        hour = 0;
      }
    } else {
      if (hour != 12) {
        hour += 12;
      }
    }

    try {
      final dateTime = DateTime(year, month, day, hour, minute);

      // DateTime() can normalize invalid dates.
      // Therefore check that the resulting values are exactly the same.
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

  Future<int> UpdateAdvanceAmount({
    required String UserEmail,
    required num BookId,
    required double AdvanceAmount,
  }) async {
    try {
      final Map<String, dynamic> userData = {
        "UserEmail": UserEmail,
        "BookId": BookId,
        "AdvancePaymentAmount": AdvanceAmount,
      };
      const String url = Backend_Server_Url + "api/Booking/updateadvanceamount";
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.Current_User_JwtToken}',
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        print("Update advance amount info success");
        Toast.Toastmsg("Update advance amount  success.");
        return 1;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg("Update advance amount  fail.Try again.Server error.");
        print("Update advance amount  fail.Try again.Server error.");
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
        Toast.Toastmsg("No booking advance amount  available of that book id.");
        print("No booking data available of taht book id.");
        return 4;
      } else if (response.statusCode == 501) {
        Toast.Toastmsg(
          "Invalid data format.Please provide data in correct format.",
        );
        print("Invalid data format.Please provide data in correct format.");
        return 5;
      } else {
        print("Other status code.Error.");
        print("Status code = ${response.statusCode}");
        Toast.Toastmsg("Update advance amount  fail.Try again.Server error.");
        return 6;
      }
    } catch (Obj) {
      print("Exception caught while Updating advance amount .");
      print(Obj.toString());
      Toast.Toastmsg("Update advance amount  fail.Try again.Server error.");
      return 7;
    }
  }

  Future<int> UpdateProviderApprovalStatus({
    required String UserEmail,
    required num BookId,
  }) async {
    try {
      final Map<String, dynamic> userData = {
        "UserEmail": UserEmail,
        "BookId": BookId,
      };
      const String url =
          Backend_Server_Url + "api/Booking/updateproviderapprovalstatus";
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.Current_User_JwtToken}',
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        print("Update provider approval status info success");
        Toast.Toastmsg("Update provider approval status success.");
        return 1;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg(
          "Update provider approval status  fail.Try again.Server error.",
        );
        print("Update provider approval status  fail.Try again.Server error.");
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
          "No booking provider approval status  available of that book id.",
        );
        print("No provider approval status data available of taht book id.");
        return 4;
      } else if (response.statusCode == 501) {
        Toast.Toastmsg(
          "Invalid provider approval status data format.Please provide data in correct format.",
        );
        print(
          "Invalid provider approval status data format.Please provide data in correct format.",
        );
        return 5;
      } else {
        print("Other status code.Error.");
        print("Status code = ${response.statusCode}");
        Toast.Toastmsg(
          "Update provider approval status  fail.Try again.Server error.",
        );
        return 6;
      }
    } catch (Obj) {
      print("Exception caught while Updating provider approval status .");
      print(Obj.toString());
      Toast.Toastmsg(
        "Update provider approval status  fail.Try again.Server error.",
      );
      return 7;
    }
  }

  Future<int> ProRequestTaskComplete({
    required String UserEmail,
    required num BookId,
  }) async {
    try {
      final Map<String, dynamic> userData = {
        "UserEmail": UserEmail,
        "BookId": BookId,
      };
      const String url =
          Backend_Server_Url + "api/Booking/proupdatetaskcompletestatus";
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.Current_User_JwtToken}',
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        print("Update provider task complete status info success");
        Toast.Toastmsg("Update provider task complete status success.");
        return 1;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg(
          "Update provider task complete status   fail.Try again.Server error.",
        );
        print(
          "Update provider task complete status   fail.Try again.Server error.",
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
      } else if (response.statusCode == 501) {
        Toast.Toastmsg(
          "Invalid provider task complete data format.Please provide data in correct format.",
        );
        print(
          "Invalid provider task complete data format.Please provide data in correct format.",
        );
        return 5;
      } else {
        print("Other status code.Error.");
        print("Status code = ${response.statusCode}");
        Toast.Toastmsg(
          "Update provider task complete status  fail.Try again.Server error.",
        );
        return 6;
      }
    } catch (Obj) {
      print("Exception caught while Updating provider task completestatus .");
      print(Obj.toString());
      Toast.Toastmsg(
        "Update provider task complete status  fail.Try again.Server error.",
      );
      return 7;
    }
  }


  Future<int> UpdateDescription({
    required String UserEmail,
    required num BookId,
    required String UserBookingDescription,
  }) async {
    try {
      final Map<String, dynamic> userData = {
        "UserEmail": UserEmail,
        "BookId": BookId,
        "UserBookingDescription":UserBookingDescription
      };
      const String url =
          Backend_Server_Url + "api/Booking/updateproviderdescp";
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
        print(
          "Update fail.Try again.Server error.",
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
      } else if (response.statusCode == 501) {
        Toast.Toastmsg(
          "Invalid  data format.Please provide data in correct format.",
        );
        print(
          "Invalid data format.Please provide data in correct format.",
        );
        return 5;
      } else {
        print("Other status code.Error.");
        print("Status code = ${response.statusCode}");
        Toast.Toastmsg(
          "Update  fail.Try again.Server error.",
        );
        return 6;
      }
    } catch (Obj) {
      print("Exception caught while Updating description .");
      print(Obj.toString());
      Toast.Toastmsg(
        "Update fail.Try again.Server error.",
      );
      return 7;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Provider Booking Details"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text("Expected format: yyyy-MM-dd HH:mm"),
            Text("Date and time format = 2026-06-30 01:03"),
            GreenField(
              controller: StartDateController,
              label: "Enter start date and time",
              icon: Icons.calendar_today,
            ),
            GreenField(
              controller: EndDateController,
              label: "Enter end date and time",
              icon: Icons.calendar_today,
            ),
            GreenField(
              controller: StartDateAmOrPmController,
              label: "Enter start date am or pm",
              icon: Icons.timer,
            ),
            GreenField(
              controller: EndDateAmOrPmController,
              label: "Enter end date am or pm",
              icon: Icons.timer,
            ),

            ElevatedButton(
              onPressed: () async {
                try {
                  if (StartDateController.text.trim().isEmpty ||
                      EndDateController.text.trim().isEmpty ||
                      StartDateAmOrPmController.text.trim().isEmpty ||
                      EndDateAmOrPmController.text.trim().isEmpty) {
                    Toastget().Toastmsg(
                      "All date and time fields are required.",
                    );
                    return;
                  }

                  final startDate = parseDateTimeWithAmPm(
                    StartDateController.text.trim(),
                    StartDateAmOrPmController.text.trim(),
                  );

                  final endDate = parseDateTimeWithAmPm(
                    EndDateController.text.trim(),
                    EndDateAmOrPmController.text.trim(),
                  );

                  if (startDate == null) {
                    Toastget().Toastmsg(
                      "Invalid start date/time. Use yyyy-MM-dd hh:mm and AM/PM.",
                    );
                    return;
                  }

                  if (endDate == null) {
                    Toastget().Toastmsg(
                      "Invalid end date/time. Use yyyy-MM-dd hh:mm and AM/PM.",
                    );
                    return;
                  }

                  if (endDate.isBefore(startDate)) {
                    Toastget().Toastmsg(
                      "End date/time cannot be before start date/time.",
                    );
                    return;
                  }

                  // ISO format accepted by ASP.NET Core DateTime
                  final startDateString = startDate.toIso8601String();
                  final endDateString = endDate.toIso8601String();

                  print("Start Date: $startDateString");
                  print("End Date: $endDateString");

                  num BookIdValue = widget.BookingInfoListInfo[0].bookId!;

                  final UpdateDateResult = await UpdateDate(
                    UserEmail: widget.Current_User_Email,
                    BookId: BookIdValue,
                    StartDate: startDateString,
                    EndDate: endDateString,
                  );
                  print("UpdateDateResult = ${UpdateDateResult}");
                } catch (e) {
                  print(e.toString());
                  Toastget().Toastmsg("Something went wrong.");
                }
              },
              child: const Text("Update date and time."),
            ),

            GreenField(
              controller: AdvanceAmountController,
              label: "Enter advance amount",
              icon: Icons.money,
            ),

            ElevatedButton(
              onPressed: () async {
                try {
                  if (AdvanceAmountController.text.isEmptyOrNull ||
                      double.parse(AdvanceAmountController.text.trim()) <= 0) {
                    Toast.Toastmsg("Advance amount should be greater than 0.");
                    return;
                  }

                  num BookIdValue = widget.BookingInfoListInfo[0].bookId!;

                  double? AdvanceAmountValue = double.tryParse(
                    AdvanceAmountController.text.trim(),
                  );

                  final UpdateAdvanceAmountResult = await UpdateAdvanceAmount(
                    UserEmail: widget.Current_User_Email,
                    BookId: BookIdValue,
                    AdvanceAmount: AdvanceAmountValue!,
                  );

                  print("AdvanceAmountValue = ${AdvanceAmountValue}");

                  print(
                    "Adance amount update result = ${UpdateAdvanceAmountResult}",
                  );
                } catch (e) {
                  print(e.toString());
                }
              },
              child: Text("Update advance payment amount."),
            ),

            ElevatedButton(
              onPressed: () async {
                try {
                  num BookIdValue = widget.BookingInfoListInfo[0].bookId!;
                  final ProviderApprovalResult =
                      await UpdateProviderApprovalStatus(
                        UserEmail: widget.Current_User_Email,
                        BookId: BookIdValue,
                      );

                  print(
                    "provider approval update result = ${ProviderApprovalResult}",
                  );
                } catch (e) {
                  print(e.toString());
                  return;
                }
              },
              child: Text("Update booking confirmation status."),
            ),

            ElevatedButton(
              onPressed: () async {
                try {
                  num BookIdValue = widget.BookingInfoListInfo[0].bookId!;

                  String ProviderEmail =
                      widget.BookingInfoListInfo[0].providerEmail!;

                  final RequestTaskResult = await ProRequestTaskComplete(
                    UserEmail: widget.Current_User_Email,
                    BookId: BookIdValue,
                  );

                  print(
                    "Request for task complete result = ${RequestTaskResult}",
                  );

                  final AddNotificationsResult = await AddNotifications(
                    CurrentUserEmail: widget.Current_User_Email,
                    ReceiverEmail: ProviderEmail,
                    Message:
                        "Please chnage task complete status if provider have finish your work for the booking id = ${BookIdValue}.",
                    Current_User_JwtToken: widget.Current_User_JwtToken,
                    context: context,
                  );
                  if (AddNotificationsResult == 1) {
                    final AddNewNotificationsResult = await AddNewNotifications(
                      CurrentUserEmail: widget.Current_User_Email,
                      ReceiverEmail: ProviderEmail,
                      Status: true,
                      Current_User_JwtToken: widget.Current_User_JwtToken,
                      context: context,
                    );
                    if (AddNewNotificationsResult == 1) {
                      print("Add new notification success.");
                    } else {
                      print("Add new notification failed");
                      return;
                    }
                  } else {
                    print("Add notification failed");
                    return;
                  }
                } catch (e) {
                  print(e.toString());
                  return;
                }
              },
              child: Text("Request for task complete."),
            ),

            GreenField(controller: ProviderDescriptionCont, label: "Enter your service description.", icon:Icons.description),

            ElevatedButton(
              onPressed: () async {
                try {

                  if(ProviderDescriptionCont.text.trim().isEmptyOrNull)
                  {
                    Toast.Toastmsg("Description field is required.");
                    return;
                  }
                  num BookIdValue = widget.BookingInfoListInfo[0].bookId!;
                  final UpdateDescriptionResult =
                  await UpdateDescription(
                    UserEmail: widget.Current_User_Email,
                    BookId: BookIdValue,
                    UserBookingDescription: ProviderDescriptionCont.text.trim(),
                  );

                  print(
                    "update result = ${UpdateDescriptionResult}",
                  );
                } catch (e) {
                  print(e.toString());
                  return;
                }
              },
              child: Text("Update your booking description value(provider)."),
            ),

          ],
        ),
      ),
    );
  }
}
