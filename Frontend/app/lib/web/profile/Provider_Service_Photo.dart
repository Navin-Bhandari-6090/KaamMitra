import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../constant/Server_Database.dart';
import '../../models/ServicePhotoModel.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/toast.dart';

class ProviderServicePhoto extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  final String Service_Name;
  const ProviderServicePhoto({
    super.key,
    required this.User_Email,
    required this.User_JwtToken,
    required this.User_Role, required this.Service_Name,
  });

  @override
  State<ProviderServicePhoto> createState() => _ProviderServicePhotoState();
}

class _ProviderServicePhotoState extends State<ProviderServicePhoto> {
  final Toast = Toastget();

  late Future<List<ServicePhotoModel>> _servicePhotoFuture;

  @override
  void initState() {
    super.initState();

    Provider_Jwt_Verify(Jwt_Token: widget.User_JwtToken);

    _servicePhotoFuture = GetServicePhotoInfo(
      Email: widget.User_Email,
      jwttoken: widget.User_JwtToken,
    );
  }

  Future<void> Provider_Jwt_Verify({required String Jwt_Token}) async {
    int Result = await ProviderJwtVerify(Jwt_Token: Jwt_Token);

    if (Result == 1) {
      return;
    } else {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ErrorPage()),
      );

      Toastget().Toastmsg("Session End. Relogin please.");
    }
  }

  Future<List<ServicePhotoModel>> GetServicePhotoInfo({
    required String Email,
    required String jwttoken,
  }) async {
    try {
      print("Profile service photo method called");

      const String url = Backend_Server_Url + "api/Profile/getservicephotoinfo";

      Map<String, dynamic> UserDetails = {
        "Email": Email,
        "ServiceName": widget.Service_Name
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwttoken",
        },
        body: jsonEncode(UserDetails),
      );



      if (response.statusCode == 200) {
        List<dynamic> responseData = jsonDecode(response.body);

        List<ServicePhotoModel> result = responseData
            .map((data) => ServicePhotoModel.fromJson(data))
            .toList();

        return result;
      } else {
        print("Data get from service resources failed.");

        throw Exception(
          "Failed to load service photos. "
          "Status code: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("Exception while fetching service resources data:");
      print(e);

      throw Exception("Unable to load service photos.");
    }
  }

  Widget _buildServicePhoto(ServicePhotoModel service) {
    try {
      if (service.servicePhoto == null || service.servicePhoto!.isEmpty) {
        return Container(
          height: 220,
          width: double.infinity,
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 60,
              color: Colors.grey,
            ),
          ),
        );
      }

      // Convert Base64 String -> Uint8List
      final Uint8List imageBytes = base64Decode(service.servicePhoto!);

      return

        SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 10.0,
              panEnabled: true,
              scaleEnabled: true,
              boundaryMargin: const EdgeInsets.all(300),
              child: Image.memory(
                imageBytes,
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.5,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );



    } catch (e) {
      print("Image Base64 decode error = $e");

      return Container(
        height: 220,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
        ),
      );
    }
  }

  Widget _buildServiceCard(ServicePhotoModel service) {
    return Card(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // PHOTO
            // =========================

            _buildServicePhoto(service),

            const SizedBox(height: 12),

            // =========================
            // SERVICE NAME
            // =========================
            Text(
              service.serviceName ?? "Unknown Service",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // =========================
            // SERVICE ID
            // =========================
            Row(
              children: [
                const Text(
                  "Service ID: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("${service.providerServiceId ?? 'N/A'}"),
              ],
            ),

            const SizedBox(height: 5),

            // =========================
            // RESOURCE ID
            // =========================
            Row(
              children: [
                const Text(
                  "Resource ID: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("${service.providerServiceResourcesId ?? 'N/A'}"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Provider Service Photo"),
        centerTitle: true,
      ),

      body: FutureBuilder<List<ServicePhotoModel>>(
        future: _servicePhotoFuture,

        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<ServicePhotoModel>> snapshot,
            ) {
              // =========================
              // LOADING
              // =========================

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // =========================
              // ERROR
              // =========================

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),

                        const SizedBox(height: 15),

                        const Text(
                          "Failed to load service photos.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text("${snapshot.error}", textAlign: TextAlign.center),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _servicePhotoFuture = GetServicePhotoInfo(
                                Email: widget.User_Email,
                                jwttoken: widget.User_JwtToken,
                              );
                            });
                          },
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // =========================
              // NO DATA
              // =========================

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    "No service photos found.",
                    style: TextStyle(fontSize: 18),
                  ),
                );
              }

              // =========================
              // DATA
              // =========================

              final List<ServicePhotoModel> services = snapshot.data!;

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _servicePhotoFuture = GetServicePhotoInfo(
                      Email: widget.User_Email,
                      jwttoken: widget.User_JwtToken,
                    );
                  });

                  await _servicePhotoFuture;
                },

                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),

                  padding: const EdgeInsets.only(top: 16),

                  itemCount: services.length,

                  itemBuilder: (BuildContext context, int index) {
                    final ServicePhotoModel service = services[index];

                    return _buildServiceCard(service);
                  },
                ),
              );
            },
      ),
    );
  }
}

// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// import '../../constant/Server_Database.dart';
// import '../../models/ServicePhotoModel.dart';
// import '../authentication/Error_page.dart';
// import '../common method/Commmon_Method.dart';
// import '../common widget/toast.dart';
//
// class ProviderServicePhoto extends StatefulWidget {
//   final String User_Email;
//   final String User_JwtToken;
//   final String User_Role;
//   const ProviderServicePhoto({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role});
//
//   @override
//   State<ProviderServicePhoto> createState() => _ProviderServicePhotoState();
// }
//
// class _ProviderServicePhotoState extends State<ProviderServicePhoto> {
//   final Toast = Toastget();
//
//   @override
//   void initState() {
//     super.initState();
//     Provider_Jwt_Verify(Jwt_Token:widget.User_JwtToken);
//   }
//
//   Future<void> Provider_Jwt_Verify({required String Jwt_Token})async
//   {
//     int Result=await ProviderJwtVerify(Jwt_Token: Jwt_Token);
//     if (Result==1)
//     {
//       return;
//     } else {
//       Navigator.pushReplacement(context,
//           MaterialPageRoute(builder: (context) => ErrorPage()
//           )
//       );
//       Toastget().Toastmsg("Session End.Relogin please.");
//       return;
//     }
//   }
//
//
//   List<ServicePhotoModel> ServicePhotoInfoModelList = [];
//
//   Future<void> GetServicePhotoInfo(
//       {required String Email, required String jwttoken}) async {
//     try {
//       print("profile user info method called");
//       const String url = Backend_Server_Url + "api/Profile/getservicephotoinfo";
//       Map<String, dynamic> UserDetails = {"Email": Email};
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           "Content-Type": "application/json",
//           'Authorization': 'Bearer $jwttoken'
//         },
//         body: json.encode(UserDetails),
//       );
//       print(response.statusCode);
//       if (response.statusCode == 200) {
//         List<dynamic> responseData = await jsonDecode(response.body);
//         ServicePhotoInfoModelList.clear();
//         ServicePhotoInfoModelList.addAll(responseData.map((data) => ServicePhotoModel.fromJson(data)).toList());
//         return;
//       } else {
//         ServicePhotoInfoModelList.clear();
//         print("Data get from service resouces info failed.");
//         return;
//       }
//     } catch (obj) {
//       ServicePhotoInfoModelList.clear();
//       print("Exception caught while fetching service resouces data for profile screen");
//       print(obj.toString());
//       return;
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Provider Service Photo"),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         scrollDirection: Axis.vertical,
//         physics: BouncingScrollPhysics(),
//         child: Column(
//           children:
//           [
//
//
//
//
//
//
//           ],
//         ),
//       ),
//
//     );
//   }
// }
