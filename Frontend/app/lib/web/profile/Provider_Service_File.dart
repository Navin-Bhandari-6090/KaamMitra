

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../constant/Server_Database.dart';
import '../../models/ProviderServiceFileModel.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/toast.dart';

class ProviderServiceFile extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  final String Service_Name;

  const ProviderServiceFile({
    super.key,
    required this.User_Email,
    required this.User_JwtToken,
    required this.User_Role,
    required this.Service_Name,
  });

  @override
  State<ProviderServiceFile> createState() =>
      _ProviderServiceFileState();
}

class _ProviderServiceFileState
    extends State<ProviderServiceFile> {

  // ============================================================
  // PDF CONTROLLER
  // ============================================================

  final PdfViewerController _pdfViewerController =
  PdfViewerController();

  // ============================================================
  // FUTURE
  // ============================================================

  late Future<int> _serviceFileFuture;

  // ============================================================
  // SERVICE FILE LIST
  // ============================================================

  List<ProviderServiceFileModel>
  ProviderRegisterFileList = [];

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    print('');
    print('================================================');
    print('PROVIDER SERVICE FILE SCREEN INITIALIZED');
    print('================================================');
    print('Email       : ${widget.User_Email}');
    print('Service     : ${widget.Service_Name}');
    print('Role        : ${widget.User_Role}');
    print('JWT length  : ${widget.User_JwtToken.length}');
    print('================================================');

    // JWT verification
    JwtVerify(
      Jwt_Token: widget.User_JwtToken,
    );

    // API request
    _serviceFileFuture =
        GetProviderRegisterService(
          Email: widget.User_Email,
          jwttoken: widget.User_JwtToken,
        );
  }

  // ============================================================
  // JWT VERIFICATION
  // ============================================================

  Future<void> JwtVerify({
    required String Jwt_Token,
  }) async {

    print('');
    print('--------------------------------------------');
    print('JWT VERIFICATION START');
    print('--------------------------------------------');

    print(
      'JWT exists: '
          '${Jwt_Token.isNotEmpty ? "YES" : "NO"}',
    );

    print(
      'JWT length: ${Jwt_Token.length}',
    );

    final int Result =
    await ProviderJwtVerify(
      Jwt_Token: Jwt_Token,
    );

    print(
      'JWT verification result: $Result',
    );

    if (Result == 1) {

      print(
        'CHECKPOINT: JWT VALID',
      );

      return;
    }

    print(
      'CHECKPOINT: JWT INVALID',
    );

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ErrorPage(),
      ),
    );

    Toastget().Toastmsg(
      "Session End. Relogin please.",
    );
  }

  // ============================================================
  // GET SERVICE FILE
  // ============================================================

  Future<int> GetProviderRegisterService({
    required String Email,
    required String jwttoken,
  }) async {

    try {

      print('');
      print('================================================');
      print('GET SERVICE FILE METHOD CALLED');
      print('================================================');

      print('Email   : $Email');
      print('Service : ${widget.Service_Name}');

      const String url =
          Backend_Server_Url +
              "api/Profile/getservicefileinfo";

      print(
        'API URL: $url',
      );

      final Map<String, dynamic> UserDetails = {
        "Email": Email,
        "ServiceName": widget.Service_Name,
      };

      print(
        'Request body: ${jsonEncode(UserDetails)}',
      );

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwttoken",
        },
        body: jsonEncode(UserDetails),
      );

      print(
        'Status code: ${response.statusCode}',
      );

      if (response.statusCode != 200) {

        print(
          'API FAILED',
        );

        print(
          'Response: ${response.body}',
        );

        ProviderRegisterFileList.clear();

        return 0;
      }

      print(
        'API RESPONSE SUCCESS',
      );

      print(
        'Response length: ${response.body.length}',
      );

      // ========================================================
      // JSON DECODE
      // ========================================================

      final dynamic responseData =
      jsonDecode(response.body);

      if (responseData is! List) {

        print(
          'ERROR: Response is not a List.',
        );

        return 0;
      }

      print(
        'Number of files: ${responseData.length}',
      );

      // ========================================================
      // MODEL CONVERSION
      // ========================================================

      ProviderRegisterFileList.clear();

      ProviderRegisterFileList.addAll(
        responseData
            .map(
              (data) =>
              ProviderServiceFileModel.fromJson(
                data,
              ),
        )
            .toList(),
      );

      // ========================================================
      // VALIDATION
      // ========================================================

      for (
      int i = 0;
      i < ProviderRegisterFileList.length;
      i++
      ) {

        final service =
        ProviderRegisterFileList[i];

        print('');
        print(
          '--------------- FILE $i ---------------',
        );

        print(
          'Service Name: '
              '${service.serviceName}',
        );

        print(
          'Service ID: '
              '${service.providerServiceId}',
        );

        print(
          'Document exists: '
              '${service.serviceDocument != null}',
        );

        print(
          'Document length: '
              '${service.serviceDocument?.length ?? 0}',
        );
      }

      print('');
      print(
        'SERVICE FILE API PROCESS SUCCESS',
      );
      print('================================================');

      return 1;

    } catch (e, stackTrace) {

      print('');
      print('================================================');
      print('SERVICE FILE API EXCEPTION');
      print('================================================');

      print(
        'Error: $e',
      );

      print(
        'StackTrace: $stackTrace',
      );

      print('================================================');

      ProviderRegisterFileList.clear();

      return 0;
    }
  }

  // ============================================================
  // PDF DECODER
  // ============================================================

  Uint8List? DecodePdf({
    required String? base64Document,
  }) {

    print('');
    print('================================================');
    print('PDF CHECKPOINT 01');
    print('PDF DECODING START');
    print('================================================');

    // ------------------------------------------------------------
    // NULL CHECK
    // ------------------------------------------------------------

    if (base64Document == null) {

      print(
        'FAILED: PDF document is NULL',
      );

      return null;
    }

    // ------------------------------------------------------------
    // EMPTY CHECK
    // ------------------------------------------------------------

    String cleanedBase64 =
    base64Document.trim();

    if (cleanedBase64.isEmpty) {

      print(
        'FAILED: PDF document is EMPTY',
      );

      return null;
    }

    print(
      'Original Base64 length: '
          '${cleanedBase64.length}',
    );

    // ------------------------------------------------------------
    // DATA URI CHECK
    // ------------------------------------------------------------

    print('');
    print('PDF CHECKPOINT 02');
    print('Checking Data URI...');

    if (cleanedBase64.contains(',')) {

      final int commaIndex =
      cleanedBase64.indexOf(',');

      final String prefix =
      cleanedBase64.substring(
        0,
        commaIndex,
      );

      print(
        'Prefix found: $prefix',
      );

      if (
      prefix
          .toLowerCase()
          .contains('base64')
      ) {

        cleanedBase64 =
            cleanedBase64.substring(
              commaIndex + 1,
            );

        print(
          'Data URI prefix removed.',
        );
      }

    } else {

      print(
        'No Data URI prefix.',
      );
    }

    cleanedBase64 =
        cleanedBase64.trim();

    print(
      'Clean Base64 length: '
          '${cleanedBase64.length}',
    );

    // ------------------------------------------------------------
    // BASE64 PREFIX
    // ------------------------------------------------------------

    print('');
    print('PDF CHECKPOINT 03');

    if (cleanedBase64.startsWith('JVBERi')) {

      print(
        'Base64 starts with JVBERi.',
      );

      print(
        'Looks like PDF Base64.',
      );

    } else {

      print(
        'WARNING: Base64 does not start with JVBERi.',
      );
    }

    // ------------------------------------------------------------
    // BASE64 DECODE
    // ------------------------------------------------------------

    print('');
    print('PDF CHECKPOINT 04');
    print('Decoding Base64...');

    late Uint8List pdfBytes;

    try {

      pdfBytes =
          base64Decode(
            cleanedBase64,
          );

      print(
        'Base64 decoding SUCCESS',
      );

      print(
        'Decoded PDF bytes: '
            '${pdfBytes.length}',
      );

    } catch (e) {

      print(
        'FAILED: Base64 decoding failed.',
      );

      print(
        'Error: $e',
      );

      return null;
    }

    // ------------------------------------------------------------
    // BYTE LENGTH
    // ------------------------------------------------------------

    print('');
    print('PDF CHECKPOINT 05');

    if (pdfBytes.length < 5) {

      print(
        'FAILED: PDF bytes too small.',
      );

      return null;
    }

    print(
      'PDF byte length validation SUCCESS',
    );

    // ------------------------------------------------------------
    // HEADER
    // ------------------------------------------------------------

    print('');
    print('PDF CHECKPOINT 06');

    final String header =
    String.fromCharCodes(
      pdfBytes.take(5),
    );

    print(
      'PDF header: $header',
    );

    if (header != '%PDF-') {

      print(
        'FAILED: Invalid PDF header.',
      );

      return null;
    }

    print(
      'PDF header validation SUCCESS',
    );

    // ------------------------------------------------------------
    // EOF
    // ------------------------------------------------------------

    print('');
    print('PDF CHECKPOINT 07');

    final int checkLength =
    pdfBytes.length < 500
        ? pdfBytes.length
        : 500;

    final List<int> lastBytes =
    pdfBytes.sublist(
      pdfBytes.length - checkLength,
    );

    final String lastPart =
    String.fromCharCodes(
      lastBytes,
    );

    if (lastPart.contains('%%EOF')) {

      print(
        '%%EOF FOUND',
      );

    } else {

      print(
        'WARNING: %%EOF NOT FOUND',
      );
    }

    print('');
    print(
      'PDF VALIDATION SUCCESS',
    );

    print(
      'PDF bytes ready for Syncfusion: '
          '${pdfBytes.length}',
    );

    print('================================================');

    return pdfBytes;
  }

  // ============================================================
  // ZOOM IN
  // ============================================================

  void ZoomIn() {

    final double currentZoom =
        _pdfViewerController.zoomLevel;

    double newZoom =
        currentZoom + 0.25;

    if (newZoom > 5.0) {
      newZoom = 5.0;
    }

    _pdfViewerController.zoomLevel =
        newZoom;

    print(
      'Zoom In: $newZoom',
    );
  }

  // ============================================================
  // ZOOM OUT
  // ============================================================

  void ZoomOut() {

    final double currentZoom =
        _pdfViewerController.zoomLevel;

    double newZoom =
        currentZoom - 0.25;

    if (newZoom < 0.5) {
      newZoom = 0.5;
    }

    _pdfViewerController.zoomLevel =
        newZoom;

    print(
      'Zoom Out: $newZoom',
    );
  }

  // ============================================================
  // RESET ZOOM
  // ============================================================

  void ResetZoom() {

    _pdfViewerController.zoomLevel =
    1.0;

    print(
      'Zoom Reset',
    );
  }

  // ============================================================
  // PDF VIEWER
  // ============================================================

  Widget BuildPdfViewer(
      ProviderServiceFileModel service,
      double width,
      double height,
      ) {

    final Uint8List? pdfBytes =
    DecodePdf(
      base64Document:
      service.serviceDocument,
    );

    if (pdfBytes == null) {

      return Container(

        width: width,
        height: height,

        alignment:
        Alignment.center,

        decoration:
        BoxDecoration(
          border:
          Border.all(
            color: Colors.red,
          ),

          borderRadius:
          BorderRadius.circular(12),
        ),

        child: const Column(

          mainAxisSize:
          MainAxisSize.min,

          children: [

            Icon(
              Icons.picture_as_pdf,
              size: 60,
              color: Colors.red,
            ),

            SizedBox(
              height: 15,
            ),

            Text(
              'Unable to open PDF',
              style:
              TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(

      width: width,
      height: height,

      decoration:
      BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(12),

        boxShadow: [
          BoxShadow(
            blurRadius: 15,

            spreadRadius: 1,

            offset:
            const Offset(
              0,
              5,
            ),

            color:
            Colors.black
                .withOpacity(
              0.15,
            ),
          ),
        ],
      ),

      clipBehavior:
      Clip.antiAlias,

      child:
      SfPdfViewer.memory(

        pdfBytes,

        controller:
        _pdfViewerController,

        // --------------------------------------------------------
        // ZOOM
        // --------------------------------------------------------

        enableDoubleTapZooming:
        true,

        // --------------------------------------------------------
        // TEXT SELECTION
        // --------------------------------------------------------

        enableTextSelection:
        true,

        // --------------------------------------------------------
        // PAGE LAYOUT
        // --------------------------------------------------------

        pageLayoutMode:
        PdfPageLayoutMode.continuous,

        // --------------------------------------------------------
        // SCROLL
        // --------------------------------------------------------

        scrollDirection:
        PdfScrollDirection.vertical,

        canShowScrollHead:
        true,

        canShowScrollStatus:
        true,

        // --------------------------------------------------------
        // PDF LOADED
        // --------------------------------------------------------

        onDocumentLoaded:
            (
            PdfDocumentLoadedDetails details,
            ) {

          print('');
          print(
            '================================================',
          );

          print(
            'PDF CHECKPOINT 08',
          );

          print(
            'PDF LOADED SUCCESSFULLY',
          );

          print(
            'Service: '
                '${service.serviceName}',
          );

          print(
            'Service ID: '
                '${service.providerServiceId}',
          );

          print(
            'Pages: '
                '${details.document.pages.count}',
          );

          print(
            '================================================',
          );
        },

        // --------------------------------------------------------
        // PDF FAILED
        // --------------------------------------------------------

        onDocumentLoadFailed:
            (
            PdfDocumentLoadFailedDetails details,
            ) {

          print('');
          print(
            '================================================',
          );

          print(
            'PDF CHECKPOINT 09 FAILED',
          );

          print(
            'Error: ${details.error}',
          );

          print(
            'Description: '
                '${details.description}',
          );

          print(
            'PDF bytes: ${pdfBytes.length}',
          );

          print(
            '================================================',
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {

    return Scaffold(

      appBar: AppBar(

        title: Text(
          widget.Service_Name,
        ),

        centerTitle: true,
      ),

      body: SafeArea(

        child:
        FutureBuilder<int>(

          future:
          _serviceFileFuture,

          builder:
              (
              BuildContext context,
              AsyncSnapshot<int> snapshot,
              ) {

            // ==================================================
            // LOADING
            // ==================================================

            if (
            snapshot.connectionState ==
                ConnectionState.waiting
            ) {

              return const Center(

                child:
                CircularProgressIndicator(),
              );
            }

            // ==================================================
            // ERROR
            // ==================================================

            if (snapshot.hasError) {

              return Center(

                child:
                Column(

                  mainAxisSize:
                  MainAxisSize.min,

                  children: [

                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    const Text(
                      'Something went wrong.',
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    ElevatedButton(

                      onPressed: () {

                        setState(() {

                          _serviceFileFuture =
                              GetProviderRegisterService(
                                Email:
                                widget.User_Email,

                                jwttoken:
                                widget.User_JwtToken,
                              );
                        });
                      },

                      child:
                      const Text(
                        'Retry',
                      ),
                    ),
                  ],
                ),
              );
            }

            // ==================================================
            // API FAILED
            // ==================================================

            if (snapshot.data != 1) {

              return Center(

                child:
                Column(

                  mainAxisSize:
                  MainAxisSize.min,

                  children: [

                    const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 65,
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    const Text(
                      'No service file found.',
                      style:
                      TextStyle(
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    ElevatedButton.icon(

                      onPressed: () {

                        setState(() {

                          _serviceFileFuture =
                              GetProviderRegisterService(
                                Email:
                                widget.User_Email,

                                jwttoken:
                                widget.User_JwtToken,
                              );
                        });
                      },

                      icon:
                      const Icon(
                        Icons.refresh,
                      ),

                      label:
                      const Text(
                        'Retry',
                      ),
                    ),
                  ],
                ),
              );
            }

            // ==================================================
            // EMPTY
            // ==================================================

            if (
            ProviderRegisterFileList
                .isEmpty) {

              return const Center(

                child:
                Text(
                  'No service file available.',
                  style:
                  TextStyle(
                    fontSize: 18,
                  ),
                ),
              );
            }

            // ==================================================
            // RESPONSIVE LAYOUT
            // ==================================================

            return LayoutBuilder(

              builder:
                  (
                  BuildContext context,
                  BoxConstraints constraints,
                  ) {

                final double screenWidth =
                    constraints.maxWidth;

                final double screenHeight =
                    constraints.maxHeight;

                // ------------------------------------------------
                // 80% WIDTH
                // ------------------------------------------------

                double pdfWidth =
                    screenWidth * 0.80;

                // ------------------------------------------------
                // 80% HEIGHT
                // ------------------------------------------------

                double pdfHeight =
                    screenHeight * 0.80;

                // ------------------------------------------------
                // SAFETY FOR VERY SMALL DEVICES
                // ------------------------------------------------

                if (pdfWidth < 280) {
                  pdfWidth = screenWidth - 20;
                }

                if (pdfHeight < 300) {
                  pdfHeight =
                      screenHeight - 40;
                }

                // ------------------------------------------------
                // MAX WIDTH FOR LARGE DESKTOP
                // ------------------------------------------------

                if (pdfWidth > 1400) {
                  pdfWidth = 1400;
                }

                return Center(

                  child:
                  SingleChildScrollView(

                    physics:
                    const BouncingScrollPhysics(),

                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 10,
                    ),

                    child: Column(

                      mainAxisSize:
                      MainAxisSize.min,

                      children: [

                        // ========================================
                        // SERVICE INFORMATION
                        // ========================================

                        Container(

                          width: pdfWidth,

                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),

                          decoration:
                          BoxDecoration(
                            color:
                            Theme.of(context)
                                .colorScheme
                                .surface,

                            borderRadius:
                            const BorderRadius.only(
                              topLeft:
                              Radius.circular(12),
                              topRight:
                              Radius.circular(12),
                            ),

                            boxShadow: [
                              BoxShadow(
                                blurRadius: 10,

                                offset:
                                const Offset(
                                  0,
                                  3,
                                ),

                                color:
                                Colors.black
                                    .withOpacity(
                                  0.08,
                                ),
                              ),
                            ],
                          ),

                          child:
                          Row(

                            children: [

                              // ----------------------------------
                              // SERVICE INFORMATION
                              // ----------------------------------

                              Expanded(

                                child:
                                Column(

                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                                  children: [

                                    Text(
                                      serviceName(
                                        ProviderRegisterFileList[
                                        0],
                                      ),

                                      style:
                                      const TextStyle(
                                        fontSize: 20,
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 5,
                                    ),

                                    Text(
                                      'Service ID: '
                                          '${ProviderRegisterFileList[0].providerServiceId ?? "-"}',

                                      style:
                                      TextStyle(
                                        fontSize: 14,
                                        color:
                                        Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ----------------------------------
                              // ZOOM CONTROLS
                              // ----------------------------------

                              Wrap(

                                children: [

                                  IconButton(
                                    tooltip:
                                    'Zoom Out',

                                    onPressed:
                                    ZoomOut,

                                    icon:
                                    const Icon(
                                      Icons.remove,
                                    ),
                                  ),

                                  IconButton(
                                    tooltip:
                                    'Reset Zoom',

                                    onPressed:
                                    ResetZoom,

                                    icon:
                                    const Icon(
                                      Icons.refresh,
                                    ),
                                  ),

                                  IconButton(
                                    tooltip:
                                    'Zoom In',

                                    onPressed:
                                    ZoomIn,

                                    icon:
                                    const Icon(
                                      Icons.add,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ========================================
                        // PDF
                        // ========================================

                        BuildPdfViewer(

                          ProviderRegisterFileList[
                          0],

                          pdfWidth,

                          pdfHeight,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // SERVICE NAME HELPER
  // ============================================================

  String serviceName(
      ProviderServiceFileModel service,
      ) {

    if (
    service.serviceName != null &&
        service.serviceName!
            .trim()
            .isNotEmpty) {

      return service.serviceName!;
    }

    return widget.Service_Name;
  }
}