import 'package:app/web/footer/Footer.dart';
import 'package:app/web/header/Header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constant/Server_Database.dart';
import '../../state management/getx/services/service_screen_getx.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/design/bolbs_background.dart';
import '../common widget/toast.dart';
import 'select_service_provider_info_screen.dart';

// ---------------------------------------------------------------------------
// THEME TOKENS (dark green) — matches Header.dart / ProviderProfile.dart
// ---------------------------------------------------------------------------
class _Theme {
  static const Color bgTop = Color(0xFF0F1F17);
  static const Color bgMid = Color(0xFF12261C);
  static const Color bgBottom = Color(0xFF0A160F);

  static const Color surface = Color(0xFF162E22);
  static const Color surfaceBar = Color(0xFF12261C);

  static const Color primaryText = Color(0xFFE6F4EA);
  static const Color mutedText = Color(0xFF9AA0A6);
  static const Color mutedTextAlt = Color(0xFF8A9A90);

  static const Color emerald = Color(0xFF22C55E);
  static const Color mint = Color(0xFF34D399);
  static const Color danger = Color(0xFFF87171);

  static const Color border = Color(0xFF234232);
}

class ServicesScreen extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;

  const ServicesScreen({
    super.key,
    required this.User_Email,
    required this.User_JwtToken,
    required this.User_Role,
  });

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen>
    with SingleTickerProviderStateMixin {
  // GetX controller — owns all state and all API calls.
  final ServiceScreenGetx serviceCont = Get.put(ServiceScreenGetx());

  final TextEditingController SearchCont = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Entrance animation (UI only)
  late final AnimationController _entranceController;
  late final Animation<double> _heroAnim;
  late final Animation<double> _searchAnim;
  late final Animation<double> _listAnim;
  late final Animation<double> _footerAnim;

  @override
  void initState() {
    super.initState();

    try {
      Provider_User_Jwt_Verify(
        Jwt_Token: widget.User_JwtToken,
        context: context,
      );
    } catch (e) {
      debugPrint("Session verify failed: $e");
    }

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _heroAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _searchAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.70, curve: Curves.easeOutCubic),
    );
    _listAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.30, 0.85, curve: Curves.easeOutCubic),
    );
    _footerAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    );
    _entranceController.forward();

    _searchFocusNode.addListener(() {
      serviceCont.setSearchFocused(_searchFocusNode.hasFocus);
    });

    _loadEverything();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _searchFocusNode.dispose();
    SearchCont.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD + NAVIGATION (the screen only forwards to the controller)
  // ============================================================

  Future<void> _loadEverything() {
    return serviceCont.loadEverything(
      email: widget.User_Email,
      jwtToken: widget.User_JwtToken,
      context: context,
    );
  }

  void _onCardTap(
      CombinedServiceCard card, {
        required String ProviderEmail,
        required String ServiceName,
        required num ProviderNumber,
        required num ServiceId,
        required String ProRegServiceDescription,
      }) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectServiceProviderInfoScreen(
            Current_User_Email: widget.User_Email,
            Current_User_JwtToken: widget.User_JwtToken,
            Current_User_Role: widget.User_Role,
            Distance: card.distanceKm,
            Rating: card.rating,
            Provider_User_Email: ProviderEmail,
            Service_info_List: serviceCont.serviceInfoList,
            Provider_info_List: serviceCont.providerInfoList,
            Provider_Service_Name: ServiceName,
            Providernumber: ProviderNumber,
            ServiceId: ServiceId,
            ProRegServiceDescription: ProRegServiceDescription,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Open provider failed: $e");
      Toastget().Toastmsg("Could not open this provider. Please try again.");
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;

    final double hPad =
    width < 420 ? 14 : (isMobile ? 20 : (width < 1100 ? 32 : 48));
    final bool canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: _Theme.bgTop,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_Theme.bgTop, _Theme.bgMid, _Theme.bgBottom],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Ambient blobs — full width and height, behind content.
          const AmbientBackground(),

          SafeArea(
            child: RefreshIndicator(
              color: _Theme.emerald,
              backgroundColor: _Theme.surface,
              onRefresh: _loadEverything,
              child: LayoutBuilder(
                builder: (context, outer) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: outer.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Header(
                                UserLogin: true,
                                User_JwtToken: widget.User_JwtToken,
                              ),
                              Center(
                                child: ConstrainedBox(
                                  constraints:
                                  const BoxConstraints(maxWidth: 1180),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      hPad,
                                      isMobile ? 20 : 32,
                                      hPad,
                                      24,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        _buildTopBar(canPop),
                                        SizedBox(height: isMobile ? 20 : 26),
                                        _animatedSection(
                                          animation: _heroAnim,
                                          child: _buildHero(isMobile),
                                        ),
                                        SizedBox(height: isMobile ? 18 : 24),
                                        _animatedSection(
                                          animation: _searchAnim,
                                          child: _buildSearchCard(isMobile),
                                        ),
                                        SizedBox(height: isMobile ? 18 : 24),
                                        _animatedSection(
                                          animation: _listAnim,
                                          child: _buildResults(),
                                        ),
                                        SizedBox(height: isMobile ? 28 : 40),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _animatedSection(
                            animation: _footerAnim,
                            child: Footer(User_JwtToken: widget.User_JwtToken),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SHARED STYLE HELPERS
  // ============================================================

  BoxDecoration _cardDecoration({double radius = 22, bool elevated = true}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF193A29), Color(0xFF12261C), Color(0xFF101F18)],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _Theme.border),
      boxShadow: elevated
          ? [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ]
          : null,
    );
  }

  Widget _animatedSection({
    required Animation<double> animation,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, builtChild) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 22),
            child: builtChild,
          ),
        );
      },
      child: child,
    );
  }

  /// Bordered icon button with a primary-coloured icon.
  Widget _borderedIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final Widget button = Material(
      color: _Theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: _Theme.emerald.withOpacity(0.55),
          width: 1.4,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: _Theme.primaryText, size: 20),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  // ============================================================
  // TOP BAR — bordered back arrow + title + refresh
  // ============================================================

  Widget _buildTopBar(bool canPop) {
    return Row(
      children: [
        if (canPop) ...[
          _borderedIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.maybePop(context),
            tooltip: "Back",
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Services",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _Theme.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                textOrNoData(widget.User_Email),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _Theme.mutedTextAlt,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _borderedIconButton(
          icon: Icons.refresh_rounded,
          onTap: () => _loadEverything(),
          tooltip: "Refresh",
        ),
      ],
    );
  }

  // ============================================================
  // HERO — title + live counts (reactive)
  // ============================================================

  Widget _buildHero(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: _cardDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _Theme.emerald.withOpacity(0.10),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: _Theme.emerald.withOpacity(0.25)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: _Theme.mint, size: 14),
                SizedBox(width: 7),
                Flexible(
                  child: Text(
                    "Verified providers",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _Theme.mint,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Find a trusted provider",
            style: TextStyle(
              color: _Theme.primaryText,
              fontSize: isMobile ? 24 : 30,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Search by service name or provider ID, then sort by distance "
                "or rating to find the best match near you.",
            style: TextStyle(
              color: _Theme.mutedText,
              fontSize: isMobile ? 13 : 14.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 20),
          Obx(() {
            int serviceCount = 0;
            int providerCount = 0;
            try {
              serviceCount = serviceCont.allCards.length;
              providerCount = serviceCont.allCards
                  .map((c) => c.service.userNumber)
                  .where((n) => n != null)
                  .toSet()
                  .length;
            } catch (_) {}
            return Row(
              children: [
                Expanded(
                  child: _heroStat(
                    icon: Icons.design_services_rounded,
                    value: "$serviceCount",
                    label: "Services",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _heroStat(
                    icon: Icons.groups_rounded,
                    value: "$providerCount",
                    label: "Providers",
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _heroStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _Theme.surfaceBar,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Theme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _Theme.emerald.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _Theme.mint, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: _Theme.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: _Theme.mutedTextAlt,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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
  // SEARCH + SORT
  // ============================================================

  Widget _buildSearchCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 22),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
                () => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _Theme.surfaceBar,
                border: Border.all(
                  color: serviceCont.isSearchFocused.value
                      ? _Theme.emerald.withOpacity(0.55)
                      : _Theme.border,
                  width: 1.4,
                ),
                boxShadow: serviceCont.isSearchFocused.value
                    ? [
                  BoxShadow(
                    color: _Theme.emerald.withOpacity(0.15),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
                    : const [],
              ),
              child: TextField(
                controller: SearchCont,
                focusNode: _searchFocusNode,
                style: const TextStyle(
                  color: _Theme.primaryText,
                  fontSize: 14,
                ),
                onChanged: (value) => serviceCont.changeSearchText(value),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  hintText: "Search service name or provider ID (#)",
                  hintMaxLines: 1,
                  hintStyle: const TextStyle(
                    color: _Theme.mutedTextAlt,
                    fontSize: 13,
                    overflow: TextOverflow.ellipsis,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _Theme.mint,
                    size: 20,
                  ),
                  suffixIcon: Obx(
                        () => serviceCont.searchText.value.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: _Theme.mutedTextAlt,
                        size: 18,
                      ),
                      onPressed: () {
                        SearchCont.clear();
                        serviceCont.changeSearchText("");
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: _Theme.mutedTextAlt, size: 15),
              SizedBox(width: 6),
              Text(
                "Sort by",
                style: TextStyle(
                  color: _Theme.mutedTextAlt,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _Theme.surfaceBar,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _Theme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _sortSegment(
                    label: "Nearest",
                    icon: Icons.near_me_rounded,
                    mode: ServiceSortMode.distance,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _sortSegment(
                    label: "Top rated",
                    icon: Icons.star_rounded,
                    mode: ServiceSortMode.rating,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortSegment({
    required String label,
    required IconData icon,
    required ServiceSortMode mode,
  }) {
    return Obx(() {
      final bool selected = serviceCont.sortMode.value == mode;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => serviceCont.changeSortMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: selected
                  ? const LinearGradient(colors: [_Theme.emerald, _Theme.mint])
                  : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: selected ? _Theme.bgTop : _Theme.mutedTextAlt,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? _Theme.bgTop : _Theme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ============================================================
  // RESULTS — reactive to loading, error, empty, and data
  // ============================================================

  Widget _buildResults() {
    return Obx(() {
      if (serviceCont.isLoading.value) {
        return _stateShell(
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  color: _Theme.emerald,
                  strokeWidth: 2.6,
                ),
              ),
              SizedBox(height: 14),
              Text(
                "Loading services...",
                style: TextStyle(
                  color: _Theme.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }

      if (serviceCont.hasLoadError.value) {
        return _stateShell(
          child: _stateContent(
            icon: Icons.error_outline_rounded,
            title: "Couldn't load services",
            message: "Check your connection and try again.",
            action: ElevatedButton.icon(
              onPressed: () => _loadEverything(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Try again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Theme.emerald,
                foregroundColor: _Theme.bgTop,
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      }

      final List<CombinedServiceCard> cards = serviceCont.displayedCards;

      if (cards.isEmpty) {
        final bool searching = serviceCont.searchText.value.trim().isNotEmpty;
        return _stateShell(
          child: _stateContent(
            icon: searching ? Icons.search_off_rounded : Icons.inbox_rounded,
            title: searching ? "No matches found" : "No providers yet",
            message: searching
                ? "Try a different service name or provider number."
                : "Check back soon. New providers appear here.",
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              "${cards.length} provider${cards.length == 1 ? '' : 's'} found",
              style: const TextStyle(
                color: _Theme.mutedTextAlt,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _cardsGrid(cards),
        ],
      );
    });
  }

  Widget _cardsGrid(List<CombinedServiceCard> cards) {
    return LayoutBuilder(
      builder: (context, box) {
        final double maxW = box.maxWidth;
        final int columns = maxW >= 1000 ? 3 : (maxW >= 640 ? 2 : 1);
        const double gap = 16;
        final double cardW =
        ((maxW - gap * (columns - 1)) / columns).clamp(0.0, maxW);

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (int i = 0; i < cards.length; i++)
              SizedBox(width: cardW, child: _providerCard(cards[i], i)),
          ],
        );
      },
    );
  }

  Widget _stateShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: _Theme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Theme.border),
      ),
      child: Center(child: child),
    );
  }

  Widget _stateContent({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _Theme.surfaceBar,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _Theme.border),
          ),
          child: Icon(icon, color: _Theme.mint, size: 28),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _Theme.primaryText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _Theme.mutedText,
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 18),
          action,
        ],
      ],
    );
  }

  // ============================================================
  // PROVIDER CARD
  // ============================================================

  String _clean(String? v) {
    final String t = (v ?? '').trim();
    return (t.isEmpty || t.toLowerCase() == 'null') ? '' : t;
  }

  String _buildPhotoUrl(String? path) {
    try {
      final String p = (path ?? '').trim();
      if (p.isEmpty || p.toLowerCase() == 'null') return '';
      if (p.startsWith('http://') || p.startsWith('https://')) return p;
      final String base = Backend_Server_Url.replaceFirst(RegExp(r'/$'), '');
      return p.startsWith('/') ? '$base$p' : '$base/$p';
    } catch (_) {
      return '';
    }
  }

  Widget _providerAvatar(String? photoPath, {required double size}) {
    final String url = _buildPhotoUrl(photoPath);
    final double inner = size - 4;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(
          colors: [_Theme.emerald, _Theme.mint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3 - 2),
        child: url.isEmpty
            ? _avatarFallback(inner)
            : Image.network(
          url,
          width: inner,
          height: inner,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) => progress == null
              ? child
              : _avatarFallback(inner, loading: true),
          errorBuilder: (ctx, e, st) => _avatarFallback(inner),
        ),
      ),
    );
  }

  Widget _avatarFallback(double size, {bool loading = false}) {
    return Container(
      width: size,
      height: size,
      color: _Theme.surfaceBar,
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
        width: size * 0.35,
        height: size * 0.35,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: _Theme.mint,
        ),
      )
          : Icon(Icons.person_rounded, color: _Theme.mint, size: size * 0.45),
    );
  }

  Widget _statusChip(bool? status) {
    final bool missing = status == null;
    final Color color =
    missing ? _Theme.mutedText : (status ? _Theme.danger : _Theme.emerald);
    final String label =
    missing ? kNoData : (status ? "Reserved" : "Available");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final bool missing = value == kNoData;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: _Theme.surfaceBar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: _Theme.mint),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _Theme.mutedTextAlt,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: missing ? _Theme.mutedText : _Theme.primaryText,
              fontSize: missing ? 11 : 13,
              height: 1.2,
              fontWeight: FontWeight.w800,
              fontStyle: missing ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _providerCard(CombinedServiceCard card, int index) {
    final provider = card.provider;

    final String serviceName = _clean(card.service.serviceName);
    final String description = _clean(card.service.proRegServiceDescription);
    final String providerName = [
      _clean(provider?.firstName),
      _clean(provider?.lastName),
    ].where((e) => e.isNotEmpty).join(' ');
    final String providerEmail = _clean(provider?.email);

    final num? userNumber = card.service.userNumber;
    final num? serviceId = card.service.providerServiceId;
    final bool? status = provider?.status;

    final bool canOpen =
        userNumber != null && serviceId != null && providerEmail.isNotEmpty;

    final double avatarSize = MediaQuery.sizeOf(context).width >= 700 ? 60 : 54;

    return Obx(() {
      final bool hovered = serviceCont.hoveredCardIndex.value == index;
      final bool pressed = serviceCont.pressedCardIndex.value == index;

      return MouseRegion(
        onEnter: (_) => serviceCont.setHoveredCard(index),
        onExit: (_) => serviceCont.clearHoveredCard(),
        cursor: canOpen ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: canOpen ? (_) => serviceCont.setPressedCard(index) : null,
          onTapCancel: () => serviceCont.clearPressedCard(),
          onTapUp: (_) => serviceCont.clearPressedCard(),
          onTap: !canOpen
              ? null
              : () => _onCardTap(
            card,
            ServiceName: serviceName,
            ProviderNumber: userNumber,
            ServiceId: serviceId,
            ProRegServiceDescription: description,
            ProviderEmail: providerEmail,
          ),
          child: AnimatedScale(
            scale: pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _Theme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hovered
                      ? _Theme.emerald.withOpacity(0.55)
                      : _Theme.border,
                  width: hovered ? 1.3 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: hovered
                        ? _Theme.emerald.withOpacity(0.16)
                        : Colors.black.withOpacity(0.12),
                    blurRadius: hovered ? 24 : 12,
                    offset: Offset(0, hovered ? 10 : 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- header ----------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _providerAvatar(provider?.photo, size: avatarSize),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              serviceName.isEmpty ? kNoData : serviceName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: serviceName.isEmpty
                                    ? _Theme.mutedText
                                    : _Theme.primaryText,
                                fontSize: 16,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                fontStyle: serviceName.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.person_rounded,
                                    size: 13, color: _Theme.mutedTextAlt),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    providerName.isEmpty
                                        ? kNoData
                                        : providerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: providerName.isEmpty
                                          ? _Theme.mutedText
                                          : _Theme.mutedTextAlt,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: providerName.isEmpty
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _statusChip(status),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ---------- description ----------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _Theme.surfaceBar,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _Theme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notes_rounded,
                                size: 13, color: _Theme.mint),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "SERVICE DESCRIPTION",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _Theme.mutedTextAlt,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description.isEmpty ? kNoData : description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: description.isEmpty
                                ? _Theme.mutedText
                                : _Theme.primaryText,
                            fontSize: 13,
                            height: 1.5,
                            fontStyle: description.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ---------- metrics ----------
                  Row(
                    children: [
                      Expanded(
                        child: _metricTile(
                          icon: Icons.badge_rounded,
                          label: "Provider",
                          value: userNumber == null
                              ? kNoData
                              : "#${userNumber.toInt()}",
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metricTile(
                          icon: Icons.location_on_rounded,
                          label: "Distance",
                          value: card.hasLocation
                              ? "${card.distanceKm.toStringAsFixed(1)} km"
                              : kNoData,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metricTile(
                          icon: Icons.star_rounded,
                          label: "Rating",
                          value: card.rating > 0
                              ? card.rating.toStringAsFixed(1)
                              : "New",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ---------- call to action ----------
                  Row(
                    children: [
                      Expanded(
                        child: canOpen
                            ? const SizedBox.shrink()
                            : const Text(
                          "Profile incomplete",
                          style: TextStyle(
                            color: _Theme.mutedText,
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      if (canOpen)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_fill_rounded,
                                color: _Theme.mint, size: 16),
                            SizedBox(width: 5),
                            Text(
                              "Start work",
                              style: TextStyle(
                                color: _Theme.mint,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded,
                                color: _Theme.mint, size: 14),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}