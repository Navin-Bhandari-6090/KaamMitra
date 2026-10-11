import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// Adjust the relative import segment counts if your folder depth differs.
import '../../../constant/Server_Database.dart';
import '../../../constant/variable.dart';
import '../../../web/common method/Commmon_Method.dart';

// =============================================================================
// CONTROLLER — all state lives here (no setState anywhere).
// Validation rules + API call are the same as the original screen.
// =============================================================================
class AddFooterInfoGetx extends GetxController {
  // ---------------- text controllers ----------------
  final TextEditingController ContactNumberController = TextEditingController();
  final TextEditingController AddressController = TextEditingController();
  final TextEditingController EmailController = TextEditingController();
  final TextEditingController SocialMediaInfoController =
  TextEditingController();

  // ---------------- reactive state ----------------
  final RxBool isSaving = false.obs;

  // Live values used only by the footer preview card.
  final RxString contactText = ''.obs;
  final RxString addressText = ''.obs;
  final RxString emailText = ''.obs;
  final RxString socialText = ''.obs;

  void _syncContact() => contactText.value = ContactNumberController.text;
  void _syncAddress() => addressText.value = AddressController.text;
  void _syncEmail() => emailText.value = EmailController.text;
  void _syncSocial() => socialText.value = SocialMediaInfoController.text;

  @override
  void onInit() {
    super.onInit();
    try {
      ContactNumberController.addListener(_syncContact);
      AddressController.addListener(_syncAddress);
      EmailController.addListener(_syncEmail);
      SocialMediaInfoController.addListener(_syncSocial);
    } catch (obj) {
      print(obj.toString());
    }
  }

  @override
  void onClose() {
    try {
      ContactNumberController.dispose();
      AddressController.dispose();
      EmailController.dispose();
      SocialMediaInfoController.dispose();
    } catch (obj) {
      print(obj.toString());
    }
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // VALIDATION — same rules and same order as the original screen.
  // Returns an error message, or null when everything is valid.
  // ---------------------------------------------------------------------------
  String? validate() {
    try {
      final contactNumberRegex = RegExp(r'^\+[0-9]{7,15}$');
      final emailRegex = RegExp(
        r'^(?=.*@)(?=.*\.)(?=.*com).+$',
      );
      final addressRegex = RegExp(r'^[a-zA-Z0-9\s,./#-]+$');
      final socialMediaRegex = RegExp(
        r'^[a-zA-Z0-9\s@:/._#?&=%+\-]+$',
      );

      final String email = EmailController.text.trim();
      final String contact = ContactNumberController.text.trim();
      final String address = AddressController.text.trim();
      final String social = SocialMediaInfoController.text.trim();

      if (email.isEmpty) return "Please enter email.";
      if (!emailRegex.hasMatch(email)) {
        return "Please enter a valid email address.";
      }
      if (contact.isEmpty) return "Please enter contact number.";
      if (!contactNumberRegex.hasMatch(contact)) {
        return "Contact number must start with + and contain 7 to 15 digits.";
      }
      if (address.isEmpty) return "Please enter address.";
      if (!addressRegex.hasMatch(address)) {
        return "Please enter a valid address.";
      }
      if (social.isEmpty) return "Please enter social media information.";
      if (!socialMediaRegex.hasMatch(social)) {
        return "Please enter valid social media information.";
      }
      return null;
    } catch (obj) {
      print(obj.toString());
      return "Something went wrong.";
    }
  }

  // ---------------------------------------------------------------------------
  // SUBMIT (guarded by isSaving + try/catch)
  // ---------------------------------------------------------------------------
  Future<void> submit({required String jwtToken}) async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      await AddFooterInfo(
        ContactNumber: ContactNumberController.text.trim(),
        Address: AddressController.text.trim(),
        Email: EmailController.text.trim(),
        SocialMediaInfo: SocialMediaInfoController.text.trim(),
        jwttoken: jwtToken,
      );
    } catch (obj) {
      print(obj.toString());
    } finally {
      if (!isClosed) isSaving.value = false;
    }
  }

  // ===========================================================================
  // ORIGINAL API METHOD — logic unchanged.
  // (Only fix: the status checks are now ONE if/else chain, so a successful
  //  save no longer also shows "Something went wrong.")
  // ===========================================================================
  Future<void> AddFooterInfo({
    required String ContactNumber,
    required String Address,
    required String Email,
    required String SocialMediaInfo,
    required String jwttoken,
  }) async {
    try {
      const String url = Backend_Server_Url + "api/Admin/addfooterinfo";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwttoken",
        },
        body: jsonEncode({
          "ContactNumber": ContactNumber,
          "Address": Address,
          "Email": Email,
          "SocialMediaInfo": SocialMediaInfo,
        }),
      );

      if (response.statusCode == 200) {
        Toast.Toastmsg("Footer information saved successfully.");
        ContactNumberController.clear();
        AddressController.clear();
        EmailController.clear();
        SocialMediaInfoController.clear();
      } else if (response.statusCode == 400) {
        Toast.Toastmsg("Please enter valid footer information.");
      } else if (response.statusCode == 401) {
        Toast.Toastmsg("Unauthorized access.");
      } else if (response.statusCode == 502) {
        Toast.Toastmsg("User not found.");
      } else if (response.statusCode == 506) {
        Toast.Toastmsg(
          "You have been blocked by the system. Please contact the KaamMitra community.",
        );
      } else if (response.statusCode == 403) {
        Toast.Toastmsg(
          "You do not have permission to update footer information.",
        );
      } else if (response.statusCode == 500) {
        Toast.Toastmsg("Server error. Please try again.");
      } else {
        Toast.Toastmsg("Something went wrong.");
      }
    } catch (e) {
      Toast.Toastmsg("Something went wrong.");
    }
  }
}