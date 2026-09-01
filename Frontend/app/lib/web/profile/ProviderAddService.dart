import 'dart:convert';

import 'package:app/state%20management/bloc/common%20state/common_variable_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';
import '../../constant/Server_Database.dart';
import '../../constant/Style.dart';
import '../../models/RegisterServiceInfo.dart';
import '../authentication/Error_page.dart';
import '../authentication/Login.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/single_file_pick_getx_cont.dart';
import '../common widget/toast.dart';

class ProviderAddService extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;

  const ProviderAddService(
      {super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});

  @override
  State<ProviderAddService> createState() => _ProviderAddServiceState();
}

class _ProviderAddServiceState extends State<ProviderAddService> {
  final Toast = Toastget();
  final change_file_cont_getx = Get.put(FilePickerController());

  @override
  void initState() {
    super.initState();
    Provider_Jwt_Verify(Jwt_Token: widget.User_JwtToken);
  }

  Future<void> Provider_Jwt_Verify({required String Jwt_Token}) async
  {
    int Result = await ProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result == 1) {
      return;
    } else {
      await Clear_User_Data();
      await Random_token_Clear();
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => ErrorPage()
          )
      );
      Toastget().Toastmsg("Session End.Relogin please.");
      return;
    }
  }

  Future<int> AddService({required FileBytes}) async {
    try {
      final blocState = context.read<CommonVariableBloc>().state;
      final ServiceName = blocState.ProviderServiceName;
      final String base64File = base64Encode(FileBytes as List<int>);

      if (base64File.isEmptyOrNull) {
        Toast.Toastmsg('File data is required');
        print('File data  is required');
        return 1;
      }
      if (ServiceName.isEmptyOrNull) {
        Toast.Toastmsg('ServiceName is required');
        print('ServiceName is required');
        return 2;
      }

      print(ServiceName);

      // All fields valid
      final Map<String, dynamic> ServiceData = {
        "ServiceName": ServiceName,
        "ServiceDocument":base64File,
        "Email":widget.User_Email
      };

      const String url = Backend_Server_Url + "api/Profile/addservice";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.User_JwtToken}'
        },
        body: json.encode(ServiceData),
      );

      if (response.statusCode == 200) {
        Toast.Toastmsg('Add service success.');
        print('Add service success.');
        return 1;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg('Add service fail.Data are not in correct format.');
        print('Add service fail.Data are not in correct format.');
        return 3;
      }
      else {
        print("else status code = ${response.statusCode}");
        Toast.Toastmsg(
            'Add service fail.'
        );
        print('Add service fail.');
        return 2;
      }
    } catch (E) {
      Toast.Toastmsg('Add service fail.');
      print('Add service fail.');
      return 0;
    }
  }



  List<RegisterServiceInfo> RegisterServiceInfoModelList = [];

  Future<void> GetRegisterServiceInfo(
      {required String Email, required String jwttoken}) async {
    try {
      print("profile user info method called");
      const String url = Backend_Server_Url + "api/Profile/getserviceinfo";
      Map<String, dynamic> UserDetails = {"Email": Email};
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $jwttoken'
        },
        body: json.encode(UserDetails),
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        List<dynamic> responseData = await jsonDecode(response.body);
        RegisterServiceInfoModelList.clear();
        RegisterServiceInfoModelList.addAll(responseData.map((data) => RegisterServiceInfo.fromJson(data)).toList());
        return;
      } else {
        RegisterServiceInfoModelList.clear();
        print("Data get from service info failed.");
        return;
      }
    } catch (obj) {
      RegisterServiceInfoModelList.clear();
      print("Exception caught while fetching service data from profile screen");
      print(obj.toString());
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    var shortestval = MediaQuery
        .of(context)
        .size
        .shortestSide;
    var widthval = MediaQuery
        .of(context)
        .size
        .width;
    var heightval = MediaQuery
        .of(context)
        .size
        .height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Service'),
      ),
      body: Container(
        child: Column(
          children: [


            FutureBuilder(
              future: GetRegisterServiceInfo(
                  Email: widget.User_Email, jwttoken: widget.User_JwtToken),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(
                      color: Colors.green[700]));
                }
                else if (snapshot.hasError) {
                  return Center(child: Text('Error:No data available'));
                }
                else if (snapshot.connectionState == ConnectionState.done) {
                  if (RegisterServiceInfoModelList.isNotEmpty) {
                    return
                      BlocBuilder<CommonVariableBloc, CommonVariableState>(
                        builder: (context, state) {
                          return _GreenDropdown(
                            value: state.ProviderServiceName!,
                            items: RegisterServiceInfoModelList
                                .map((service) => service.serviceName ?? '')
                                .toList(),
                            label: 'Select your service',
                            icon: Icons.work_outline,
                            onChanged: (value) {
                              if (value != null) {
                                context.read<CommonVariableBloc>().add(
                                  SelectProviderSerrviceName(
                                    ProviderSerrviceName: value,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                  }
                  return Text('No service data available');
                }
                return Text('Error. Relogin.');
              },
            ),


            SizedBox(height: shortestval * 0.02),


            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(
                    horizontal: shortestval * 0.05,
                    vertical: shortestval * 0.03),
              ),
              onPressed: () async {
                try {
                  int Result = await change_file_cont_getx.pickFile();
                  if (Result == 1) {
                    int Result = await AddService(
                        FileBytes: change_file_cont_getx.fileBytes.value);
                    if (Result == 1) {
                      return;
                    }
                    else {
                      return;
                    }
                  }
                  else {
                    return;
                  }
                } catch (exception) {
                  return;
                }
              },
              child: Text(
                "Add service",
                style: TextStyle(
                    fontFamily: semibold,
                    color: Colors.white,
                    fontSize: shortestval * 0.04),
              ),
            ),

          ],
        ),

      ),
    );
  }
}

/// Styled dropdown matching the green field look — used for the
/// User / Provider role selector.
class _GreenDropdown extends StatefulWidget {
  const _GreenDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final String label;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  @override
  State<_GreenDropdown> createState() => _GreenDropdownState();
}

class _GreenDropdownState extends State<_GreenDropdown> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused ? AppColors.bgMid : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: DropdownButtonFormField<String>(
          value: widget.value,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
          ),
          style: const TextStyle(fontSize: 14.5, color: AppColors.textDark),
          dropdownColor: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.fieldFill,
            labelText: widget.label,
            labelStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13.5,
            ),
            prefixIcon: Icon(widget.icon, size: 19, color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
          ),
          items: widget.items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}



