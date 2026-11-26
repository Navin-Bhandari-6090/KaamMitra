import 'dart:math' as math;

import 'package:app/state management/getx/admin/admin_home_getx.dart';
import 'package:app/web/admin/send_notification_user.dart';
import 'package:app/web/admin/update_user_login_access.dart';
import 'package:app/web/admin/user_linked_resources.dart';

import 'package:app/models/NotificationsInfoModel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../common method/Commmon_Method.dart';
import '../common method/date_time.dart';
import '../common widget/design/bolbs_background.dart';
import 'Booking_pro_task_complete_pay.dart';
import 'add_del_advertisement_screen.dart';
import 'add_del_services.dart';
import 'add_footer_info.dart';
import 'admin_qr.dart';
import 'advance_pay_qr_info.dart';
import 'booking_pro_task_pay_summary.dart';
import 'del_pro_reg_service_res.dart';
import 'del_res.dart';
import 'delete_user.dart';
import 'manage_media.dart';
import 'manage_no_of_res_per_user.dart';
import 'manage_notice.dart';

class _C {
  static const Color bg = Color(0xFF0F1F17);
  static const Color surface = Color(0xFF162E22);
  static const Color bar = Color(0xFF12261C);
  static const Color text = Color(0xFFE6F4EA);
  static const Color muted = Color(0xFF8A9A90);
  static const Color accent = Color(0xFF22C55E);
  static const Color mint = Color(0xFF34D399);
  static const Color border = Color(0xFF234232);
  static const Color red = Color(0xFFEF4444);
  static const Color danger = Color(0xFFF87171);
}

class _Fmt {
  static const String noData = 'No data available';

  static String date(String? raw) {
    try {
      final String s = (raw ?? '').trim();
      if (s.isEmpty || s.toLowerCase() == 'null') return noData;
      final String f = formatDateTime(s);
      return f.isEmpty ? s : f;
    } catch (_) {
      return noData;
    }
  }

  static String text(String? v) {
    final String t = (v ?? '').trim();
    return (t.isEmpty || t.toLowerCase() == 'null') ? noData : t;
  }

  static BoxDecoration card({double radius = 22}) => BoxDecoration(
    color: _C.surface.withOpacity(.88),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _C.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.28),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class AdminHomeScreen extends StatefulWidget {
  final String User_Role;
  final String User_JwtToken;
  final String User_Email;
  final int User_Number;

  const AdminHomeScreen({
    super.key,
    required this.User_Role,
    required this.User_JwtToken,
    required this.User_Email,
    required this.User_Number,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final String _tag = UniqueKey().toString();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AdminHomeGetx c;

  @override
  void initState() {
    super.initState();
    try {
      Admin_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
    } catch (_) {}
    c = Get.put(AdminHomeGetx(), tag: _tag)
      ..init(email: widget.User_Email, jwtToken: widget.User_JwtToken);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) c.loadAll(context);
    });
  }

  @override
  void dispose() {
    Get.delete<AdminHomeGetx>(tag: _tag);
    super.dispose();
  }

  void _go(Widget Function() page) {
    try {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page()));
    } catch (_) {}
  }

  void _openNotifications() {
    try {
      _scaffoldKey.currentState?.openEndDrawer();
      c.openNotifications(context);
    } catch (_) {}
  }

  void _closeNotifications() {
    try {
      _scaffoldKey.currentState?.closeEndDrawer();
    } catch (_) {}
  }

  Future<void> _logout() async {
    try {
      await Logout(context: context);
    } catch (_) {}
  }

  List<_Section> _sections() {
    final String jwt = widget.User_JwtToken;
    final String role = widget.User_Role;
    final String email = widget.User_Email;
    final int number = widget.User_Number;

    return [
      _Section(
        title: 'Users',
        icon: Icons.people_alt_rounded,
        items: [
          _Item(
            icon: Icons.link_rounded,
            title: 'User linked resources',
            subtitle: 'Resources linked to each user',
            onTap: () => _go(() => UserLinkedResources(User_JwtToken: jwt)),
          ),
          _Item(
            icon: Icons.lock_person_rounded,
            title: 'User login access',
            subtitle: 'Block or allow user accounts',
            onTap: () => _go(() => UpdateUserLoginAccess(
              User_Role: role,
              User_JwtToken: jwt,
              User_Email: email,
            )),
          ),
          _Item(
            icon: Icons.send_rounded,
            title: 'Send notification to user',
            subtitle: 'Message a user directly',
            onTap: () => _go(() => SendNotificationUser(
              User_Role: role,
              User_JwtToken: jwt,
              User_Email: email,
              User_Number: number,
            )),
          ),
          _Item(
            icon: Icons.person_remove_rounded,
            title: 'Delete user',
            subtitle: 'Remove a user account',
            onTap: () => _go(() => DeleteUser(User_JwtToken: jwt)),
          ),
        ],
      ),
      _Section(
        title: 'Services',
        icon: Icons.handyman_rounded,
        items: [
          _Item(
            icon: Icons.campaign_rounded,
            title: 'Advertisements',
            subtitle: 'Add or delete advertisements',
            onTap: () => _go(() => AdvertisementScreen(
              User_Role: role,
              User_JwtToken: jwt,
              User_Email: email,
            )),
          ),
          _Item(
            icon: Icons.build_circle_rounded,
            title: 'Services',
            subtitle: 'Add or delete services',
            onTap: () => _go(() => AddDelServices(
              User_Role: role,
              User_JwtToken: jwt,
              User_Email: email,
            )),
          ),
          _Item(
            icon: Icons.delete_sweep_rounded,
            title: 'Provider services',
            subtitle: 'Delete provider registered services',
            onTap: () => _go(() => DelProRegServiceRes(
              User_Role: role,
              User_JwtToken: jwt,
              User_Email: email,
            )),
          ),
          _Item(
            icon: Icons.manage_accounts_rounded,
            title: 'Manage provider services',
            subtitle: 'Services and their resources',
            onTap: () => _go(() => AdminDelServORRes(
              Current_User_JwtToken: jwt,
            )),
          ),
        ],
      ),
      _Section(
        title: 'Bookings & payments',
        icon: Icons.account_balance_wallet_rounded,
        items: [
          _Item(
            icon: Icons.task_alt_rounded,
            title: 'Bookings and provider task complete payment.',
            subtitle: 'Provider task complete payments',
            onTap: () => _go(() => BookingProTaskCompletePay(
              User_Role: role,
              User_JwtToken: jwt,
              User_Email: email,
              User_Number: number,
            )),
          ),
          _Item(
            icon: Icons.analytics_rounded,
            title: 'Filtered booking details',
            subtitle: 'Analysis and risk review',
            onTap: () => _go(() => FilterSummaryBookingTaskCompPayment(
              User_JwtToken: jwt,
              User_Role: role,
              User_Email: email,
              User_Number: number,
            )),
          ),
          _Item(
            icon: Icons.qr_code_2_rounded,
            title: 'Advance payment & QR',
            subtitle: 'Advance payment and payment QR info',
            onTap: () => _go(() => AdvancePayQrInfo(
              User_Role: role,
              User_JwtToken: jwt,
              User_Email: email,
              User_Number: number,
            )),
          ),
          _Item(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Admin QR',
            subtitle: 'QR for provider task complete',
            onTap: () => _go(() => AdminQr(
              User_Role: role,
              User_JwtToken: jwt,
              User_Email: email,
              User_Number: number,
            )),
          ),
        ],
      ),
      _Section(
        title: 'Content',
        icon: Icons.perm_media_rounded,
        items: [
          _Item(
            icon: Icons.photo_library_rounded,
            title: 'Shared media',
            subtitle: 'Manage shared photos, videos and files',
            onTap: () => _go(() => ManageMedia(Jwt_Token: jwt)),
          ),
          _Item(
            icon: Icons.web_rounded,
            title: 'Footer details',
            subtitle: 'Update footer information',
            onTap: () => _go(() => AddFooterInfo(User_JwtToken: jwt)),
          ),
        ],
      ),

      _Section(
        title: 'Notices',
        icon: Icons.perm_media_rounded,
        items: [

          _Item(
            icon: Icons.data_exploration_outlined,
            title: 'Manage notices',
            subtitle: "Review and delete notices",
            onTap: () => _go(() => ManageNotice(Current_User_JwtToken: jwt)),
          ),
        ],
      ),


      _Section(
        title: 'No of resources.',
        icon: Icons.perm_media_rounded,
        items: [

          _Item(
            icon: Icons.data_exploration_outlined,
            title: 'Manage No of resources per user.',
            subtitle: "Review and delete no of resources.",
            onTap: () => _go(() => ManageNoOfResPerUser(User_JwtToken: jwt)),
          ),
        ],
      ),


    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<_Section> sections = _sections();
    int animIndex = 0;
    final List<Widget> blocks = [];
    for (final s in sections) {
      blocks.add(_SectionBlock(section: s, startIndex: animIndex));
      blocks.add(const SizedBox(height: 20));
      animIndex += s.items.length;
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bar,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Admin Home',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: _C.text, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          Obx(() => _AppIconButton(
            tip: 'Refresh',
            icon: Icons.refresh_rounded,
            loading: c.isLoading.value,
            onTap: () => c.loadAll(context),
          )),
          const SizedBox(width: 8),
          Obx(() => _BellButton(
            hasNew: c.hasNew,
            count: c.newCount,
            onTap: _openNotifications,
          )),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.border),
        ),
      ),
      endDrawer: _NotificationsDrawer(
        c: c,
        onClose: _closeNotifications,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: AmbientBackground())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final double w = box.maxWidth.isFinite ? box.maxWidth : 900;
                final double hPad = w >= 700 ? 24 : 14;

                return RefreshIndicator(
                  color: _C.accent,
                  backgroundColor: _C.surface,
                  onRefresh: () => c.loadAll(context),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Hero(c: c),
                            const SizedBox(height: 20),
                            ...blocks,
                            _LogoutButton(onTap: _logout),
                          ],
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
}

// =============================================================================
// APP BAR
// =============================================================================
class _AppIconButton extends StatelessWidget {
  final String tip;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;
  const _AppIconButton({
    required this.tip,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: loading ? null : onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.text, width: 1.2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: _C.text, size: 22),
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: loading ? 1 : 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _C.surface.withOpacity(.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: _C.accent),
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

/// Bell in the AppBar.
/// hasNew == true  -> large red bell that rings (shakes) and shows the count.
/// hasNew == false -> normal bell, no animation.
class _BellButton extends StatefulWidget {
  final bool hasNew;
  final int count;
  final VoidCallback onTap;
  const _BellButton({
    required this.hasNew,
    required this.count,
    required this.onTap,
  });

  @override
  State<_BellButton> createState() => _BellButtonState();
}

class _BellButtonState extends State<_BellButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  late final Animation<double> _swing = TweenSequence<double>([
    TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 0.32), weight: 1),
    TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.32, end: -0.32), weight: 2),
    TweenSequenceItem<double>(
        tween: Tween<double>(begin: -0.32, end: 0.24), weight: 2),
    TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.24, end: -0.16), weight: 2),
    TweenSequenceItem<double>(
        tween: Tween<double>(begin: -0.16, end: 0.0), weight: 1),
    TweenSequenceItem<double>(
        tween: ConstantTween<double>(0.0), weight: 8),
  ]).animate(_ring);

  @override
  void initState() {
    super.initState();
    if (widget.hasNew) _ring.repeat();
  }

  @override
  void didUpdateWidget(covariant _BellButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasNew && !_ring.isAnimating) {
      _ring.repeat();
    } else if (!widget.hasNew && _ring.isAnimating) {
      _ring.stop();
      _ring.value = 0;
    }
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasNew = widget.hasNew;
    final String badge = widget.count > 99 ? '99+' : '${widget.count}';

    return Tooltip(
      message: hasNew ? 'New notifications' : 'Notifications',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onTap,
        child: SizedBox(
          width: 56,
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hasNew ? _C.red.withOpacity(.18) : _C.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasNew ? _C.red : _C.text,
                    width: hasNew ? 1.8 : 1.2,
                  ),
                  boxShadow: hasNew
                      ? [
                    BoxShadow(
                      color: _C.red.withOpacity(.5),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                      : const [],
                ),
                child: AnimatedBuilder(
                  animation: _swing,
                  builder: (context, child) => Transform.rotate(
                    angle: hasNew ? _swing.value : 0,
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                  child: Icon(
                    hasNew
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: hasNew ? _C.red : _C.text,
                    size: hasNew ? 30 : 24,
                  ),
                ),
              ),
              if (hasNew && widget.count > 0)
                Positioned(
                  right: 0,
                  top: -2,
                  child: Container(
                    constraints:
                    const BoxConstraints(minWidth: 20, minHeight: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _C.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.bg, width: 1.5),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
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
// NOTIFICATIONS DRAWER
// =============================================================================
class _NotificationsDrawer extends StatelessWidget {
  final AdminHomeGetx c;
  final VoidCallback onClose;
  const _NotificationsDrawer({required this.c, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final double width = math.min(MediaQuery.sizeOf(context).width * .92, 400);
    return Drawer(
      width: width,
      backgroundColor: _C.bg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _C.accent.withOpacity(.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.accent.withOpacity(.35)),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: _C.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                              color: _C.text,
                              fontSize: 17,
                              fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${c.notifications.length} message(s)',
                          style: const TextStyle(
                              color: _C.mint, fontSize: 12.5),
                        ),
                      ],
                    )),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onClose,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _C.text, width: 1.2),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: _C.text, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 2,
              child: Obx(() => AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: c.isLoading.value ? 1 : 0,
                child: const LinearProgressIndicator(
                  minHeight: 2,
                  color: _C.accent,
                  backgroundColor: _C.border,
                ),
              )),
            ),
            Expanded(
              child: Obx(() => _body(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    try {
      if (c.notifications.isEmpty) {
        if (c.isLoading.value) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: List.generate(
              3,
                  (_) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _SkeletonRow(),
              ),
            ),
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inbox_rounded, color: _C.muted, size: 44),
                const SizedBox(height: 12),
                const Text(_Fmt.noData,
                    style: TextStyle(color: _C.muted, fontSize: 14)),
                if (c.loadFailed.value) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => c.loadAll(context),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _C.text,
                      side: const BorderSide(color: _C.border),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        itemCount: c.notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _NoteTile(
          index: i,
          note: c.notifications[i],
        ),
      );
    } catch (_) {
      return const Center(
        child: Text(_Fmt.noData, style: TextStyle(color: _C.muted)),
      );
    }
  }
}

class _NoteTile extends StatelessWidget {
  final int index;
  final NotificationsInfoModel note;
  const _NoteTile({required this.index, required this.note});

  @override
  Widget build(BuildContext context) {
    final String message = _Fmt.text(note.message);
    final bool hasMessage = message != _Fmt.noData;
    final String dateText = _Fmt.date(note.date);
    final bool hasDate = dateText != _Fmt.noData;
    final String userId = note.receiverNumber == null
        ? _Fmt.noData
        : note.receiverNumber!.toInt().toString();
    final bool hasUser = userId != _Fmt.noData;

    return RepaintBoundary(
      key: ValueKey('note_${note.notId ?? index}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 14, color: _C.mint.withOpacity(.9)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _C.muted,
                      fontSize: 11.5,
                      fontStyle:
                      hasDate ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                color: hasMessage ? _C.text : _C.muted,
                fontSize: 13.5,
                height: 1.45,
                fontStyle: hasMessage ? FontStyle.normal : FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_rounded, size: 14, color: _C.muted),
                const SizedBox(width: 4),
                const Text('Your ID: ',
                    style: TextStyle(color: _C.muted, fontSize: 12)),
                Text(
                  userId,
                  style: TextStyle(
                    color: hasUser ? _C.text : _C.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontStyle: hasUser ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
    );
  }
}

// =============================================================================
// HERO
// =============================================================================
class _Hero extends StatelessWidget {
  final AdminHomeGetx c;
  const _Hero({required this.c});

  @override
  Widget build(BuildContext context) {
    return _Entrance(
      index: 0,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _Fmt.card(radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.accent.withOpacity(.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.accent.withOpacity(.35)),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: _C.accent, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin dashboard',
                        style: TextStyle(
                            color: _C.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Manage users, services, bookings and content.',
                        style: TextStyle(color: _C.muted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(
                  icon: Icons.notifications_rounded,
                  label: 'Messages',
                  value: '${c.notifications.length}',
                  color: _C.mint,
                ),
                _StatChip(
                  icon: Icons.fiber_new_rounded,
                  label: 'New',
                  value: '${c.newCount}',
                  color: c.hasNew ? _C.red : _C.muted,
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(color: _C.muted, fontSize: 12.5)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTIONS + ACTION TILES
// =============================================================================
class _Section {
  final String title;
  final IconData icon;
  final List<_Item> items;
  const _Section({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class _Item {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Item({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _SectionBlock extends StatelessWidget {
  final _Section section;
  final int startIndex;
  const _SectionBlock({required this.section, required this.startIndex});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(section.icon, size: 16, color: _C.mint),
              const SizedBox(width: 8),
              Text(
                section.title.toUpperCase(),
                style: const TextStyle(
                  color: _C.mint,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
        ),
        _Grid(
          minTile: 260,
          children: [
            for (int i = 0; i < section.items.length; i++)
              _Entrance(
                index: startIndex + i + 1,
                child: _ActionTile(item: section.items[i]),
              ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final _Item item;
  const _ActionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.surface.withOpacity(.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.2),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _C.accent.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.accent.withOpacity(.35)),
              ),
              child: Icon(item.icon, color: _C.accent, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _C.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _C.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: _C.mint, size: 22),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final Future<void> Function() onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: OutlinedButton.icon(
        onPressed: () => onTap(),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('Logout'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _C.danger,
          minimumSize: const Size(0, 52),
          side: BorderSide(color: _C.danger.withOpacity(.6), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

// =============================================================================
// SHARED
// =============================================================================
class _Grid extends StatelessWidget {
  final double minTile;
  final double gap;
  final List<Widget> children;
  const _Grid({required this.minTile, required this.children, this.gap = 12});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, b) {
      final double maxW = b.maxWidth.isFinite ? b.maxWidth : minTile;
      final int cols = math.max(1, ((maxW + gap) / (minTile + gap)).floor());
      final double w = math.max(0.0, (maxW - gap * (cols - 1)) / cols);
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final ch in children) SizedBox(width: w, child: ch)],
      );
    });
  }
}

class _Entrance extends StatelessWidget {
  final int index;
  final Widget child;
  const _Entrance({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + math.min(index * 60, 420)),
      curve: Curves.easeOutCubic,
      builder: (context, v, ch) => Opacity(
        opacity: v.clamp(0.0, 1.0).toDouble(),
        child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: ch),
      ),
      child: child,
    );
  }
}