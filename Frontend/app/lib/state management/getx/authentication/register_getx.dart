import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../constant/Server_Database.dart';
import '../../../constant/variable.dart';
import '../../../web/common method/forget_pswd_credentials_download.dart';
import '../../../web/common widget/location/get_location_getx.dart';



/// Focus node + reactive "is focused" flag for one input field.
/// Lets stateless widgets show focus styling without setState.
class FieldFocus {
  final FocusNode node = FocusNode();
  final RxBool focused = false.obs;

  FieldFocus() {
    node.addListener(() => focused.value = node.hasFocus);
  }

  void dispose() => node.dispose();
}

/// GetX controller for the Register screen.
/// Holds ALL state + the signup API call. No setState anywhere.
class RegisterController extends GetxController
    with GetTickerProviderStateMixin {
  RegisterController({required this.userJwtToken});

  final String userJwtToken;

  // ---- animations ---------------------------------------------------
  late final AnimationController entrance;
  late final AnimationController wave;

  // ---- text controllers ---------------------------------------------
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final whatsappCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final retypeCtrl = TextEditingController();
  final latitudeCtrl = TextEditingController();
  final longitudeCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  // ---- focus per field ----------------------------------------------
  final firstF = FieldFocus();
  final lastF = FieldFocus();
  final emailF = FieldFocus();
  final addressF = FieldFocus();
  final phoneF = FieldFocus();
  final whatsappF = FieldFocus();
  final latF = FieldFocus();
  final lngF = FieldFocus();
  final passF = FieldFocus();
  final retypeF = FieldFocus();
  final roleFocused = false.obs;

  // ---- reactive UI state --------------------------------------------
  final role = 'User'.obs; // replaces CommonVariableBloc role
  final obscurePass = true.obs; // replaces bloc obscure values
  final obscureRetype = true.obs;
  final buttonPressed = false.obs;
  final isLoading = false.obs;

  final _toast = LongToast;

  // ---- location (existing GetX service) -----------------------------
  late final GetLocationGetx locationCont;
  late final String _locTag;

  @override
  void onInit() {
    super.onInit();
    _locTag = 'register_${identityHashCode(this)}';
    locationCont = Get.put(GetLocationGetx(), tag: _locTag);

    entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
    wave = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void onClose() {
    entrance.dispose();
    wave.dispose();
    for (final c in [
      firstNameCtrl,
      lastNameCtrl,
      emailCtrl,
      phoneCtrl,
      whatsappCtrl,
      passCtrl,
      retypeCtrl,
      latitudeCtrl,
      longitudeCtrl,
      addressCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      firstF, lastF, emailF, addressF, phoneF,
      whatsappF, latF, lngF, passF, retypeF,
    ]) {
      f.dispose();
    }
    Get.delete<GetLocationGetx>(tag: _locTag);
    super.onClose();
  }

  Animation<double> stagger(double start, double end) {
    return CurvedAnimation(
      parent: entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  void selectRole(String? value) {
    if (value != null) role.value = value;
  }

  void toggleObscurePass() => obscurePass.value = !obscurePass.value;
  void toggleObscureRetype() => obscureRetype.value = !obscureRetype.value;

  // ---- use my current location --------------------------------------
  Future<void> handleUseCurrentLocation() async {
    try {
      final bool success = await locationCont.fetchCurrentLocation();
      if (!success || isClosed) return;

      final double? lat = locationCont.latitude.value;
      final double? lng = locationCont.longitude.value;
      if (lat == null || lng == null) return;

      latitudeCtrl.text = lat.toString();
      longitudeCtrl.text = lng.toString();
    } catch (e) {
      print("Unexpected error in handleUseCurrentLocation: $e");
    }
  }

  // ---- create account flow (called AFTER the confirm dialog) --------
  Future<void> createAccountFlow(BuildContext context) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final result = await handleCreateAccount(context);

      print("Handle create account methode executed.Result = $result");

      if (result == 1)
      {
        await downloadCredentialsPdf(
          email: emailCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          whatsapp: whatsappCtrl.text.trim(),
          password: passCtrl.text.trim(),
        );
      }

      firstNameCtrl.clear();
      lastNameCtrl.clear();
      emailCtrl.clear();
      phoneCtrl.clear();
      whatsappCtrl.clear();
      passCtrl.clear();
      retypeCtrl.clear();
      latitudeCtrl.clear();
      longitudeCtrl.clear();
      addressCtrl.clear();

    } catch (e) {
      print("Exception in create account onTap: $e");
      Toast.Toastmsg("Something went wrong. Try again.");
    } finally {
      isLoading.value = false;
    }
  }

  // ---- signup api (logic unchanged) ---------------------------------
  Future<int> handleCreateAccount(BuildContext context) async {
    try {
      final firstName = firstNameCtrl.text.trim();
      final lastName = lastNameCtrl.text.trim();
      final email = emailCtrl.text.trim();
      final phone = phoneCtrl.text.trim();
      final whatsapp = whatsappCtrl.text.trim();
      final password = passCtrl.text.trim();
      final retype = retypeCtrl.text.trim();
      final latitude = latitudeCtrl.text.trim();
      final longitude = longitudeCtrl.text.trim();
      final address = addressCtrl.text.trim();
      final roleValue = role.value;

      if (firstName.isEmpty) {
        _toast.Toastmsg('First name is required');
        print('First name is required');
        return 1;
      }
      if (lastName.isEmpty) {
        _toast.Toastmsg('Last name is required');
        print('Last name is required');
        return 2;
      }
      if (email.isEmpty) {
        _toast.Toastmsg('Email is required');
        print('Email is required');
        return 3;
      }
      if (address.isEmpty) {
        _toast.Toastmsg('Address is required');
        print('Address is required');
        return 3;
      }
      if (!email.contains('@') || !email.contains('.com')) {
        _toast.Toastmsg('Enter a valid email address');
        print('Enter a valid email address');
        return 4;
      }
      if (phone.isEmpty) {
        _toast.Toastmsg('Phone number is required');
        print('Phone number is required');
        return 5;
      }
      if (!phone.startsWith('+')) {
        _toast.Toastmsg('Phone number must start with +');
        print('Phone number must start with +');
        return 6;
      }
      if (whatsapp.isEmpty) {
        _toast.Toastmsg('WhatsApp number is required');
        print('WhatsApp number is required');
        return 7;
      }
      if (!whatsapp.startsWith('+')) {
        _toast.Toastmsg('WhatsApp number must start with +');
        print('WhatsApp number must start with +');
        return 8;
      }
      if (password.isEmpty) {
        _toast.Toastmsg('Password is required');
        print('Password is required');
        return 9;
      }
      if (retype.isEmpty) {
        _toast.Toastmsg('Please retype your password');
        print('Please retype your password');
        return 10;
      }
      if (roleValue.isEmpty) {
        _toast.Toastmsg('Role is required.');
        print('Role is required.');
        return 10;
      }
      if (latitude.isEmpty) {
        _toast.Toastmsg('Latitude is required.');
        print('Latitude is required.');
        return 10;
      }
      if (longitude.isEmpty) {
        _toast.Toastmsg('Longitude is required.');
        print('Longitude is required.');
        return 10;
      }
      if (password != retype) {
        _toast.Toastmsg('Passwords do not match');
        print('Passwords do not match');
        return 11;
      }

      final latitudeValue = double.tryParse(latitude);
      final longitudeValue = double.tryParse(longitude);

      if (latitudeValue == null) {
        _toast.Toastmsg('Invalid latitude');
        print('Invalid latitude');
        return 10;
      }
      if (longitudeValue == null) {
        _toast.Toastmsg('Invalid longitude');
        print('Invalid longitude');
        return 10;
      }

      const String url = Backend_Server_Url + "api/Authentication/signin";

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $userJwtToken';

      request.fields['FirstName'] = firstName;
      request.fields['LastName'] = lastName;
      request.fields['Email'] = email;
      request.fields['PhoneNumber'] = phone;
      request.fields['WhatsappPhoneNumber'] = whatsapp;
      request.fields['Address'] = address;
      request.fields['Password'] = password;
      request.fields['Latitude'] = latitudeValue.toString();
      request.fields['Longitude'] = longitudeValue.toString();
      request.fields['Role'] = roleValue;


      final response = await request.send();


      final responseBody = await response.stream.bytesToString();


      if (response.statusCode == 200) {
        _toast.Toastmsg('Account created successfully');
        print('Account created successfully');

        return 1;
      } else if (response.statusCode == 400) {
        _toast.Toastmsg('Invalid role.');
        print('Account created fail. Invalid role.');
        return 2;
      } else if (response.statusCode == 525) {
        _toast.Toastmsg('You have been blocked by the system.');
        print('You have been blocked by the system.');
        return 2;
      } else if (response.statusCode == 501) {
        _toast.Toastmsg( 'Provided data are not in correct format.');
        print('Account created fail. Provided data are not in correct format.');
        return 4;
      } else if (response.statusCode == 502) {
        _toast.Toastmsg(
            'Email already exists.');
        print('Account created fail. Email already exists.');
        return 3;
      } else if (response.statusCode == 500) {
        _toast.Toastmsg('Something went wrong. Please try again.');
        print('Account created fail. Exception caught in backend.');
        return 5;
      } else {
        print('Unexpected status code = ${response.statusCode}');
        _toast.Toastmsg(
            'Account created fail. Status code: ${response.statusCode}');
        return 2;
      }
    } catch (E) {

      _toast.Toastmsg('Account created fail. Please try again. Server error.');
      print('Account created fail. Please try again. Server error.');
      return 0;
    }
  }
}