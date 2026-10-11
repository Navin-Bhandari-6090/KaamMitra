// =============================================================================
// filter_summary_booking_task_comp_getx.dart
// ANALYSIS controller for FilterSummaryBookingTaskCompPayment screen.
//
// - Server data comes ONLY from the OLD BookProTaskCompGetx (same API methods,
//   same JWT flow). This controller wraps it; no API code is duplicated here.
// - Visualization only: no add / update / delete calls exist in this file.
// - Every derived value is Rx-based, so the UI updates reactively.
// - If BookingInfoModel / ProTaskCompPayInfoModel live in their own files,
//   add their import lines below.
// =============================================================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/AdminTaskCompletePaymentModel.dart';
import '../../../models/BookingInfoModel.dart';
import '../../../models/ProTaskCompPayInfoModel.dart';
import 'book_pro_task_comp_getx.dart';

// -----------------------------------------------------------------------------
// ENUMS
// -----------------------------------------------------------------------------
enum Tri { any, yes, no }

enum SortKey {
  newest,
  oldest,
  bookIdAsc,
  bookIdDesc,
  amountHigh,
  amountLow,
  riskHigh,
}

enum IncomePeriod { weekly, monthly, yearly }

enum RiskLevel { low, medium, high, critical }

enum PartyKind { user, provider }

const List<String> kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

// -----------------------------------------------------------------------------
// HELPERS (pure, never throw)
// -----------------------------------------------------------------------------
String digitsOnly(String? s) => (s ?? '').replaceAll(RegExp(r'\D'), '');

String numText(num? n) {
  if (n == null) return '';
  return n % 1 == 0 ? n.toInt().toString() : n.toString();
}

DateTime? parseDate(String? s) {
  try {
    if (s == null || s.trim().isEmpty) return null;
    return DateTime.tryParse(s.trim())?.toLocal();
  } catch (_) {
    return null;
  }
}

bool triMatch(bool v, Tri t) {
  switch (t) {
    case Tri.any:
      return true;
    case Tri.yes:
      return v;
    case Tri.no:
      return !v;
  }
}

bool _isDomesticMethod(String? m) =>
    (m ?? '').trim().toLowerCase() == 'domestic';

bool _isIntlMethod(String? m) =>
    (m ?? '').trim().toLowerCase().contains('inter');

// -----------------------------------------------------------------------------
// ROW MODELS
// -----------------------------------------------------------------------------

/// One booking (deduplicated by bookId) with all its payments attached.
class BookingRow {
  BookingRow({required this.bookId, required this.info});

  final num bookId;
  final BookingInfoModel info;
  final List<ProTaskCompPayInfoModel> payments = [];

  num? get userNumber => info.userNumber;
  num? get providerNumber => info.providerNumber;

  String get serviceName {
    final s = (info.serviceName ?? '').trim();
    return s.isEmpty ? 'Unknown service' : s;
  }

  DateTime? get createdAt => parseDate(info.createdAt);

  bool get userApproved => info.userApprovalStatus == true;
  bool get providerApproved => info.providerApprovalStatus == true;
  bool get userDone => info.userTaskCompleteStatus == true;
  bool get providerDone => info.providerTaskCompleteStatus == true;

  bool get hasPayment => payments.isNotEmpty;
  bool get fullyCompleted => userDone && providerDone;

  /// Open for 7+ days and not closed by both sides.
  bool get stalled {
    final d = createdAt;
    return !fullyCompleted && d != null && DateTime.now().difference(d).inDays >= 7;
  }

  /// Money logged but job not closed by both sides.
  bool get paidButIncomplete => hasPayment && !fullyCompleted;

  double get paidTotal => payments.fold<double>(
      0.0, (s, p) => s + (p.paymentAmount ?? 0).toDouble());

  bool get contactGap =>
      digitsOnly(info.userPhoneNumber).length < 6 ||
          (info.userEmail ?? '').trim().isEmpty;

  bool get noCoords => info.userLatitude == null || info.userLongitude == null;

  bool get emptyDesc => (info.userBookingDescription ?? '').trim().length < 3;
}

/// One payment record (may be orphan when its booking was deleted).
class PaymentRow {
  PaymentRow({required this.payment, this.booking});

  final ProTaskCompPayInfoModel payment;
  final BookingRow? booking;

  double get amount => (payment.paymentAmount ?? 0).toDouble();
  DateTime? get date => parseDate(payment.paymentDate);
  bool get isDomestic => _isDomesticMethod(payment.paymentMethod);
  bool get isIntl => _isIntlMethod(payment.paymentMethod);
  String get kind => isDomestic ? 'domestic' : (isIntl ? 'international' : 'other');
  String get category => booking?.serviceName ?? 'Unknown service';
}

class RiskFlag {
  const RiskFlag(this.title, this.detail, this.points, {this.severe = false});

  final String title;
  final String detail;
  final int points;

  /// A severe flag alone pushes the party onto the blacklist.
  final bool severe;
}

/// Risk profile for a user number or a provider number.
class RiskProfile {
  RiskProfile({
    required this.kind,
    required this.number,
    required this.rows,
    required this.flags,
    this.email,
    this.phone,
  });

  final PartyKind kind;
  final num number;
  final List<BookingRow> rows;
  final List<RiskFlag> flags;
  final String? email;
  final String? phone;

  int get total => rows.length;

  int get score {
    final s = flags.fold<int>(0, (a, f) => a + f.points);
    return s > 100 ? 100 : s;
  }

  RiskLevel get level {
    final s = score;
    if (s >= 70) return RiskLevel.critical;
    if (s >= 50) return RiskLevel.high;
    if (s >= 30) return RiskLevel.medium;
    return RiskLevel.low;
  }

  bool get blacklisted => score >= 70 || flags.any((f) => f.severe);

  int get stalledCount => rows.where((r) => r.stalled).length;

  double get paidTotal =>
      rows.fold<double>(0.0, (s, r) => s + r.paidTotal);
}

/// Income bucket for weekly / monthly / yearly charts.
class IncomeBucket {
  IncomeBucket({required this.start, required this.label});

  final DateTime start;
  final String label;
  double domestic = 0.0;
  double international = 0.0;
  double other = 0.0;
  int count = 0;

  double get total => domestic + international + other;

  void add(PaymentRow r) {
    final a = r.amount;
    if (r.isDomestic) {
      domestic += a;
    } else if (r.isIntl) {
      international += a;
    } else {
      other += a;
    }
    count++;
  }
}

/// Income per service category (service name).
class CategoryIncome {
  CategoryIncome(this.name);

  final String name;
  double domestic = 0.0;
  double international = 0.0;
  double other = 0.0;
  int count = 0;

  double get total => domestic + international + other;

  void add(PaymentRow r) {
    final a = r.amount;
    if (r.isDomestic) {
      domestic += a;
    } else if (r.isIntl) {
      international += a;
    } else {
      other += a;
    }
    count++;
  }
}

// =============================================================================
// CONTROLLER
// =============================================================================
class FilterSummaryBookingTaskCompPaymentGetx extends GetxController {
  /// OLD controller: owns API calls, JWT, and raw server list.
  final BookProTaskCompGetx src = BookProTaskCompGetx();

  // ---------------- derived reactive data ----------------
  final RxList<BookingRow> bookings = <BookingRow>[].obs;
  final RxList<PaymentRow> payments = <PaymentRow>[].obs;
  final RxList<RiskProfile> userRisks = <RiskProfile>[].obs;
  final RxList<RiskProfile> providerRisks = <RiskProfile>[].obs;

  // ---------------- booking search (each field separate) ----------------
  final TextEditingController bookIdCont = TextEditingController();
  final TextEditingController userCont = TextEditingController();
  final TextEditingController providerCont = TextEditingController();
  final RxString bookIdQ = ''.obs;
  final RxString userQ = ''.obs;
  final RxString providerQ = ''.obs;

  // ---------------- booking filters (tri-state) ----------------
  final Rx<Tri> userApprovedF = Tri.any.obs;
  final Rx<Tri> providerApprovedF = Tri.any.obs;
  final Rx<Tri> userDoneF = Tri.any.obs;
  final Rx<Tri> providerDoneF = Tri.any.obs;
  final Rx<Tri> paymentF = Tri.any.obs;
  final Rx<SortKey> sortKey = SortKey.newest.obs;

  // ---------------- quick finder: last N (1..10) ----------------
  final RxInt quickN = 10.obs;

  // ---------------- income ----------------
  final Rx<IncomePeriod> period = IncomePeriod.monthly.obs;

  // ---------------- risk ----------------
  final Rx<PartyKind> riskKind = PartyKind.user.obs;
  final Rxn<RiskLevel> riskLevelF = Rxn<RiskLevel>();
  final TextEditingController riskCont = TextEditingController();
  final RxString riskQ = ''.obs;

  // ---------------- UI tab ----------------
  final RxInt tab = 0.obs;

  final List<Worker> _workers = [];

  RxBool get isLoading => src.isLoading;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================
  Future<void> init({required String jwtToken}) async {
    try {
      _workers.add(ever(src.adminTaskCompletePaymentList, (_) => _recompute()));
      await src.init(jwtToken: jwtToken);
      _recompute();
    } catch (e) {
      print("FilterSummary init error: $e");
    }
  }

  Future<void> refreshData() async {
    try {
      await src.loadInfo();
    } catch (e) {
      print("FilterSummary refresh error: $e");
    }
  }

  @override
  void onClose() {
    try {
      for (final w in _workers) {
        w.dispose();
      }
      bookIdCont.dispose();
      userCont.dispose();
      providerCont.dispose();
      riskCont.dispose();
      src.onClose();
    } catch (e) {
      print("FilterSummary onClose error: $e");
    }
    super.onClose();
  }

  void resetFilters() {
    try {
      bookIdCont.clear();
      userCont.clear();
      providerCont.clear();
      riskCont.clear();
      bookIdQ.value = '';
      userQ.value = '';
      providerQ.value = '';
      userApprovedF.value = Tri.any;
      providerApprovedF.value = Tri.any;
      userDoneF.value = Tri.any;
      providerDoneF.value = Tri.any;
      paymentF.value = Tri.any;
      sortKey.value = SortKey.newest;
      riskLevelF.value = null;
      riskQ.value = '';
    } catch (e) {
      print("resetFilters error: $e");
    }
  }

  // ===========================================================================
  // BUILD DERIVED DATA (from old controller's raw list)
  // ===========================================================================
  void _recompute() {
    try {
      final raw = src.adminTaskCompletePaymentList;

      // Pass 1: every booking exactly once.
      final Map<num, BookingRow> map = {};
      for (final m in raw) {
        final info = m.bookingInfo;
        final id = info?.bookId;
        if (info != null && id != null && !map.containsKey(id)) {
          map[id] = BookingRow(bookId: id, info: info);
        }
      }

      // Pass 2: attach payments once each (dedupe by payment id).
      final Set<num> seenPay = {};
      final List<PaymentRow> pays = [];
      for (final m in raw) {
        final pay = m.paymentInfo;
        if (pay == null) continue;
        final pid = pay.taskCompletePaymentId;
        if (pid != null && !seenPay.add(pid)) continue;
        final link = map[pay.bookId ?? m.bookingInfo?.bookId];
        link?.payments.add(pay);
        pays.add(PaymentRow(payment: pay, booking: link));
      }

      final bookingList = map.values.toList();
      bookings.assignAll(bookingList);
      payments.assignAll(pays);
      userRisks.assignAll(_buildUserRisks(bookingList));
      providerRisks.assignAll(_buildProviderRisks(bookingList));
    } catch (e) {
      print("FilterSummary recompute error: $e");
    }
  }

  // ===========================================================================
  // FAKE USER / BLACKLIST ENGINE
  // Points per signal, score capped at 100.
  // Level: 30 medium, 50 high, 70 critical.
  // Blacklist: score >= 70 OR any severe signal.
  // ===========================================================================
  List<RiskProfile> _buildUserRisks(List<BookingRow> all) {
    try {
      final Map<num, List<BookingRow>> groups = {};
      for (final r in all) {
        final k = r.userNumber;
        if (k == null) continue;
        groups.putIfAbsent(k, () => <BookingRow>[]).add(r);
      }

      // Phone -> set of user numbers using it (shared-phone detection).
      final Map<String, Set<num>> phoneOwners = {};
      for (final r in all) {
        final ph = digitsOnly(r.info.userPhoneNumber);
        final u = r.userNumber;
        if (ph.length >= 6 && u != null) {
          phoneOwners.putIfAbsent(ph, () => <num>{}).add(u);
        }
      }
      final sharedKeys = phoneOwners.entries
          .where((e) => e.value.length > 1)
          .map((e) => e.key)
          .toSet();

      final List<RiskProfile> out = [];
      groups.forEach((num number, List<BookingRow> rows) {
        final flags = <RiskFlag>[];

        final never = rows.where((r) => !r.userApproved && !r.providerApproved).length;
        if (never >= 2) {
          flags.add(RiskFlag(
            'Never approved',
            '$never booking(s) with no approval from either side',
            never >= 5 ? 30 : 15,
            severe: never >= 5,
          ));
        }

        final userNoShow = rows
            .where((r) => r.providerApproved && !r.userDone && r.stalled)
            .length;
        if (userNoShow >= 2) {
          flags.add(RiskFlag(
            'User never completes',
            '$userNoShow approved job(s) left open by the user',
            20,
          ));
        }

        final providerIgnores =
            rows.where((r) => r.userApproved && !r.providerApproved).length;
        if (providerIgnores >= 2) {
          flags.add(RiskFlag(
            'Provider ignores user',
            '$providerIgnores booking(s) approved by user but not by provider',
            10,
          ));
        }

        final staleUnpaid = rows.where((r) => r.stalled && !r.hasPayment).length;
        if (staleUnpaid >= 3) {
          flags.add(RiskFlag(
            'Stale unpaid bookings',
            '$staleUnpaid booking(s) open 7+ days with no payment',
            15,
          ));
        }

        final Map<String, int> perDay = {};
        for (final r in rows) {
          final d = r.createdAt;
          if (d == null) continue;
          final k = '${d.year}-${d.month}-${d.day}';
          perDay[k] = (perDay[k] ?? 0) + 1;
        }
        final burst = perDay.values.fold<int>(0, (m, v) => v > m ? v : m);
        if (burst >= 3) {
          flags.add(RiskFlag(
            'Booking burst',
            'Up to $burst bookings created in a single day',
            15,
          ));
        }

        final sharedPhone = rows.any((r) =>
            sharedKeys.contains(digitsOnly(r.info.userPhoneNumber)));
        if (sharedPhone) {
          flags.add(RiskFlag(
            'Shared phone number',
            'Same phone number linked to multiple user accounts',
            25,
            severe: true,
          ));
        }

        final gaps = rows.where((r) => r.contactGap).length;
        if (gaps > 0 && gaps * 2 >= rows.length) {
          flags.add(RiskFlag(
            'Incomplete contact',
            'Phone or email missing on most bookings',
            10,
          ));
        }

        final noCoords = rows.where((r) => r.noCoords).length;
        if (noCoords >= 2 && noCoords * 2 >= rows.length) {
          flags.add(RiskFlag(
            'No location data',
            'Coordinates missing on most bookings',
            8,
          ));
        }

        final emptyDesc = rows.where((r) => r.emptyDesc).length;
        if (emptyDesc >= 2 && emptyDesc * 2 >= rows.length) {
          flags.add(RiskFlag(
            'Empty descriptions',
            'Booking descriptions are blank or too short',
            5,
          ));
        }

        final first = rows.first.info;
        out.add(RiskProfile(
          kind: PartyKind.user,
          number: number,
          rows: rows,
          flags: flags,
          email: first.userEmail,
          phone: first.userPhoneNumber,
        ));
      });

      out.sort((a, b) => b.score.compareTo(a.score));
      return out;
    } catch (e) {
      print("buildUserRisks error: $e");
      return [];
    }
  }

  List<RiskProfile> _buildProviderRisks(List<BookingRow> all) {
    try {
      final Map<num, List<BookingRow>> groups = {};
      for (final r in all) {
        final k = r.providerNumber;
        if (k == null) continue;
        groups.putIfAbsent(k, () => <BookingRow>[]).add(r);
      }

      final List<RiskProfile> out = [];
      groups.forEach((num number, List<BookingRow> rows) {
        final flags = <RiskFlag>[];

        final ignored = rows.where((r) => !r.providerApproved).length;
        if (ignored >= 2) {
          flags.add(RiskFlag(
            'Ignores booking requests',
            '$ignored booking(s) never approved by provider',
            ignored >= 5 ? 25 : 15,
            severe: ignored >= 5,
          ));
        }

        final noFinish = rows.where((r) => r.userDone && !r.providerDone).length;
        if (noFinish >= 2) {
          flags.add(RiskFlag(
            'Does not close after user confirms',
            '$noFinish job(s) confirmed by user but not closed by provider',
            noFinish >= 4 ? 30 : 20,
            severe: noFinish >= 4,
          ));
        }

        final doneNoPay = rows.where((r) => r.providerDone && !r.hasPayment).length;
        if (doneNoPay >= 1) {
          flags.add(RiskFlag(
            'Completed without payment',
            '$doneNoPay job(s) closed with no payment logged',
            doneNoPay >= 3 ? 25 : 10,
          ));
        }

        final stale = rows.where((r) => r.stalled).length;
        if (stale >= 3) {
          flags.add(RiskFlag(
            'Stale bookings',
            '$stale booking(s) open 7+ days',
            20,
          ));
        }

        final paidOpen = rows.where((r) => r.paidButIncomplete).length;
        if (paidOpen >= 2) {
          flags.add(RiskFlag(
            'Paid but not closed',
            '$paidOpen payment(s) logged on jobs not closed by both sides',
            15,
          ));
        }

        final badPhone = rows.any(
                (r) => digitsOnly(r.info.providerPhoneNumber).length < 6);
        if (badPhone) {
          flags.add(RiskFlag(
            'Missing provider phone',
            'Contact number missing or invalid',
            10,
          ));
        }

        final first = rows.first.info;
        out.add(RiskProfile(
          kind: PartyKind.provider,
          number: number,
          rows: rows,
          flags: flags,
          email: first.providerEmail,
          phone: first.providerPhoneNumber,
        ));
      });

      out.sort((a, b) => b.score.compareTo(a.score));
      return out;
    } catch (e) {
      print("buildProviderRisks error: $e");
      return [];
    }
  }

  // ===========================================================================
  // BOOKING SEARCH / FILTER / SORT / QUICK FINDER
  // ===========================================================================
  int _rowRisk(BookingRow r) {
    int s = 0;
    if (r.stalled) s += 30;
    if (r.paidButIncomplete) s += 25;
    if (!r.userApproved && !r.providerApproved) s += 20;
    if (r.contactGap) s += 10;
    if (r.emptyDesc) s += 5;
    return s;
  }

  void _sortList(List<BookingRow> l, SortKey k) {
    DateTime d(BookingRow r) => r.createdAt ?? DateTime(1970);
    switch (k) {
      case SortKey.newest:
        l.sort((a, b) => d(b).compareTo(d(a)));
        break;
      case SortKey.oldest:
        l.sort((a, b) => d(a).compareTo(d(b)));
        break;
      case SortKey.bookIdAsc:
        l.sort((a, b) => a.bookId.compareTo(b.bookId));
        break;
      case SortKey.bookIdDesc:
        l.sort((a, b) => b.bookId.compareTo(a.bookId));
        break;
      case SortKey.amountHigh:
        l.sort((a, b) => b.paidTotal.compareTo(a.paidTotal));
        break;
      case SortKey.amountLow:
        l.sort((a, b) => a.paidTotal.compareTo(b.paidTotal));
        break;
      case SortKey.riskHigh:
        l.sort((a, b) => _rowRisk(b).compareTo(_rowRisk(a)));
        break;
    }
  }

  List<BookingRow> get filteredBookings {
    try {
      final bq = bookIdQ.value.trim();
      final uq = userQ.value.trim();
      final pq = providerQ.value.trim();
      final out = bookings.where((r) {
        if (bq.isNotEmpty && !numText(r.bookId).contains(bq)) return false;
        if (uq.isNotEmpty && !numText(r.userNumber).contains(uq)) return false;
        if (pq.isNotEmpty && !numText(r.providerNumber).contains(pq)) return false;
        if (!triMatch(r.userApproved, userApprovedF.value)) return false;
        if (!triMatch(r.providerApproved, providerApprovedF.value)) return false;
        if (!triMatch(r.userDone, userDoneF.value)) return false;
        if (!triMatch(r.providerDone, providerDoneF.value)) return false;
        if (!triMatch(r.hasPayment, paymentF.value)) return false;
        return true;
      }).toList();
      _sortList(out, sortKey.value);
      return out;
    } catch (e) {
      print("filteredBookings error: $e");
      return [];
    }
  }

  /// Last N bookings (N = 1..10) where provider approved AND no payment logged.
  List<BookingRow> get quickFinder {
    try {
      final list = bookings
          .where((r) => r.providerApproved && !r.hasPayment)
          .toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(1970))
            .compareTo(a.createdAt ?? DateTime(1970)));
      int n = quickN.value;
      if (n < 1) n = 1;
      if (n > 10) n = 10;
      return list.take(n).toList();
    } catch (e) {
      print("quickFinder error: $e");
      return [];
    }
  }

  BookingRow? bookingById(num id) {
    for (final r in bookings) {
      if (r.bookId == id) return r;
    }
    return null;
  }

  int userScoreOf(num? n) {
    if (n == null) return 0;
    for (final r in userRisks) {
      if (r.number == n) return r.score;
    }
    return 0;
  }

  // ===========================================================================
  // RISK FILTER
  // ===========================================================================
  List<RiskProfile> get filteredRisks {
    try {
      final base = riskKind.value == PartyKind.user ? userRisks : providerRisks;
      final q = riskQ.value.trim();
      final lv = riskLevelF.value;
      return base.where((r) {
        if (lv != null && r.level != lv) return false;
        if (q.isNotEmpty && !numText(r.number).contains(q)) return false;
        return true;
      }).toList();
    } catch (e) {
      print("filteredRisks error: $e");
      return [];
    }
  }

  // ===========================================================================
  // INCOME ANALYTICS
  // ===========================================================================
  DateTime _keyOf(DateTime d, IncomePeriod p) {
    switch (p) {
      case IncomePeriod.weekly:
        {
          final day = DateTime(d.year, d.month, d.day);
          return day.subtract(Duration(days: day.weekday - 1));
        }
      case IncomePeriod.monthly:
        return DateTime(d.year, d.month);
      case IncomePeriod.yearly:
        return DateTime(d.year);
    }
  }

  String _label(DateTime k, IncomePeriod p) {
    switch (p) {
      case IncomePeriod.weekly:
        return '${k.day.toString().padLeft(2, '0')} ${kMonths[k.month - 1]}';
      case IncomePeriod.monthly:
        return '${kMonths[k.month - 1]} ${k.year % 100}';
      case IncomePeriod.yearly:
        return '${k.year}';
    }
  }

  /// Weekly: last 12 weeks. Monthly: last 12 months. Yearly: all years.
  List<IncomeBucket> incomeBuckets() {
    try {
      final p = period.value;
      final now = DateTime.now();
      final Map<DateTime, IncomeBucket> m = {};

      if (p == IncomePeriod.weekly) {
        final start = _keyOf(now, p);
        for (int i = 11; i >= 0; i--) {
          final k = DateTime(start.year, start.month, start.day - 7 * i);
          m[k] = IncomeBucket(start: k, label: _label(k, p));
        }
      } else if (p == IncomePeriod.monthly) {
        for (int i = 11; i >= 0; i--) {
          final k = DateTime(now.year, now.month - i);
          m[k] = IncomeBucket(start: k, label: _label(k, p));
        }
      } else {
        int first = now.year - 4;
        for (final r in payments) {
          final d = r.date;
          if (d != null && d.year < first) first = d.year;
        }
        for (int y = first; y <= now.year; y++) {
          final k = DateTime(y);
          m[k] = IncomeBucket(start: k, label: _label(k, p));
        }
      }

      for (final r in payments) {
        final d = r.date;
        if (d == null) continue;
        final b = m[_keyOf(d, p)];
        if (b == null) continue;
        b.add(r);
      }

      final list = m.values.toList()..sort((a, b) => a.start.compareTo(b.start));
      return list;
    } catch (e) {
      print("incomeBuckets error: $e");
      return [];
    }
  }

  List<CategoryIncome> categoryBreakdown() {
    try {
      final Map<String, CategoryIncome> m = {};
      for (final r in payments) {
        m.putIfAbsent(r.category, () => CategoryIncome(r.category)).add(r);
      }
      return m.values.toList()..sort((a, b) => b.total.compareTo(a.total));
    } catch (e) {
      print("categoryBreakdown error: $e");
      return [];
    }
  }

  // ===========================================================================
  // OVERVIEW STATS (all reactive through the Rx lists they read)
  // ===========================================================================
  int get totalBookings => bookings.length;
  int get totalPayments => payments.length;

  double get totalRevenue =>
      payments.fold<double>(0.0, (s, p) => s + p.amount);

  double _sumKind(String k) => payments
      .where((p) => p.kind == k)
      .fold<double>(0.0, (s, p) => s + p.amount);

  double get domesticRevenue => _sumKind('domestic');
  double get intlRevenue => _sumKind('international');
  double get otherRevenue => _sumKind('other');

  double get avgPayment => totalPayments == 0 ? 0.0 : totalRevenue / totalPayments;

  int get fullyCompletedCount => bookings.where((r) => r.fullyCompleted).length;

  double get completionRate =>
      totalBookings == 0 ? 0.0 : fullyCompletedCount / totalBookings;

  int get stalledCount => bookings.where((r) => r.stalled).length;
  int get paidIncompleteCount => bookings.where((r) => r.paidButIncomplete).length;
  int get bookingsWithoutPayment => bookings.where((r) => !r.hasPayment).length;
  int get orphanPaymentCount => payments.where((p) => p.booking == null).length;

  int get blacklistedUsers => userRisks.where((r) => r.blacklisted).length;
  int get blacklistedProviders => providerRisks.where((r) => r.blacklisted).length;
  int get highRiskUsers => userRisks.where((r) => r.level == RiskLevel.high || r.level == RiskLevel.critical).length;
  int get highRiskProviders => providerRisks.where((r) => r.level == RiskLevel.high || r.level == RiskLevel.critical).length;
}