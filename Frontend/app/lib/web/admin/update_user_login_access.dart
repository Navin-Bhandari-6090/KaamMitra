import 'dart:convert';
import 'dart:math';


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';

import '../../constant/Server_Database.dart';
import '../../constant/variable.dart';
import '../../models/AdminUserInfosModel.dart';
import '../common method/Commmon_Method.dart';
import '../../state management/getx/admin/update_user_login_access_getx.dart';

// ============================================================
// PALETTE — Dark Forest / Emerald Glow theme
// ============================================================
class _Palette {
  static const bodyBg = Color(0xFF0F1F17);
  static const surface = Color(0xFF162E22);
  static const primaryText = Color(0xFFE6F4EA);
  static const mutedText = Color(0xFF8A9A90);
  static const headerFooter = Color(0xFF12261C);
  static const accent = Color(0xFF22C55E);
  static const accentMint = Color(0xFF34D399);
  static const borderColor = Color(0xFF234232);
}

class UpdateUserLoginAccess extends StatefulWidget {
  final String User_Role;
  final String User_JwtToken;
  final String User_Email;
  const UpdateUserLoginAccess({super.key, required this.User_Role, required this.User_JwtToken, required this.User_Email});

  @override
  State<UpdateUserLoginAccess> createState() => _UpdateUserLoginAccessState();
}

class _UpdateUserLoginAccessState extends State<UpdateUserLoginAccess>
    with TickerProviderStateMixin {
  final UserNumberTextCont=TextEditingController();

  // ---- UI-only additions: GetX controller + animations ----
  final LoginCont = Get.put(UpdateUserLoginAccessGetx());

  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final AnimationController _bubbleCtrl;

  // Cached fetch: only re-created when refreshTick changes, so window
  // resizes / keyboard changes never re-call the API.
  Future<void>? _usersFuture;
  int _lastFetchTick = -1;

  @override
  void initState()
  {
    Admin_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
    // TODO: implement initState
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));
    _entranceCtrl.forward();

    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // Live search: keep query in sync with the number field.
    UserNumberTextCont.addListener(() {
      LoginCont.searchQuery.value = UserNumberTextCont.text.trim();
    });
  }

  @override
  void dispose()
  {
    // Controllers must be disposed BEFORE super.dispose().
    _entranceCtrl.dispose();
    _bubbleCtrl.dispose();
    super.dispose();
  }

  Future<int> UpdateUserLoginAccess({
    required String User_JwtToken,
    required int UserNumber,
  }) async {
    try {
      print("========== UPDATE USER LOGIN ACCESS ==========");


      final Map<String, dynamic> data = {
        "UserNumber": UserNumber,
      };

      print("Request Data: $data");

      final response = await http.put(
        Uri.parse("${Backend_Server_Url}api/Admin/updateloginaccess"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $User_JwtToken",
        },
        body: jsonEncode(data),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("User login access updated successfully.");
        Toast.Toastmsg("User login access updated successfully.");
        return 200;
      } else if (response.statusCode == 502) {
        print("No user data available with that number.");
        print("Server Message: ${response.body}");
        Toast.Toastmsg("No user data available with that number.");
        return 502;
      } else if (response.statusCode == 500) {
        print("Data are not in correct format.");
        print("Server Message: ${response.body}");
        Toast.Toastmsg("Data are not in correct format.");
        return 500;
      } else if (response.statusCode == 501) {
        print("Backend exception.");
        print("Server Message: ${response.body}");
        Toast.Toastmsg("Something went wrong on server.");
        return 501;
      } else if (response.statusCode == 401) {
        print("Unauthorized.");
        print("Server Message: ${response.body}");
        Toast.Toastmsg("Unauthorized.");
        return 401;
      } else if (response.statusCode == 403) {
        print("Admin access required.");
        print("Server Message: ${response.body}");
        Toast.Toastmsg("Admin access required.");
        return 403;
      } else {
        print("Unexpected status code: ${response.statusCode}");
        print("Unexpected response: ${response.body}");
        Toast.Toastmsg("Failed to update user login access.");
        return response.statusCode;
      }
    } catch (obj) {
      print("========== UPDATE USER LOGIN ACCESS ERROR ==========");
      print("Exception: ${obj.toString()}");

      Toast.Toastmsg("Something went wrong.");
      return 501;
    }
  }


  List<AdminUserInfosModel> UserInfoModelList = [];

  Future<void> GetUserInfo({
    required String jwttoken,
  }) async {
    try {
      const String url = Backend_Server_Url + "api/Admin/getuserinfo";
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $jwttoken',
        },
      );
      if (response.statusCode == 200) {
        print("user info");
        UserInfoModelList.clear();
        List<dynamic> responseData = await jsonDecode(response.body);
        UserInfoModelList.clear();
        UserInfoModelList.addAll(
            responseData.map((data) => AdminUserInfosModel.fromJson(data)).toList());
        return;
        return;
      } else {
        UserInfoModelList.clear();
        print("Data insert in userinfo list failed.");
        return;
      }

    } catch (obj) {
      UserInfoModelList.clear();
      print("Exception caught while fetching user data for profile screen");
      print(obj.toString());
      return;
    }
  }

  // ============================================================
  // BUILD — visual redesign; every action body is the original logic
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final cardMaxWidth = min(size.width * 0.94, 640.0);
    final horizontalPad = size.width < 420 ? 16.0 : 24.0;
    final double listMaxHeight = (size.height * 0.55).clamp(240.0, 640.0).toDouble();

    return Scaffold(
      backgroundColor: _Palette.bodyBg,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // ---- ambient organic bubble background ----
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _bubbleCtrl,
                builder: (context, _) => CustomPaint(
                  painter: _BubblePainter(progress: _bubbleCtrl.value),
                ),
              ),
            ),
          ),

          // ---- main responsive scroll content ----
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPad,
                    vertical: orientation == Orientation.portrait ? 26 : 14,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: max(
                        0.0,
                        constraints.maxHeight -
                            (orientation == Orientation.portrait ? 52 : 28),
                      ),
                    ),
                    child: Center(
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: cardMaxWidth),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildScreenHeader(),
                                const SizedBox(height: 22),

                                _buildSectionCard(
                                  icon: Icons.people_alt_rounded,
                                  title: "Register users.",
                                  subtitle: "Type digits to filter by user number — e.g. \"2\" shows 2, 12, 23, 26, 27.",
                                  child: _buildUsersSection(listMaxHeight),
                                ),
                                const SizedBox(height: 16),

                                _buildSectionCard(
                                  icon: Icons.lock_open_rounded,
                                  title: "Update Login Access",
                                  subtitle: "Toggles access for the exact user number typed above.",
                                  child: _buildUpdateSection(),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
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

  // ---------------------------------------------------------
  // App bar — bordered, clearly visible back arrow
  // ---------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _Palette.headerFooter,
      elevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _Palette.primaryText, width: 1.4),
                  color: _Palette.surface,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: _Palette.primaryText,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
      title: const Text(
        "Update User Login Access",
        style: TextStyle(
          color: _Palette.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: 0.2,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _Palette.borderColor),
      ),
    );
  }

  Widget _buildScreenHeader() {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (context, value, child) =>
              Transform.scale(scale: 0.7 + (0.3 * value), child: child),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_Palette.accent, _Palette.accentMint],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _Palette.accent.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.manage_accounts_rounded, color: _Palette.bodyBg, size: 28),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          "Manage Login Access",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _Palette.primaryText,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Find a user by number and switch\ntheir login access on or off.",
          textAlign: TextAlign.center,
          style: TextStyle(color: _Palette.mutedText, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: _Palette.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Palette.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: LinearGradient(
                    colors: [
                      _Palette.accent.withOpacity(0.22),
                      _Palette.accentMint.withOpacity(0.16),
                    ],
                  ),
                  border: Border.all(color: _Palette.borderColor),
                ),
                child: Icon(icon, color: _Palette.accentMint, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _Palette.primaryText,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _Palette.mutedText, fontSize: 12, height: 1.3),
                    ),
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

  // ---------------------------------------------------------
  // Users section: number field (live filter) + user list.
  // The fetch is cached per refreshTick; the search filter lives
  // in its own Obx so typing never refetches.
  // ---------------------------------------------------------
  Widget _buildUsersSection(double listMaxHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextInput(
          controller: UserNumberTextCont,
          label: "Enter the user number.",
          icon: Icons.numbers,
          focusedRx: LoginCont.numberFocused,
          onFocusChange: (v) => LoginCont.numberFocused.value = v,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        Obx(() {
          // Re-fetch only when refreshTick changes (after a successful update).
          final tick = LoginCont.refreshTick.value;
          if (_usersFuture == null || _lastFetchTick != tick) {
            _lastFetchTick = tick;
            _usersFuture = GetUserInfo(jwttoken: widget.User_JwtToken);
          }

          return FutureBuilder(
            future: _usersFuture,
            builder: (context, snapshot) {
              try {
                // While refetching, keep the old list on screen (no flash).
                final bool refreshing =
                    snapshot.connectionState == ConnectionState.waiting &&
                        UserInfoModelList.isNotEmpty;

                // Loading (first load)
                if (snapshot.connectionState == ConnectionState.waiting && !refreshing) {
                  return _buildMediaFrame(
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(_Palette.accentMint),
                        ),
                      ),
                    ),
                  );
                }

                // Future error
                if (snapshot.hasError) {
                  print("FutureBuilder Error: ${snapshot.error}");

                  return _buildMediaFrame(
                    child: _buildEmptyMessage(
                      "Something went wrong while loading user information.",
                    ),
                  );
                }

                // No data returned
                if (!refreshing &&
                    !snapshot.hasData &&
                    snapshot.connectionState != ConnectionState.done) {
                  return _buildMediaFrame(
                    child: _buildEmptyMessage("No user information available."),
                  );
                }

                // List empty
                if (UserInfoModelList.isEmpty) {
                  return _buildMediaFrame(
                    child: _buildEmptyMessage("No user information found."),
                  );
                }

                // Display users — filtered reactively by user number
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (refreshing)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: _Palette.borderColor,
                          valueColor: AlwaysStoppedAnimation<Color>(_Palette.accentMint),
                        ),
                      ),
                    if (refreshing) const SizedBox(height: 10),
                    Obx(() {
                      final query = LoginCont.searchQuery.value.trim();
                      final List<AdminUserInfosModel> filtered = query.isEmpty
                          ? UserInfoModelList
                          : UserInfoModelList
                          .where((u) => (u.userNumber?.toString() ?? "").contains(query))
                          .toList();

                      if (filtered.isEmpty) {
                        return _buildMediaFrame(
                          child: _buildEmptyMessage("No user number contains \"$query\"."),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              "Showing ${filtered.length} of ${UserInfoModelList.length} users",
                              style: const TextStyle(
                                color: _Palette.mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: listMaxHeight),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                try {
                                  return _buildUserCard(filtered[index]);
                                } catch (e, stackTrace) {
                                  print("Error displaying user at index $index");
                                  print(e);
                                  print(stackTrace);

                                  return _buildMediaFrame(
                                    child: _buildEmptyMessage(
                                      "Unable to display this user's information.",
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                );
              } catch (e, stackTrace) {
                print("Unexpected FutureBuilder error");
                print(e);
                print(stackTrace);

                return _buildMediaFrame(
                  child: _buildEmptyMessage("Unable to display user information."),
                );
              }
            },
          );
        }),
      ],
    );
  }

  Widget _buildUserCard(AdminUserInfosModel user) {
    final String firstName =
    user.firstName?.trim().isNotEmpty == true
        ? user.firstName!.trim()
        : "N/A";

    final String lastName =
    user.lastName?.trim().isNotEmpty == true
        ? user.lastName!.trim()
        : "N/A";

    final String email =
    user.email?.trim().isNotEmpty == true
        ? user.email!.trim()
        : "N/A";

    final String address =
    user.address?.trim().isNotEmpty == true
        ? user.address!.trim()
        : "N/A";

    final String phoneNumber =
    user.phoneNumber?.trim().isNotEmpty == true
        ? user.phoneNumber!.trim()
        : "N/A";

    final String whatsappNumber =
    user.whatsappPhoneNumber?.trim().isNotEmpty == true
        ? user.whatsappPhoneNumber!.trim()
        : "N/A";

    final String role =
    user.role?.trim().isNotEmpty == true
        ? user.role!.trim()
        : "N/A";

    final String userNumber =
        user.userNumber?.toString() ?? "N/A";

    final String latitude =
        user.latitude?.toString() ?? "N/A";

    final String longitude =
        user.longitude?.toString() ?? "N/A";

    final bool isActive = user.loginAccess == true;
    final String loginAccess = isActive ? "Active" : "Inactive";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.headerFooter,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$firstName $lastName",
            style: const TextStyle(
              color: _Palette.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge("User #$userNumber", highlighted: true, icon: Icons.tag_rounded),
              _buildBadge(role, icon: Icons.badge_outlined),
              _buildBadge(
                "Login: $loginAccess",
                highlighted: isActive,
                icon: isActive ? Icons.check_circle_rounded : Icons.block_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow("Email", email),
          _buildInfoRow("Address", address),
          _buildInfoRow("Phone", phoneNumber),
          _buildInfoRow("WhatsApp", whatsappNumber),
          _buildInfoRow("Latitude", latitude),
          _buildInfoRow("Longitude", longitude, isLast: true),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, {bool highlighted = false, IconData? icon}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: highlighted ? _Palette.accent.withOpacity(0.16) : _Palette.surface,
        border: Border.all(
          color: highlighted ? _Palette.accentMint : _Palette.borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: highlighted ? _Palette.accentMint : _Palette.mutedText,
            ),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: highlighted ? _Palette.accentMint : _Palette.mutedText,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(color: _Palette.borderColor.withOpacity(0.6)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(color: _Palette.mutedText, fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _Palette.primaryText,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // Update section — onTap body is the original logic; on
  // success (200) the list refetches automatically.
  // ---------------------------------------------------------
  Widget _buildUpdateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          final q = LoginCont.searchQuery.value;
          final has = q.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _Palette.headerFooter,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: has ? _Palette.accentMint : _Palette.borderColor,
                width: has ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  has ? Icons.person_pin_rounded : Icons.person_search_rounded,
                  size: 19,
                  color: has ? _Palette.accentMint : _Palette.mutedText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    has ? "User number to update: $q" : "Enter a user number above first",
                    style: TextStyle(
                      color: has ? _Palette.primaryText : _Palette.mutedText,
                      fontSize: 13,
                      fontWeight: has ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 14),
        Obx(() => _buildPrimaryButton(
          label: "Update user login access.",
          icon: Icons.sync_alt_rounded,
          loading: LoginCont.isUpdating.value,
          onTap: () async {
            if (LoginCont.isUpdating.value) return;
            LoginCont.isUpdating.value = true;
            try{

              if(UserNumberTextCont.text.trim().isEmptyOrNull){
                Toast.Toastmsg("User number is required.");
                return;
              }

              int UserNumber=int.tryParse(UserNumberTextCont.text.trim())!;

              int DeleteServiceResult=await UpdateUserLoginAccess(
                  User_JwtToken:widget.User_JwtToken,
                  UserNumber:UserNumber
              );

              // Refresh the user list so the new access status shows instantly.
              if (DeleteServiceResult == 200) {
                LoginCont.refreshTick.value++;
              }

            }catch(obj){
              print(obj.toString());
              return;
            } finally {
              LoginCont.isUpdating.value = false;
            }
          },
        )),
      ],
    );
  }

  // ============================================================
  // SHARED UI HELPERS
  // ============================================================
  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required RxBool focusedRx,
    required ValueChanged<bool> onFocusChange,
    TextInputType? keyboardType,
  }) {
    return Focus(
      onFocusChange: onFocusChange,
      child: Obx(() {
        final focused = focusedRx.value;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: focused ? _Palette.accentMint : _Palette.borderColor,
              width: focused ? 1.6 : 1,
            ),
            boxShadow: focused
                ? [
              BoxShadow(
                color: _Palette.accentMint.withOpacity(0.18),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ]
                : [],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: _Palette.primaryText, fontSize: 14.5),
            cursorColor: _Palette.accentMint,
            decoration: InputDecoration(
              filled: true,
              fillColor: _Palette.headerFooter,
              labelText: label,
              labelStyle: TextStyle(
                color: focused ? _Palette.accentMint : _Palette.mutedText,
                fontSize: 13,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  icon,
                  color: focused ? _Palette.accentMint : _Palette.mutedText,
                  size: 18,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    bool loading = false,
  }) {
    return SizedBox(
      height: 50,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loading ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [_Palette.accent, _Palette.accentMint],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _Palette.accent.withOpacity(0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: loading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(_Palette.bodyBg),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: _Palette.bodyBg),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _Palette.bodyBg,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      letterSpacing: 0.1,
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

  Widget _buildMediaFrame({required Widget child}) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _Palette.headerFooter,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.borderColor),
      ),
      child: child,
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, color: _Palette.mutedText, size: 24),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _Palette.mutedText, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Ambient organic bubble / blob background painter.
// ============================================================
class _BubblePainter extends CustomPainter {
  final double progress; // 0..1 looping

  _BubblePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final blobs = <_BlobSpec>[
      _BlobSpec(rx: -0.08, ry: 0.05, radius: w * 0.42, color: _Palette.accent, speed: 0.6, opacity: 0.10, blur: 90),
      _BlobSpec(rx: 1.05, ry: 0.10, radius: w * 0.34, color: _Palette.accentMint, speed: -0.5, opacity: 0.08, blur: 80),
      _BlobSpec(rx: 0.92, ry: 0.55, radius: w * 0.30, color: _Palette.accent, speed: 0.4, opacity: 0.07, blur: 70),
      _BlobSpec(rx: 0.06, ry: 0.62, radius: w * 0.28, color: _Palette.accentMint, speed: -0.35, opacity: 0.07, blur: 75),
      _BlobSpec(rx: 0.55, ry: 0.95, radius: w * 0.36, color: _Palette.accent, speed: 0.5, opacity: 0.09, blur: 85),
      _BlobSpec(rx: 0.35, ry: 0.30, radius: w * 0.14, color: _Palette.accentMint, speed: 0.8, opacity: 0.05, blur: 40),
      _BlobSpec(rx: 0.78, ry: 0.78, radius: w * 0.10, color: _Palette.accent, speed: -0.9, opacity: 0.05, blur: 35),
    ];

    for (final b in blobs) {
      final dx = sin(progress * 2 * pi * b.speed) * w * 0.015;
      final dy = cos(progress * 2 * pi * b.speed) * h * 0.012;
      final center = Offset(b.rx * w + dx, b.ry * h + dy);

      final paint = Paint()
        ..color = b.color.withOpacity(b.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, b.blur);

      canvas.drawCircle(center, b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BlobSpec {
  final double rx;
  final double ry;
  final double radius;
  final Color color;
  final double speed;
  final double opacity;
  final double blur;

  _BlobSpec({
    required this.rx,
    required this.ry,
    required this.radius,
    required this.color,
    required this.speed,
    required this.opacity,
    required this.blur,
  });
}