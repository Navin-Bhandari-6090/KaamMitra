import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../constant/Server_Database.dart';
import '../../models/ProviderRegisterServiceNameModel.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/toast.dart';
import 'ProviderGallery.dart';

class ProviderServiceSelect extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  const ProviderServiceSelect({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});

  @override
  State<ProviderServiceSelect> createState() => _ProviderServiceSelectState();
}

class _ProviderServiceSelectState extends State<ProviderServiceSelect> {

  @override
  void initState() {
    super.initState();
    JwtVerify(Jwt_Token:widget.User_JwtToken);
  }

  Future<void> JwtVerify({required String Jwt_Token})async
  {
    int Result=await ProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result==1)
    {
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


  List<ProviderRegisterServiceNameModel> ProviderRegisterServiceList=[];


  Future<int> GetProviderRegisterService({
    required String Email,
    required String jwttoken,
  }) async {
    try {
      print("Profile service photo method called");

      const String url = Backend_Server_Url + "api/Profile/getproviderregisterserviceinfo";

      Map<String, dynamic> UserDetails = {"Email": Email};

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwttoken",
        },
        body: jsonEncode(UserDetails),
      );
      if (response.statusCode == 200) {
        List<dynamic> responseData = await jsonDecode(response.body);
        ProviderRegisterServiceList.clear();
        ProviderRegisterServiceList.addAll(responseData.map((data) => ProviderRegisterServiceNameModel.fromJson(data)).toList());

        return 1;
      } else {
        ProviderRegisterServiceList.clear();
        print("Failed to fetch provider register service data. Status code: ${response.statusCode}");

        return 0;
      }
    } catch (e) {
      ProviderRegisterServiceList.clear();
      print("Error occurred while fetching provider register service data: $e");

      return 0;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Provider Service Select"),
        centerTitle: true,
      ),

      body: FutureBuilder<int>(
        future: GetProviderRegisterService(
          Email: widget.User_Email,
          jwttoken: widget.User_JwtToken,
        ),

        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {

          // =========================
          // LOADING
          // =========================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // =========================
          // ERROR
          // =========================

          if (snapshot.hasError)
          {

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Something went wrong.",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  ElevatedButton(
                    onPressed: () {
                      setState(() {

                      });
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }


          if (snapshot.data != 1)
          {
            return const Center(
              child: Text(
                "Failed to load services.",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            );
          }

          // =========================
          // NO SERVICES
          // =========================

          if (ProviderRegisterServiceList.isEmpty) {
            return const Center(
              child: Text(
                "No registered services found.First reguster service.",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            );
          }

          // =========================
          // SERVICES
          // =========================

          return ListView.builder(
            padding: const EdgeInsets.all(16),

            itemCount: ProviderRegisterServiceList.length,

            itemBuilder: (
                BuildContext context,
                int index,
                ) {
              final service =
              ProviderRegisterServiceList[index];

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 12,
                ),

                child: ListTile(
                  leading: const Icon(
                    Icons.miscellaneous_services,
                    size: 30,
                  ),

                  title: Text(
                    service.serviceName ?? "Unknown Service",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),

                  onTap: ()
                  {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyGalleryScreen(
                          User_Email: widget.User_Email,
                          User_JwtToken: widget.User_JwtToken,
                          User_Role: widget.User_Role,
                          Service_Name:
                          service.serviceName ?? "",
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }


}
