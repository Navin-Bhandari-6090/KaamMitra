import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/ServicePhotoModel.dart';
import '../../../state management/getx/profile/provider_user/view_photo_getx.dart';


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

class _ProviderServicePhotoState extends State<ProviderServicePhoto>
    with TickerProviderStateMixin {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _green = Color(0xFF00E676);
  static const Color _darkGreen = Color(0xFF00A86B);
  static const Color _black = Color(0xFF080B09);
  static const Color _card = Color(0xFF111713);
  static const Color _card2 = Color(0xFF161D18);
  static const Color _grey = Color(0xFF9AA59D);

  // ============================================================
  // VARIABLES
  // ============================================================

  late final ViewPhotoGetx controller;
  final String _tag = UniqueKey().toString();

  late AnimationController _pageAnimationController;
  late Animation<double> _fadeAnimation;

  Worker? _errorWorker;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    controller = Get.put(ViewPhotoGetx(), tag: _tag);

    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeOutCubic,
    );

    // The original showed a SnackBar for every genuine failure result
    // (via _showErrorToast) — that behavior lives here now, since the
    // controller has no BuildContext to call ScaffoldMessenger with.
    _errorWorker = ever<PhotoFetchResult?>(controller.result, (result) {
      if (result != null && result.status == FetchStatus.failure && result.message.isNotEmpty) {
        _showErrorToast(result.message);
      }
    });

    controller.init(
      email: widget.User_Email,
      jwtToken: widget.User_JwtToken,
      serviceName: widget.Service_Name,
    );

    _pageAnimationController.forward();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    _errorWorker?.dispose();
    Get.delete<ViewPhotoGetx>(tag: _tag);
    super.dispose();
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshPhotos() async {
    await controller.refreshPhotos();
  }

  // ============================================================
  // TOAST / SNACKBAR
  // ============================================================

  void _showErrorToast(String message) {
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
                child: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
  }

  // ============================================================
  // OPEN FULL SCREEN IMAGE
  // ============================================================

  void _openImage(BuildContext context, ServicePhotoModel photo) {
    final String imageUrl = controller.buildImageUrl(photo.servicePhoto);
    if (imageUrl.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenPhoto(
            imageUrl: imageUrl,
            serviceName: photo.serviceName ?? widget.Service_Name,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  // ============================================================
  // RESPONSIVE COLUMNS
  // ============================================================

  int _getColumns(double width) {
    if (width >= 1400) return 5;
    if (width >= 1100) return 4;
    if (width >= 750) return 3;
    if (width >= 500) return 2;
    return 1;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _black,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _green.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _green.withOpacity(.25)),
              ),
              child: const Icon(Icons.photo_library_rounded, color: _green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Service Photos",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.Service_Name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: _refreshPhotos,
            icon: const Icon(Icons.refresh_rounded, color: _green),
          ),
          const SizedBox(width: 6),
        ],
      ),

      // ========================================================
      // BODY — header container removed; grid starts right away.
      // ========================================================
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final double horizontalPadding = width >= 900 ? 40 : 18;

              return RefreshIndicator(
                color: _green,
                backgroundColor: _card,
                onRefresh: _refreshPhotos,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        16,
                        horizontalPadding,
                        30,
                      ),
                      sliver: Obx(() {
                        // ==============================
                        // LOADING
                        // ==============================
                        if (controller.isLoading.value) {
                          return SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildSkeletonCard(),
                              childCount: width >= 750 ? 6 : 4,
                            ),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _getColumns(width),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: width < 500 ? .80 : .82,
                            ),
                          );
                        }

                        final result = controller.result.value;

                        // ==============================
                        // REAL SERVER/NETWORK ERROR
                        // ==============================
                        if (result == null || result.status == FetchStatus.failure) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildErrorState(
                              result?.message.isNotEmpty == true
                                  ? result!.message
                                  : "Something went wrong while loading your service photos.",
                            ),
                          );
                        }

                        // ==============================
                        // NOTHING UPLOADED YET (404 / empty list)
                        // ==============================
                        if (result.status == FetchStatus.notFound || result.photos.isEmpty) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(
                              result.message.isNotEmpty
                                  ? result.message
                                  : "No photos have been uploaded for \"${widget.Service_Name}\" yet.",
                            ),
                          );
                        }

                        // ==============================
                        // GRID
                        // ==============================
                        final photos = result.photos;
                        return SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) => _AnimatedPhotoCard(
                              index: index,
                              child: _buildPhotoCard(photos[index], index),
                            ),
                            childCount: photos.length,
                          ),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _getColumns(width),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: width < 500 ? .80 : .82,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PHOTO CARD
  // ============================================================

  Widget _buildPhotoCard(ServicePhotoModel photo, int index) {
    final String imageUrl = controller.buildImageUrl(photo.servicePhoto);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openImage(context, photo),
        child: Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(.06)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 15, offset: const Offset(0, 7)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                flex: 7,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl.isNotEmpty)
                      Hero(
                        tag: "service_photo_${photo.providerServiceResourcesId}",
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildImageLoading();
                          },
                          errorBuilder: (context, error, stackTrace) => _buildImageError(),
                        ),
                      )
                    else
                      _buildImageError(),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.65),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(.10)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_rounded, color: _green, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              "#${index + 1}",
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.65),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(.12)),
                        ),
                        child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              photo.serviceName ?? widget.Service_Name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: _green, size: 13),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              Icons.layers_rounded,
                              "Service Id",
                              "${photo.providerServiceId ?? '-'}",
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInfoItem(
                              Icons.photo_library_rounded,
                              "Resource Id",
                              "${photo.providerServiceResourcesId ?? '-'}",
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

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(color: _card2, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: _green, size: 13),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _grey, fontSize: 8)),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMAGE LOADING
  // ============================================================

  Widget _buildImageLoading() {
    return Container(
      color: _card2,
      child: const Center(
        child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2.5, color: _green)),
      ),
    );
  }

  // ============================================================
  // IMAGE ERROR
  // ============================================================

  Widget _buildImageError() {
    return Container(
      color: _card2,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.red.withOpacity(.08), shape: BoxShape.circle),
              child: const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 32),
            ),
            const SizedBox(height: 10),
            const Text("Image unavailable", style: TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SKELETON
  // ============================================================

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            flex: 7,
            child: Container(
              color: _card2,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _green)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 13,
                    width: 100,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.06), borderRadius: BorderRadius.circular(5)),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(.04), borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(.04), borderRadius: BorderRadius.circular(8)),
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
    );
  }

  // ============================================================
  // EMPTY STATE — "nothing uploaded yet", shows the real server
  // message when the backend provided one.
  // ============================================================

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _green.withOpacity(.08),
                border: Border.all(color: _green.withOpacity(.15)),
              ),
              child: const Icon(Icons.photo_library_outlined, color: _green, size: 42),
            ),
            const SizedBox(height: 20),
            const Text(
              "No Photos Yet",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _refreshPhotos,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE — genuine failure, shows the real server/network
  // message instead of a generic one.
  // ============================================================

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(.08)),
              child: const Icon(Icons.cloud_off_rounded, color: Colors.white54, size: 42),
            ),
            const SizedBox(height: 20),
            const Text(
              "Unable to Load Photos",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _refreshPhotos,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// ANIMATED PHOTO CARD
// ==================================================================

class _AnimatedPhotoCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedPhotoCard({required this.index, required this.child});

  @override
  State<_AnimatedPhotoCard> createState() => _AnimatedPhotoCardState();
}

class _AnimatedPhotoCardState extends State<_AnimatedPhotoCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, .12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ==================================================================
// FULL SCREEN PHOTO
// ==================================================================

class _FullScreenPhoto extends StatelessWidget {
  final String imageUrl;
  final String serviceName;

  const _FullScreenPhoto({required this.imageUrl, required this.serviceName});

  static const Color green = Color(0xFF00E676);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(.97),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: "fullscreen_$imageUrl",
                child: InteractiveViewer(
                  minScale: .8,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator(color: green));
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 60),
                      );
                    },
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
                  Container(
                    decoration: BoxDecoration(color: Colors.black.withOpacity(.60), shape: BoxShape.circle),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(.60), borderRadius: BorderRadius.circular(14)),
                      child: Text(
                        serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(.60), borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, color: green, size: 17),
                      SizedBox(width: 7),
                      Text("Pinch to zoom", style: TextStyle(color: Colors.white70, fontSize: 11)),
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