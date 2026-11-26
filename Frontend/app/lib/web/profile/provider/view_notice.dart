import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// Adjust to your ambient background file location.
import '../../../state management/getx/profile/provider/view_notice_getx.dart';
import '../../common method/ui_kit.dart';
import '../../common widget/design/bolbs_background.dart';



// Adjust to where date_time.dart is saved in your project.
import '../../common method/date_time.dart';

import '../../../models/NoticeProviderModel.dart';


class ViewNotice extends StatelessWidget {
  final String Current_User_JwtToken;

  const ViewNotice({super.key, required this.Current_User_JwtToken});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ViewNoticeGetx>(
      init: ViewNoticeGetx(jwtToken: Current_User_JwtToken),
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
                              const SizedBox(height: 24),
                              _Controls(controller: c),
                              const SizedBox(height: 16),
                              _ResultsSummary(controller: c),
                              const SizedBox(height: 14),
                              _NoticeList(controller: c),
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
  final ViewNoticeGetx controller;

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
                    'My Notices',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View, search and manage your notices',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _RefreshButton(onTap: () => controller.fetchNotices()),
          ],
        ),
        const SizedBox(height: 14),
        Obx(
              () => controller.isLoading.value
              ? const LinearProgressIndicator(
            minHeight: 3,
            color: AppColors.accent,
            backgroundColor: AppColors.border,
          )
              : const SizedBox(height: 3),
        ),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RefreshButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Refresh notices',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryText.withOpacity(0.55),
                width: 1.4,
              ),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primaryText,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final ViewNoticeGetx controller;

  const _Controls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller.searchController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: AppColors.primaryText),
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              hintText: 'Search by notice ID',
              hintStyle: TextStyle(color: AppColors.mutedText.withOpacity(0.6)),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.mutedText,
              ),
              suffixIcon: Obx(
                    () => controller.searchQuery.value.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.mutedText,
                  ),
                  onPressed: controller.clearSearch,
                ),
              ),
              filled: true,
              fillColor: AppColors.body.withOpacity(0.55),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: _border(AppColors.border),
              enabledBorder: _border(AppColors.border),
              focusedBorder: _border(AppColors.accent, 1.6),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'SORT BY DATE',
                style: TextStyle(
                  color: AppColors.mint,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Obx(
                    () => _SortPill(
                  label: 'Newest first',
                  icon: Icons.arrow_downward_rounded,
                  selected: controller.sortNewestFirst.value,
                  onTap: () => controller.setSortNewestFirst(true),
                ),
              ),
              Obx(
                    () => _SortPill(
                  label: 'Oldest first',
                  icon: Icons.arrow_upward_rounded,
                  selected: !controller.sortNewestFirst.value,
                  onTap: () => controller.setSortNewestFirst(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
}

class _SortPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.body : AppColors.primaryText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : AppColors.primaryText.withOpacity(0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultsSummary extends StatelessWidget {
  final ViewNoticeGetx controller;

  const _ResultsSummary({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final int shown = controller.visibleNotices.length;
      final int total = controller.notices.length;
      return Text(
        'Showing $shown of $total notices',
        style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
      );
    });
  }
}

class _NoticeList extends StatelessWidget {
  final ViewNoticeGetx controller;

  const _NoticeList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.notices.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        );
      }

      if (controller.errorMessage.value != null && controller.notices.isEmpty) {
        return _ErrorState(
          message: controller.errorMessage.value!,
          onRetry: () => controller.fetchNotices(),
        );
      }

      if (controller.notices.isEmpty) {
        return const DataNotAvailable(
          message: 'Data not available',
          icon: Icons.campaign_outlined,
        );
      }

      final List<NoticeProviderModel> list = controller.visibleNotices;

      if (list.isEmpty) {
        return const DataNotAvailable(
          message: 'No notice found for this ID',
          icon: Icons.search_off_rounded,
        );
      }

      return LayoutBuilder(
        builder: (context, box) {
          final bool twoColumns = box.maxWidth >= 720;
          final double cardWidth =
          twoColumns ? (box.maxWidth - 20) / 2 : box.maxWidth;

          return Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              for (final NoticeProviderModel notice in list)
                SizedBox(
                  key: ValueKey(notice.noticeId),
                  width: cardWidth,
                  child: _NoticeCard(controller: controller, notice: notice),
                ),
            ],
          );
        },
      );
    });
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: AppColors.danger, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.primaryText, fontSize: 15),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.body,
            ),
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final ViewNoticeGetx controller;
  final NoticeProviderModel notice;

  const _NoticeCard({required this.controller, required this.notice});

  @override
  Widget build(BuildContext context) {
    final int? id = notice.noticeId?.toInt();
    final String name = [notice.firstName, notice.lastName]
        .where((e) => e != null && e.trim().isNotEmpty)
        .join(' ');

    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(
                url: controller.photoUrl(notice.photo),
                initials: _initials(notice.firstName, notice.lastName),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      safeText(name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      safeText(notice.serviceName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mint,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (id != null) _IdBadge(id: id),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.body.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              safeText(notice.message),
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  color: AppColors.mutedText, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  safeText(formatDateTime(notice.createdAt ?? '')),
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                  ),
                ),
              ),
              _DeleteButton(controller: controller, id: id, notice: notice),
            ],
          ),
        ],
      ),
    );
  }

  static String _initials(String? first, String? last) {
    final String f = (first ?? '').trim();
    final String l = (last ?? '').trim();
    final String s =
        (f.isNotEmpty ? f.substring(0, 1) : '') +
            (l.isNotEmpty ? l.substring(0, 1) : '');
    return s.isEmpty ? '?' : s.toUpperCase();
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String initials;

  const _Avatar({required this.url, required this.initials});

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.body,
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: ClipOval(
        child: url == null
            ? fallback
            : Image.network(
          url!,
          fit: BoxFit.cover,
          width: 52,
          height: 52,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stack) => fallback,
        ),
      ),
    );
  }
}

class _IdBadge extends StatelessWidget {
  final int id;

  const _IdBadge({required this.id});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Text(
        '#$id',
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final ViewNoticeGetx controller;
  final int? id;
  final NoticeProviderModel notice;

  const _DeleteButton({
    required this.controller,
    required this.id,
    required this.notice,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool busy = id != null && controller.deletingId.value == id;
      final bool anyBusy = controller.deletingId.value != null;

      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onPressed: (id == null || anyBusy)
            ? null
            : () => controller.confirmAndDelete(notice),
        icon: busy
            ? const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.danger,
          ),
        )
            : const Icon(Icons.delete_outline_rounded, size: 18),
        label: Text(
          busy ? 'Deleting' : 'Delete',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    });
  }
}