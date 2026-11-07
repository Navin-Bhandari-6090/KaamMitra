import 'dart:math' as math;
import 'dart:ui';

import 'package:app/web/common%20widget/GreenTextfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../state management/getx/admin/delete_user_getx.dart';
import '../common widget/design/bolbs_background.dart';



const Color _body = Color(0xFF0F1F17);
const Color _surface = Color(0xFF162E22);
const Color _bar = Color(0xFF12261C);
const Color _border = Color(0xFF234232);
const Color _primaryText = Color(0xFFE6F4EA);
const Color _muted = Color(0xFF8A9A90);
const Color _emerald = Color(0xFF22C55E);
const Color _mint = Color(0xFF34D399);
const Color _danger = Color(0xFFEF4444);
const Color _dangerDark = Color(0xFFB91C1C);
const Color _dangerSoft = Color(0xFFF87171);

// =============================================================================
// Screen
// =============================================================================
class DeleteUser extends StatelessWidget {
  final String User_JwtToken;
  const DeleteUser({super.key, required this.User_JwtToken});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DeleteUserGetx>(
      init: DeleteUserGetx(),
      initState: (state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            final DeleteUserGetx? c = state.controller;
            if (c != null && context.mounted) {
              c.verifyAdmin(jwtToken: User_JwtToken, context: context);
            }
          } catch (_) {}
        });
      },
      builder: (c) {
        return Scaffold(
          backgroundColor: _body,
          appBar: _buildAppBar(context),
          body: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(child: AmbientBackground()),
              ),
              LayoutBuilder(
                builder: (context, cons) {
                  try {
                    final double w = cons.maxWidth.isFinite
                        ? cons.maxWidth
                        : MediaQuery.of(context).size.width;
                    final double h =
                    cons.maxHeight.isFinite ? cons.maxHeight : 0;

                    final double hPad = w < 400 ? 14 : (w < 900 ? 24 : 40);
                    final double vPad = h < 500 ? 14 : 28;
                    final bool wide = w >= 900;

                    Widget page = Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
                      child: ConstrainedBox(
                        constraints:
                        BoxConstraints(maxWidth: wide ? 980 : 560),
                        child: wide
                            ? _WideLayout(
                          c: c,
                          onDelete: () => _onDelete(context, c),
                        )
                            : _NarrowLayout(
                          c: c,
                          onDelete: () => _onDelete(context, c),
                        ),
                      ),
                    );

                    // Extremely small widths: scale the whole page down
                    if (w < 220) {
                      page = FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(width: 220, child: page),
                      );
                    }

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: h),
                        child: Center(child: page),
                      ),
                    );
                  } catch (_) {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Confirm -> delete
  // ---------------------------------------------------------------------------
  Future<void> _onDelete(BuildContext context, DeleteUserGetx c) async {
    try {
      if (c.isDeleting.value) return;

      final int? userId = c.validateUserId();
      if (userId == null) return;

      final bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ConfirmDeleteDialog(userId: userId),
      );
      if (confirmed != true) return;
      if (!context.mounted) return;

      await c.DeleteUserInfo(
        UserNumber: userId,
        Current_User_JwtToken: User_JwtToken,
        context: context,
      );
    } catch (e) {
      debugPrint('DeleteUser._onDelete error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // AppBar: bordered back button, primary-colour arrow
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    bool canPop = false;
    try {
      canPop = Navigator.of(context).canPop();
    } catch (_) {}

    return AppBar(
      backgroundColor: _bar,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leadingWidth: 64,
      shape: const Border(bottom: BorderSide(color: _border)),
      leading: canPop
          ? Padding(
        padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        child: Tooltip(
          message: 'Back',
          child: Material(
            color: _surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _primaryText.withOpacity(.6),
                width: 1.2,
              ),
            ),
            child: InkWell(
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                try {
                  Navigator.of(context).maybePop();
                } catch (_) {}
              },
              child: const Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: _primaryText,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      )
          : null,
      title: const Text(
        'Delete User',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

// =============================================================================
// Layouts
// =============================================================================
class _NarrowLayout extends StatelessWidget {
  final DeleteUserGetx c;
  final VoidCallback onDelete;
  const _NarrowLayout({required this.c, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Reveal(delayMs: 0, child: _Hero(c: c)),
        const SizedBox(height: 22),
        const _Reveal(delayMs: 120, child: _InfoCard()),
        const SizedBox(height: 16),
        _Reveal(delayMs: 240, child: _FormCard(c: c, onDelete: onDelete)),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  final DeleteUserGetx c;
  final VoidCallback onDelete;
  const _WideLayout({required this.c, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Reveal(delayMs: 0, child: _Hero(c: c)),
              const SizedBox(height: 22),
              const _Reveal(delayMs: 120, child: _InfoCard()),
            ],
          ),
        ),
        const SizedBox(width: 28),
        Expanded(
          child: _Reveal(
            delayMs: 240,
            child: _FormCard(c: c, onDelete: onDelete),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Hero
// =============================================================================
class _Hero extends StatelessWidget {
  final DeleteUserGetx c;
  const _Hero({required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: c.pulse,
          builder: (context, _) {
            final double t = Curves.easeInOut.transform(c.pulse.value);
            return Transform.scale(
              scale: 1 + .06 * t,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_dangerSoft, _dangerDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _danger.withOpacity(.25 + .25 * t),
                      blurRadius: 24 + 16 * t,
                      spreadRadius: 1 + 3 * t,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_remove_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        const Text(
          'Delete User',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _primaryText,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: .4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Permanently remove a user and everything linked to them.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}

// =============================================================================
// Info card (what gets deleted)
// =============================================================================
class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    const List<List<Object>> items = [
      [Icons.person_rounded, 'User data'],
      [Icons.chat_bubble_rounded, 'Messages'],
      [Icons.mark_chat_unread_rounded, 'New message status'],
      [Icons.notifications_rounded, 'Notifications'],
      [Icons.notifications_active_rounded, 'New notification status'],
    ];

    return _Glass(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: _dangerSoft, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Everything linked to this user will be deleted',
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final List<Object> it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _emerald.withOpacity(.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(it[0] as IconData, size: 16, color: _mint),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      it[1] as String,
                      style: const TextStyle(
                        color: _primaryText,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 2),
          const Text(
            'This action is permanent and cannot be undone.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Form card
// =============================================================================
class _FormCard extends StatelessWidget {
  final DeleteUserGetx c;
  final VoidCallback onDelete;
  const _FormCard({required this.c, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_mint, _emerald],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'USER DETAILS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GreenField(
            controller: c.UserNumberController,
            label: "Enter user ID.",
            icon: Icons.numbers,
          ),
          const SizedBox(height: 18),
          _DeleteButton(c: c, onPressed: onDelete),
          _StatusBanner(c: c),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final DeleteUserGetx c;
  final VoidCallback onPressed;
  const _DeleteButton({required this.c, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool busy = c.isDeleting.value;
      final bool hovered = c.deleteHovered.value && !busy;

      return MouseRegion(
        cursor: busy ? SystemMouseCursors.basic : SystemMouseCursors.click,
        onEnter: (_) => c.deleteHovered.value = true,
        onExit: (_) => c.deleteHovered.value = false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: busy ? null : onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: 52,
            transform: Matrix4.translationValues(0, hovered ? -2 : 0, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: busy
                    ? [_danger.withOpacity(.55), _dangerDark.withOpacity(.55)]
                    : [_danger, _dangerDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: _danger.withOpacity(hovered ? .45 : .22),
                  blurRadius: hovered ? 26 : 16,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: busy
                    ? const Row(
                  key: ValueKey('busy'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Deleting…',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                )
                    : const Row(
                  key: ValueKey('idle'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_forever_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Delete user',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _StatusBanner extends StatelessWidget {
  final DeleteUserGetx c;
  const _StatusBanner({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final String msg = c.statusMessage.value;
      final bool ok = c.statusIsSuccess.value;

      return AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: msg.isEmpty
              ? const SizedBox(width: double.infinity, key: ValueKey('none'))
              : Container(
            key: ValueKey(msg),
            width: double.infinity,
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (ok ? _emerald : _danger).withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (ok ? _emerald : _danger).withOpacity(.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  ok
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  size: 18,
                  color: ok ? _mint : _dangerSoft,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: TextStyle(
                      color: ok ? _mint : _dangerSoft,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// =============================================================================
// Confirm dialog
// =============================================================================
class _ConfirmDeleteDialog extends StatelessWidget {
  final int userId;
  const _ConfirmDeleteDialog({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: _danger.withOpacity(.18),
                blurRadius: 40,
                spreadRadius: -6,
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _danger.withOpacity(.15),
                      border: Border.all(color: _danger.withOpacity(.5)),
                    ),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: _dangerSoft, size: 28),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Confirm deletion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Delete user ID $userId? Their data, messages, new message status, notifications and new notification status will be permanently removed.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryText,
                        side: BorderSide(color: _primaryText.withOpacity(.5)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Yes, delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Shared building blocks
// =============================================================================
class _Glass extends StatelessWidget {
  final Widget child;
  const _Glass({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _surface.withOpacity(.78),
                _surface.withOpacity(.45),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Fade + slide-up entrance, no setState / controller needed.
class _Reveal extends StatelessWidget {
  final Widget child;
  final int delayMs;
  const _Reveal({required this.child, required this.delayMs});

  @override
  Widget build(BuildContext context) {
    final int total = 650 + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1, curve: Curves.easeOutCubic),
      builder: (context, v, ch) {
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - v)),
            child: ch,
          ),
        );
      },
      child: child,
    );
  }
}