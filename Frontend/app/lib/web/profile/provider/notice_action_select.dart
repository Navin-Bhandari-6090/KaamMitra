import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Adjust to your ambient background file location.
import '../../../state management/getx/profile/provider/notice_action_select_getx.dart';
import '../../common method/ui_kit.dart';
import '../../common widget/design/bolbs_background.dart';


class NoticeActionSelect extends StatelessWidget {
  final String Current_User_JwtToken;

  const NoticeActionSelect({super.key, required this.Current_User_JwtToken});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NoticeActionSelectGetx>(
      init: NoticeActionSelectGetx(jwtToken: Current_User_JwtToken),
      builder: (c) => Scaffold(
        backgroundColor: AppColors.body,
        body: Stack(
          children: [
            const Positioned.fill(child: AmbientBackground()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final double pad = AppResponsive.horizontalPadding(width);

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: pad, vertical: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: AppResponsive.contentMaxWidth(width),
                        ),
                        child: FadeSlideIn(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Header(controller: c),
                              const SizedBox(height: 36),
                              _ActionsLayout(
                                controller: c,
                                wide: AppResponsive.isWide(width),
                              ),
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
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final NoticeActionSelectGetx controller;

  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    final bool canGoBack = Navigator.of(context).canPop();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (canGoBack) ...[
              const BorderedBackButton(),
              const SizedBox(width: 16),
            ],
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notices',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Choose what you want to do next',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Obx(
              () => controller.isVerifying.value
              ? const LinearProgressIndicator(
            minHeight: 3,
            color: AppColors.accent,
            backgroundColor: AppColors.border,
          )
              : const SizedBox(height: 3),
        ),
        Obx(() {
          final String? error = controller.errorMessage.value;
          if (error == null) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.verifySession,
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ActionsLayout extends StatelessWidget {
  final NoticeActionSelectGetx controller;
  final bool wide;

  const _ActionsLayout({required this.controller, required this.wide});

  @override
  Widget build(BuildContext context) {
    final Widget addCard = _ActionCard(
      index: 0,
      controller: controller,
      icon: Icons.post_add_rounded,
      title: 'Add Notice',
      subtitle: 'Create and publish a new notice for your users.',
      onTap: controller.openAddNotice,
    );

    final Widget viewCard = _ActionCard(
      index: 1,
      controller: controller,
      icon: Icons.notifications_active_outlined,
      title: 'View Notices',
      subtitle: 'Browse and manage notices that are already published.',
      onTap: controller.openViewNotice,
    );

    if (wide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: addCard),
            const SizedBox(width: 20),
            Expanded(child: viewCard),
          ],
        ),
      );
    }

    return Column(
      children: [
        addCard,
        const SizedBox(height: 20),
        viewCard,
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final int index;
  final NoticeActionSelectGetx controller;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.index,
    required this.controller,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => controller.setHover(index),
      onExit: (_) => controller.setHover(-1),
      child: Obx(() {
        final bool hovered = controller.hoveredIndex.value == index;

        return AnimatedScale(
          scale: hovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: GlassCard(
            highlighted: hovered,
            onTap: onTap,
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withOpacity(0.95),
                        AppColors.mint.withOpacity(0.75),
                      ],
                    ),
                  ),
                  child: Icon(icon, color: AppColors.body, size: 28),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Open',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}