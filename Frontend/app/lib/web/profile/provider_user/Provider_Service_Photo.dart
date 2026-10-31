import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/ServicePhotoModel.dart';
import '../../../state management/getx/profile/provider_user/view_photo_getx.dart';
import '../../bookings/view_book_file.dart';
// TODO: import ForestBackground from your booking viewer file, e.g.
// import 'package:app/.../view_book_file.dart' show ForestBackground;

// ===========================================================================
// PALETTE
// ===========================================================================
class _C {
  static const Color bg = Color(0xFF0F1F17);
  static const Color surface = Color(0xFF162E22);
  static const Color text = Color(0xFFE6F4EA);
  static const Color muted = Color(0xFF8A9A90);
  static const Color accent = Color(0xFF22C55E);
  static const Color mint = Color(0xFF34D399);
  static const Color border = Color(0xFF234232);
  static const Color borderStrong = Color(0xFF2F5A43);
}

// ===========================================================================
// SCREEN
// ===========================================================================
class ProviderServicePhoto extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  final String Service_Name;

  const ProviderServicePhoto({
    super.key,
    required this.User_Email,
    required this.User_JwtToken,
    required this.User_Role,
    required this.Service_Name,
  });

  @override
  State<ProviderServicePhoto> createState() => _ProviderServicePhotoState();
}

class _ProviderServicePhotoState extends State<ProviderServicePhoto> {
  late final ViewPhotoGetx controller;
  final String _tag = UniqueKey().toString();
  Worker? _errorWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ViewPhotoGetx(), tag: _tag);

    // Show a snackbar for genuine failures (the controller has no context).
    _errorWorker = ever<PhotoFetchResult?>(controller.result, (r) {
      try {
        if (r != null &&
            r.status == FetchStatus.failure &&
            r.message.isNotEmpty) {
          _showErrorToast(r.message);
        }
      } catch (e) {
        debugPrint('toast error: $e');
      }
    });

    controller.init(
      email: widget.User_Email,
      jwtToken: widget.User_JwtToken,
      serviceName: widget.Service_Name,
    );
  }

  @override
  void dispose() {
    _errorWorker?.dispose();
    Get.delete<ViewPhotoGetx>(tag: _tag);
    super.dispose();
  }

  void _showErrorToast(String message) {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(message,
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        );
    } catch (e) {
      debugPrint('showErrorToast error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: _BorderIconButton(
            tooltip: 'Back',
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: const Text(
          'Service Photos',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: _C.text, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: ForestBackground(
        child: SafeArea(
          top: false,
          child: LayoutBuilder(builder: (context, box) {
            final double w = box.maxWidth.isFinite ? box.maxWidth : 900;
            final double pad = w >= 900 ? 32 : (w < 600 ? 12 : 20);

            return RefreshIndicator(
              color: _C.accent,
              backgroundColor: _C.surface,
              onRefresh: () => controller.refreshPhotos(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(pad, 8, pad, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Reveal(child: _HeaderCard(c: controller)),
                          const SizedBox(height: 12),
                          _Reveal(
                              delayMs: 80,
                              child: _SearchField(c: controller)),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
                    sliver: _PhotoSliver(c: controller),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ===========================================================================
// HEADER
// ===========================================================================
class _HeaderCard extends StatelessWidget {
  final ViewPhotoGetx c;
  const _HeaderCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _C.accent.withOpacity(0.28),
                _C.mint.withOpacity(0.10),
              ]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.accent.withOpacity(0.45)),
            ),
            child: const Icon(Icons.photo_library_rounded,
                color: _C.mint, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Photo Gallery',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: _C.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Obx(() => Text(
                  c.isLoading.value
                      ? 'Loading photos...'
                      : 'Showing ${c.filteredPhotos.length} of ${c.allPhotos.length}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: _C.mint.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => _BorderIconButton(
            tooltip: 'Refresh',
            icon: Icons.refresh_rounded,
            onTap: c.isLoading.value ? null : () => c.refreshPhotos(),
          )),
        ],
      ),
    );
  }
}

// ===========================================================================
// SEARCH
// ===========================================================================
class _SearchField extends StatelessWidget {
  final ViewPhotoGetx c;
  const _SearchField({required this.c});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: TextField(
        controller: c.searchCtrl,
        onChanged: (v) => c.query.value = v,
        cursorColor: _C.accent,
        style: const TextStyle(color: _C.text, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search by resource ID or title',
          hintStyle: const TextStyle(color: _C.muted, fontSize: 13.5),
          prefixIcon: const Icon(Icons.search_rounded, color: _C.mint),
          suffixIcon: Obx(() => c.query.value.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.close_rounded, color: _C.muted),
            onPressed: () {
              c.searchCtrl.clear();
              c.query.value = '';
            },
          )),
        ),
      ),
    );
  }
}

// ===========================================================================
// GRID / STATES
// ===========================================================================
class _PhotoSliver extends StatelessWidget {
  final ViewPhotoGetx c;
  const _PhotoSliver({required this.c});

  SliverGridDelegate _delegate() =>
      const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 340,
      );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // LOADING
      if (c.isLoading.value) {
        return SliverGrid(
          gridDelegate: _delegate(),
          delegate: SliverChildBuilderDelegate(
                (_, __) => const _SkeletonCard(),
            childCount: 6,
          ),
        );
      }

      final PhotoFetchResult? r = c.result.value;

      // REAL ERROR
      if (r == null || r.status == FetchStatus.failure) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _Placeholder(
            icon: Icons.cloud_off_rounded,
            title: 'Unable to Load Photos',
            message: (r != null && r.message.isNotEmpty)
                ? r.message
                : 'Something went wrong while loading service photos.',
            action: _retryButton('Try Again'),
          ),
        );
      }

      // NOTHING UPLOADED
      if (c.allPhotos.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _Placeholder(
            icon: Icons.photo_library_outlined,
            title: 'No Photos Yet',
            message: r.message.isNotEmpty
                ? r.message
                : 'No photos have been uploaded for this service yet.',
            action: _retryButton('Refresh'),
          ),
        );
      }

      final List<ServicePhotoModel> list = c.filteredPhotos;

      // SEARCH HAS NO MATCH
      if (list.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: _Placeholder(
            icon: Icons.search_off_rounded,
            title: 'No Match Found',
            message: 'No photo matches your search.',
          ),
        );
      }

      // GRID
      return SliverGrid(
        gridDelegate: _delegate(),
        delegate: SliverChildBuilderDelegate(
              (context, i) => _Reveal(
            delayMs: math.min(i, 6) * 60,
            child: _PhotoCard(c: c, p: list[i], index: i),
          ),
          childCount: list.length,
        ),
      );
    });
  }

  Widget _retryButton(String label) {
    return ElevatedButton.icon(
      onPressed: () => c.refreshPhotos(),
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: _C.accent,
        foregroundColor: _C.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ===========================================================================
// PHOTO CARD (no path, no service name)
// ===========================================================================
class _PhotoCard extends StatelessWidget {
  final ViewPhotoGetx c;
  final ServicePhotoModel p;
  final int index;

  const _PhotoCard({required this.c, required this.p, required this.index});

  @override
  Widget build(BuildContext context) {
    final String imageUrl = c.imageUrlOf(p);
    final String title = c.displayOr(c.titleOf(p));

    return Container(
      decoration: BoxDecoration(
        color: _C.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: imageUrl.isEmpty
              ? null
              : () => _openFullScreen(context, imageUrl, title),
          child: Column(
            children: [
              Expanded(
                flex: 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl.isEmpty
                        ? const _ImageFallback()
                        : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) =>
                      progress == null
                          ? child
                          : const _ImageLoading(),
                      errorBuilder: (ctx, e, st) =>
                      const _ImageFallback(),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(10),
                          border:
                          Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: const TextStyle(
                              color: _C.text,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Icon(Icons.fullscreen_rounded,
                            color: _C.text, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Title',
                          style: TextStyle(
                              color: _C.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _C.text,
                            fontSize: 14,
                            height: 1.25,
                            fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoChip(
                              label: 'Resource ID',
                              value: c.displayOr(c.idOf(p)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _InfoChip(
                              label: 'Service ID',
                              value: c.displayOr(c.serviceIdOf(p)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context, String imageUrl, String title) {
    try {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (_, __, ___) =>
              _FullScreenPhoto(imageUrl: imageUrl, title: title),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        ),
      );
    } catch (e) {
      debugPrint('openFullScreen error: $e');
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _C.muted, fontSize: 9.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 1),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _C.text, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ImageLoading extends StatelessWidget {
  const _ImageLoading();
  @override
  Widget build(BuildContext context) => Container(
    color: _C.bg,
    alignment: Alignment.center,
    child: const SizedBox(
      width: 26,
      height: 26,
      child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(_C.accent)),
    ),
  );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) => Container(
    color: _C.bg,
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.broken_image_outlined, color: _C.muted, size: 32),
        SizedBox(height: 6),
        Text('Image unavailable',
            style: TextStyle(color: _C.muted, fontSize: 11)),
      ],
    ),
  );
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              color: _C.bg,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _C.accent),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: 110,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(child: _bar()),
                      const SizedBox(width: 6),
                      Expanded(child: _bar()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar() => Container(
    height: 28,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

// ===========================================================================
// FULLSCREEN (title only, never the path)
// ===========================================================================
class _FullScreenPhoto extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _FullScreenPhoto({required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (ctx, child, progress) => progress == null
                        ? child
                        : const Center(
                        child: CircularProgressIndicator(
                            color: _C.accent)),
                    errorBuilder: (ctx, e, st) => const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: _C.muted, size: 60),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  _BorderIconButton(
                    tooltip: 'Close',
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Glass(
                      radius: 14,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _C.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: _Glass(
                  radius: 20,
                  padding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, color: _C.mint, size: 17),
                      SizedBox(width: 7),
                      Text('Pinch to zoom',
                          style: TextStyle(
                              color: _C.muted, fontSize: 11.5)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// REUSABLE PIECES
// ===========================================================================

/// Fade + slide-up entrance.
class _Reveal extends StatelessWidget {
  final Widget child;
  final int delayMs;
  const _Reveal({required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    final int total = 480 + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1.0, curve: Curves.easeOutCubic),
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0).toDouble(),
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Frosted-glass container.
class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Bordered square icon button (arrow uses primary text color).
class _BorderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _BorderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: enabled ? _C.borderStrong : _C.border,
                width: 1.3,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: enabled ? _C.text : _C.text.withOpacity(0.35),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty / null / error state. Used for "No data available" everywhere.
class _Placeholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _Placeholder({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _Reveal(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: _Glass(
              radius: 22,
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.accent.withOpacity(0.09),
                      border: Border.all(color: _C.accent.withOpacity(0.4)),
                    ),
                    child: Icon(icon,
                        size: 32, color: _C.accent.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: _C.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: _C.muted, fontSize: 13.5, height: 1.4),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 16),
                    action!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}