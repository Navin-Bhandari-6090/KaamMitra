import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../constant/Server_Database.dart';
import '../../../constant/variable.dart';
import '../../../models/NoOFResoucesPerUserModel.dart';
import '../../../web/common method/Commmon_Method.dart';
import '../../../web/common method/ui_kit.dart';


class ManageNoOfResPerUserGetx extends GetxController {
  ManageNoOfResPerUserGetx({required this.jwtToken});

  final String jwtToken;

  // Text input controllers for the add form.
  final TextEditingController serviceNameController = TextEditingController();
  final TextEditingController userNumberController = TextEditingController();
  final TextEditingController noOfResController = TextEditingController();

  final RxList<NoOfResoucesPerUserModel> resourcesList =
      <NoOfResoucesPerUserModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxnInt deletingId = RxnInt();
  final RxnString errorMessage = RxnString();

  BuildContext get _context {
    final BuildContext? ctx = Get.context;
    if (ctx == null) throw StateError('No active context');
    return ctx;
  }

  @override
  void onReady() {
    super.onReady();
    initialise();
  }

  /// Verifies the admin JWT (same call as before), then loads the list.
  Future<void> initialise() async {
    try {
      await Admin_Jwt_Verify(Jwt_Token: jwtToken, context: _context);
    } catch (e, s) {
      debugPrint('ManageNoOfResPerUser verify error: $e\n$s');
    }
    await fetchResources();
  }

  Future<void> fetchResources() async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final int result =
      await getAllResourcesNumber(context: _context, jwtToken: jwtToken);

      if (result != 1) {
        errorMessage.value = 'Could not load resource limits. Please try again.';
      }
    } catch (e, s) {
      debugPrint('ManageNoOfResPerUser fetchResources error: $e\n$s');
      errorMessage.value = 'Could not load resource limits. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void clearAddForm() {
    serviceNameController.clear();
    userNumberController.clear();
    noOfResController.clear();
  }

  bool _isEmpty(TextEditingController c) => c.text.trim().isEmpty;

  /// Checks the three text controllers before add.
  /// Returns a toast message when something is missing, or null when valid.
  String? _validateAddFields() {
    if (_isEmpty(serviceNameController)) return 'Please enter a service name.';
    if (_isEmpty(userNumberController)) return 'Please enter a user number.';
    if (_isEmpty(noOfResController)) {
      return 'Please enter the number of resources.';
    }
    return null;
  }

  /// Validates, asks for confirmation, then adds the resource limit.
  Future<void> submitAdd() async {
    try {
      if (isSubmitting.value) return;

      final String? emptyMessage = _validateAddFields();
      if (emptyMessage != null) {
        Toast.Toastmsg(emptyMessage);
        return;
      }

      final int? noOfRes = int.tryParse(noOfResController.text.trim());
      if (noOfRes == null || noOfRes <= 0) {
        Toast.Toastmsg('Resource count must be greater than zero.');
        return;
      }

      final int? userNumber = int.tryParse(userNumberController.text.trim());
      if (userNumber == null || userNumber <= 0) {
        Toast.Toastmsg('Please enter a valid user number.');
        return;
      }

      final bool confirmed = await confirmAction(
        title: 'Add resource limit?',
        message:
        'Allow user #$userNumber up to $noOfRes resources for "${serviceNameController.text.trim()}".',
        confirmText: 'Add limit',
      );
      if (!confirmed) return;

      isSubmitting.value = true;

      final int result = await addResourcesNumber(
        context: _context,
        jwtToken: jwtToken,
        NoOfRes: noOfRes,
        ServiceName: serviceNameController.text,
        UserNumber: userNumber,
      );

      if (result == 1) {
        clearAddForm();
        await fetchResources();
      }
    } catch (e, s) {
      debugPrint('ManageNoOfResPerUser submitAdd error: $e\n$s');
      showAppSnack('Error', 'Something went wrong. Please try again.',
          error: true);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Checks the ID before delete, asks for confirmation, then deletes.
  /// The ID comes from the selected card, so the check is on that value.
  Future<void> confirmAndDelete(NoOfResoucesPerUserModel item) async {
    try {
      if (deletingId.value != null) return;

      final int? id = item.resourcesNumberId?.toInt();
      if (id == null || id <= 0) {
        Toast.Toastmsg('This resource limit has no valid ID and cannot be deleted.');
        return;
      }

      final bool confirmed = await confirmAction(
        title: 'Delete resource limit?',
        message:
        'The limit #$id for "${item.serviceName ?? 'this service'}" will be permanently removed.',
        confirmText: 'Delete',
        destructive: true,
      );
      if (!confirmed) return;

      deletingId.value = id;
      await deleteResourcesNumber(
        context: _context,
        jwtToken: jwtToken,
        ResourcesNumberId: id,
      );
    } catch (e, s) {
      debugPrint('ManageNoOfResPerUser confirmAndDelete error: $e\n$s');
      showAppSnack('Error', 'Something went wrong. Please try again.',
          error: true);
    } finally {
      deletingId.value = null;
    }
  }

  /// API call moved from the screen. Endpoint and status handling are unchanged.
  Future<int> addResourcesNumber({
    required BuildContext context,
    required String jwtToken,
    required int NoOfRes,
    required String ServiceName,
    required int UserNumber,
  }) async {
    try {
      if (NoOfRes <= 0 || ServiceName.trim().isEmpty || UserNumber <= 0) {
        Toast.Toastmsg('All fields are required.');
        return 2;
      }

      final response = await http.post(
        Uri.parse('${Backend_Server_Url}api/Admin/addresourcesnumber'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'NoOfRes': NoOfRes,
          'ServiceName': ServiceName.trim(),
          'UserNumber': UserNumber,
        }),
      );

      if (response.statusCode == 200) {
        Toast.Toastmsg('Resource limit added successfully.');
        return 1;
      } else if (response.statusCode == 400) {
        Toast.Toastmsg('Invalid request. Please check the entered information.');
        return 2;
      } else if (response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 506) {
        Toast.Toastmsg('Unauthorized. Please log in again.');
        await Logout(context: context);
        return 3;
      } else if (response.statusCode == 507) {
        Toast.Toastmsg('Resource count must be greater than zero.');
        return 4;
      } else if (response.statusCode == 508) {
        Toast.Toastmsg('Service name is required.');
        return 5;
      } else if (response.statusCode == 509) {
        Toast.Toastmsg('Please provide a valid user number.');
        return 6;
      } else if (response.statusCode == 510) {
        Toast.Toastmsg('Admin account not found. Please log in again.');
        await Logout(context: context);
        return 3;
      } else if (response.statusCode == 511) {
        Toast.Toastmsg('Your admin account has been blocked.');
        await Logout(context: context);
        return 3;
      } else if (response.statusCode == 512) {
        Toast.Toastmsg('The specified user account was not found.');
        return 7;
      } else if (response.statusCode == 513) {
        Toast.Toastmsg('This user account has been blocked.');
        return 8;
      } else if (response.statusCode == 514) {
        Toast.Toastmsg('A resource limit already exists for this user and service.');
        return 9;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg('Server error. Please try again later.');
        return 10;
      } else {
        Toast.Toastmsg('Something went wrong. Please try again.');
        return 0;
      }
    } catch (e, s) {
      debugPrint('ManageNoOfResPerUser addResourcesNumber error: $e\n$s');
      try {
        Toast.Toastmsg('Unable to connect to the server. Please try again.');
      } catch (_) {}
      return 0;
    }
  }

  /// API call moved from the screen. Endpoint and status handling are unchanged.
  Future<int> deleteResourcesNumber({
    required BuildContext context,
    required String jwtToken,
    required int ResourcesNumberId,
  }) async {
    try {
      if (ResourcesNumberId <= 0) {
        Toast.Toastmsg('Please provide a valid resource ID.');
        return 2;
      }

      final response = await http.delete(
        Uri.parse('${Backend_Server_Url}api/Admin/deleteresourcesnumber'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'ResourcesNumberId': ResourcesNumberId,
        }),
      );

      if (response.statusCode == 200) {
        resourcesList.removeWhere(
              (item) => item.resourcesNumberId?.toInt() == ResourcesNumberId,
        );
        Toast.Toastmsg('Resource limit deleted successfully.');
        return 1;
      } else if (response.statusCode == 400) {
        Toast.Toastmsg('Invalid request. Please check the resource ID.');
        return 2;
      } else if (response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 506) {
        Toast.Toastmsg('Unauthorized. Please log in again.');
        await Logout(context: context);
        return 3;
      } else if (response.statusCode == 507) {
        Toast.Toastmsg('Invalid resource ID.');
        return 4;
      } else if (response.statusCode == 510) {
        Toast.Toastmsg('Admin account not found. Please log in again.');
        await Logout(context: context);
        return 3;
      } else if (response.statusCode == 511) {
        Toast.Toastmsg('Your admin account has been blocked.');
        await Logout(context: context);
        return 3;
      } else if (response.statusCode == 512) {
        Toast.Toastmsg('Resource record not found. It may already be deleted.');
        return 5;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg('Server error. Please try again later.');
        return 6;
      } else {
        Toast.Toastmsg('Something went wrong. Please try again.');
        return 0;
      }
    } catch (e, s) {
      debugPrint('ManageNoOfResPerUser deleteResourcesNumber error: $e\n$s');
      try {
        Toast.Toastmsg('Unable to connect to the server. Please try again.');
      } catch (_) {}
      return 0;
    }
  }

  /// API call moved from the screen. Endpoint and status handling are unchanged.
  Future<int> getAllResourcesNumber({
    required BuildContext context,
    required String jwtToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${Backend_Server_Url}api/Admin/getallresourcesnumber'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        if (data is! List) {
          resourcesList.clear();
          Toast.Toastmsg('Invalid resource data received from server.');
          return 0;
        }

        final List<NoOfResoucesPerUserModel> parsed = data
            .map((item) => NoOfResoucesPerUserModel.fromJson(item))
            .toList();
        resourcesList.assignAll(parsed);

        return 1;
      } else if (response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 506) {
        Toast.Toastmsg('Unauthorized. Please log in again.');
        await Logout(context: context);
        return 3;
      } else if (response.statusCode == 510) {
        Toast.Toastmsg('Admin account not found. Please log in again.');
        await Logout(context: context);
        return 3;
      } else if (response.statusCode == 511) {
        Toast.Toastmsg('Your admin account has been blocked.');
        await Logout(context: context);
        return 3;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg('Server error. Please try again later.');
        return 4;
      } else {
        Toast.Toastmsg('Something went wrong. Please try again.');
        return 0;
      }
    } catch (e, s) {
      debugPrint('ManageNoOfResPerUser getAllResourcesNumber error: $e\n$s');
      try {
        Toast.Toastmsg('Unable to connect to the server. Please try again.');
      } catch (_) {}
      return 0;
    }
  }

  @override
  void onClose() {
    serviceNameController.dispose();
    userNumberController.dispose();
    noOfResController.dispose();
    super.onClose();
  }
}