import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/BookingInfoModel.dart';
import '../../../models/ProTaskCompPayInfoModel.dart';
import 'book_pro_task_comp_getx.dart';

const String kNoData = 'No data available';

const List<String> kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

enum Tri { any, yes, no }

enum SortKey { newest, oldest, bookIdAsc, bookIdDesc, amountHigh, amountLow, riskHigh }

enum RiskLevel { low, medium, high, critical }

enum PartyKind { user, provider }

enum RiskView { fakeUsers, providerNotApproved, providerNotCompleted }

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

bool _isDomesticMethod(String? m) => (m ?? '').trim().toLowerCase() == 'domestic';

bool _isIntlMethod(String? m) => (m ?? '').trim().toLowerCase().contains('inter');

List<num> idsOf(Iterable<BookingRow> rows) => rows.map((r) => r.bookId).toList();

class BookingRow {
  BookingRow({required this.bookId, required this.info});

  final num bookId;
  final BookingInfoModel info;
  final List<ProTaskCompPayInfoModel> payments = [];

  num? get userNumber => info.userNumber;
  num? get providerNumber => info.providerNumber;

  String get serviceName {
    final s = (info.serviceName ?? '').trim();
    return s.isEmpty ? kNoData : s;
  }

  DateTime? get createdAt => parseDate(info.createdAt);

  bool get userApproved => info.userApprovalStatus == true;
  bool get providerApproved => info.providerApprovalStatus == true;
  bool get userDone => info.userTaskCompleteStatus == true;
  bool get providerDone => info.providerTaskCompleteStatus == true;

  bool get hasPayment => payments.isNotEmpty;
  bool get fullyCompleted => userDone && providerDone;

  int get daysOpen {
    final d = createdAt;
    return d == null ? 0 : DateTime.now().difference(d).inDays;
  }

  bool get stalled => !fullyCompleted && daysOpen >= 7;

  bool get paidButIncomplete => hasPayment && !fullyCompleted;

  double get paidTotal =>
      payments.fold<double>(0.0, (s, p) => s + (p.paymentAmount ?? 0).toDouble());

  bool get contactGap =>
      digitsOnly(info.userPhoneNumber).length < 6 ||
          (info.userEmail ?? '').trim().isEmpty;

  bool get noCoords => info.userLatitude == null || info.userLongitude == null;

  bool get emptyDesc => (info.userBookingDescription ?? '').trim().length < 3;
}

class PaymentRow {
  PaymentRow({required this.payment, this.booking});

  final ProTaskCompPayInfoModel payment;
  final BookingRow? booking;

  double get amount => (payment.paymentAmount ?? 0).toDouble();
  DateTime? get date => parseDate(payment.paymentDate);
  bool get isDomestic => _isDomesticMethod(payment.paymentMethod);
  bool get isIntl => _isIntlMethod(payment.paymentMethod);
  String get category => booking?.serviceName ?? kNoData;
}

class RiskFlag {
  const RiskFlag(
      this.title,
      this.detail,
      this.points, {
        this.severe = false,
        this.bookIds = const <num>[],
      });

  final String title;
  final String detail;
  final int points;
  final bool severe;
  final List<num> bookIds;
}

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

  double get paidTotal => rows.fold<double>(0.0, (s, r) => s + r.paidTotal);
}

class DayIncome {
  DayIncome(this.date);

  final DateTime date;
  double domestic = 0.0;
  double international = 0.0;
  double other = 0.0;
  int count = 0;
  final List<PaymentRow> items = [];

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
    items.add(r);
  }
}

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

class FilterSummaryBookingTaskCompPaymentGetx extends GetxController {
  final BookProTaskCompGetx src = BookProTaskCompGetx();

  final RxList<BookingRow> bookings = <BookingRow>[].obs;
  final RxList<PaymentRow> payments = <PaymentRow>[].obs;
  final RxList<RiskProfile> userRisks = <RiskProfile>[].obs;
  final RxList<RiskProfile> providerRisks = <RiskProfile>[].obs;

  final TextEditingController bookIdCont = TextEditingController();
  final TextEditingController userCont = TextEditingController();
  final TextEditingController providerCont = TextEditingController();
  final RxString bookIdQ = ''.obs;
  final RxString userQ = ''.obs;
  final RxString providerQ = ''.obs;

  final Rx<Tri> userApprovedF = Tri.any.obs;
  final Rx<Tri> providerApprovedF = Tri.any.obs;
  final Rx<Tri> userDoneF = Tri.any.obs;
  final Rx<Tri> providerDoneF = Tri.any.obs;
  final Rx<Tri> paymentF = Tri.any.obs;
  final Rx<SortKey> sortKey = SortKey.newest.obs;

  final RxInt quickN = 10.obs;
  final RxInt tab = 0.obs;

  final Rx<DateTime> incomeMonth =
      DateTime(DateTime.now().year, DateTime.now().month).obs;
  final Rxn<DateTime> selectedDay = Rxn<DateTime>();
  final TextEditingController dateCont = TextEditingController();
  final RxString dateError = ''.obs;

  final Rx<RiskView> riskView = RiskView.fakeUsers.obs;
  final Rxn<RiskLevel> riskLevelF = Rxn<RiskLevel>();
  final TextEditingController riskCont = TextEditingController();
  final RxString riskQ = ''.obs;

  final List<Worker> _workers = [];

  RxBool get isLoading => src.isLoading;

  Future<void> init({required String jwtToken}) async {
    try {
      _workers.add(ever(src.adminTaskCompletePaymentList, (_) => _recompute()));
      await src.init(jwtToken: jwtToken);
      _recompute();
    } catch (_) {}
  }

  Future<void> refreshData() async {
    try {
      await src.loadInfo();
    } catch (_) {}
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
      dateCont.dispose();
      src.onClose();
    } catch (_) {}
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
    } catch (_) {}
  }

  void _recompute() {
    try {
      final raw = src.adminTaskCompletePaymentList;

      final Map<num, BookingRow> map = {};
      for (final m in raw) {
        final info = m.bookingInfo;
        final id = info?.bookId;
        if (info != null && id != null && !map.containsKey(id)) {
          map[id] = BookingRow(bookId: id, info: info);
        }
      }

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
    } catch (_) {}
  }

  List<RiskProfile> _buildUserRisks(List<BookingRow> all) {
    try {
      final Map<num, List<BookingRow>> groups = {};
      for (final r in all) {
        final k = r.userNumber;
        if (k == null) continue;
        groups.putIfAbsent(k, () => <BookingRow>[]).add(r);
      }

      final Map<String, Set<num>> phoneOwners = {};
      for (final r in all) {
        final ph = digitsOnly(r.info.userPhoneNumber);
        final u = r.userNumber;
        if (ph.length >= 6 && u != null) {
          phoneOwners.putIfAbsent(ph, () => <num>{}).add(u);
        }
      }
      final Set<String> sharedKeys = phoneOwners.entries
          .where((e) => e.value.length > 1)
          .map((e) => e.key)
          .toSet();

      final List<RiskProfile> out = [];
      groups.forEach((num number, List<BookingRow> rows) {
        final flags = <RiskFlag>[];

        final never =
        rows.where((r) => !r.userApproved && !r.providerApproved).toList();
        if (never.length >= 2) {
          flags.add(RiskFlag(
            'Never approved',
            '${never.length} booking(s) with no approval from either side',
            never.length >= 5 ? 30 : 15,
            severe: never.length >= 5,
            bookIds: idsOf(never),
          ));
        }

        final userOpen = rows
            .where((r) => r.providerApproved && !r.userDone && r.stalled)
            .toList();
        if (userOpen.length >= 2) {
          flags.add(RiskFlag(
            'User never completes',
            '${userOpen.length} approved job(s) left open by the user',
            20,
            bookIds: idsOf(userOpen),
          ));
        }

        final ignores =
        rows.where((r) => r.userApproved && !r.providerApproved).toList();
        if (ignores.length >= 2) {
          flags.add(RiskFlag(
            'Provider ignores user',
            '${ignores.length} booking(s) approved by user but not by provider',
            10,
            bookIds: idsOf(ignores),
          ));
        }

        final staleUnpaid =
        rows.where((r) => r.stalled && !r.hasPayment).toList();
        if (staleUnpaid.length >= 3) {
          flags.add(RiskFlag(
            'Stale unpaid bookings',
            '${staleUnpaid.length} booking(s) open 7+ days with no payment',
            15,
            bookIds: idsOf(staleUnpaid),
          ));
        }

        final Map<String, List<BookingRow>> perDay = {};
        for (final r in rows) {
          final d = r.createdAt;
          if (d == null) continue;
          perDay
              .putIfAbsent('${d.year}-${d.month}-${d.day}', () => <BookingRow>[])
              .add(r);
        }
        List<BookingRow> burstRows = const <BookingRow>[];
        perDay.forEach((_, v) {
          if (v.length > burstRows.length) burstRows = v;
        });
        if (burstRows.length >= 3) {
          flags.add(RiskFlag(
            'Booking burst',
            'Up to ${burstRows.length} bookings created in a single day',
            15,
            bookIds: idsOf(burstRows),
          ));
        }

        final sharedRows = rows
            .where((r) => sharedKeys.contains(digitsOnly(r.info.userPhoneNumber)))
            .toList();
        if (sharedRows.isNotEmpty) {
          flags.add(RiskFlag(
            'Shared phone number',
            'Same phone number linked to multiple user accounts',
            25,
            severe: true,
            bookIds: idsOf(sharedRows),
          ));
        }

        final gaps = rows.where((r) => r.contactGap).toList();
        if (gaps.isNotEmpty && gaps.length * 2 >= rows.length) {
          flags.add(RiskFlag(
            'Incomplete contact',
            'Phone or email missing on most bookings',
            10,
            bookIds: idsOf(gaps),
          ));
        }

        final noCoords = rows.where((r) => r.noCoords).toList();
        if (noCoords.length >= 2 && noCoords.length * 2 >= rows.length) {
          flags.add(RiskFlag(
            'No location data',
            'Coordinates missing on most bookings',
            8,
            bookIds: idsOf(noCoords),
          ));
        }

        final emptyDesc = rows.where((r) => r.emptyDesc).toList();
        if (emptyDesc.length >= 2 && emptyDesc.length * 2 >= rows.length) {
          flags.add(RiskFlag(
            'Empty descriptions',
            'Booking descriptions are blank or too short',
            5,
            bookIds: idsOf(emptyDesc),
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
    } catch (_) {
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

        final ignored = rows.where((r) => !r.providerApproved).toList();
        if (ignored.length >= 2) {
          flags.add(RiskFlag(
            'Ignores booking requests',
            '${ignored.length} booking(s) never approved by provider',
            ignored.length >= 5 ? 25 : 15,
            severe: ignored.length >= 5,
            bookIds: idsOf(ignored),
          ));
        }

        final noFinish = rows.where((r) => r.userDone && !r.providerDone).toList();
        if (noFinish.length >= 2) {
          flags.add(RiskFlag(
            'Does not close after user confirms',
            '${noFinish.length} job(s) confirmed by user but not closed by provider',
            noFinish.length >= 4 ? 30 : 20,
            severe: noFinish.length >= 4,
            bookIds: idsOf(noFinish),
          ));
        }

        final doneNoPay =
        rows.where((r) => r.providerDone && !r.hasPayment).toList();
        if (doneNoPay.isNotEmpty) {
          flags.add(RiskFlag(
            'Completed without payment',
            '${doneNoPay.length} job(s) closed with no payment logged',
            doneNoPay.length >= 3 ? 25 : 10,
            bookIds: idsOf(doneNoPay),
          ));
        }

        final stale = rows.where((r) => r.stalled).toList();
        if (stale.length >= 3) {
          flags.add(RiskFlag(
            'Stale bookings',
            '${stale.length} booking(s) open 7+ days',
            20,
            bookIds: idsOf(stale),
          ));
        }

        final paidOpen = rows.where((r) => r.paidButIncomplete).toList();
        if (paidOpen.length >= 2) {
          flags.add(RiskFlag(
            'Paid but not closed',
            '${paidOpen.length} payment(s) logged on jobs not closed by both sides',
            15,
            bookIds: idsOf(paidOpen),
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
    } catch (_) {
      return [];
    }
  }

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
    } catch (_) {
      return [];
    }
  }

  List<BookingRow> get quickFinder {
    try {
      final list = bookings.where((r) => r.providerApproved && !r.hasPayment).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(1970))
            .compareTo(a.createdAt ?? DateTime(1970)));
      int n = quickN.value;
      if (n < 1) n = 1;
      if (n > 10) n = 10;
      return list.take(n).toList();
    } catch (_) {
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

  bool _matchRisk(BookingRow r, String q) {
    if (q.isEmpty) return true;
    return numText(r.bookId).contains(q) ||
        numText(r.userNumber).contains(q) ||
        numText(r.providerNumber).contains(q);
  }

  List<BookingRow> _searchRows(List<BookingRow> list) {
    final q = riskQ.value.trim();
    final out = list.where((r) => _matchRisk(r, q)).toList();
    out.sort((a, b) => (b.createdAt ?? DateTime(1970))
        .compareTo(a.createdAt ?? DateTime(1970)));
    return out;
  }

  List<BookingRow> get providerNotApprovedRows =>
      _searchRows(bookings.where((r) => !r.providerApproved).toList());

  List<BookingRow> get providerNotCompletedRows =>
      _searchRows(bookings.where((r) => !r.providerDone).toList());

  List<RiskProfile> get filteredRisks {
    try {
      final q = riskQ.value.trim();
      final lv = riskLevelF.value;
      return userRisks.where((r) {
        if (lv != null && r.level != lv) return false;
        if (q.isNotEmpty &&
            !numText(r.number).contains(q) &&
            !r.rows.any((b) => numText(b.bookId).contains(q))) {
          return false;
        }
        return true;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  String get monthLabelText {
    final m = incomeMonth.value;
    return '${m.month}/${m.year}';
  }

  int get daysInIncomeMonth {
    final m = incomeMonth.value;
    return DateTime(m.year, m.month + 1, 0).day;
  }

  void shiftMonth(int delta) {
    try {
      final m = incomeMonth.value;
      final next = DateTime(m.year, m.month + delta, 1);
      incomeMonth.value = next;
      final s = selectedDay.value;
      if (s != null && (s.year != next.year || s.month != next.month)) {
        selectedDay.value = null;
      }
    } catch (_) {}
  }

  void selectDay(DateTime d) {
    try {
      final day = DateTime(d.year, d.month, d.day);
      incomeMonth.value = DateTime(day.year, day.month, 1);
      selectedDay.value = day;
      dateError.value = '';
    } catch (_) {}
  }

  void clearSelectedDay() {
    selectedDay.value = null;
  }

  bool applyDateText() {
    try {
      final t = dateCont.text.trim();
      final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(t);
      if (m == null) {
        dateError.value = 'Use the format yyyy-MM-dd';
        return false;
      }
      final int y = int.parse(m.group(1)!);
      final int mo = int.parse(m.group(2)!);
      final int d = int.parse(m.group(3)!);
      final DateTime date = DateTime(y, mo, d);
      if (date.year != y || date.month != mo || date.day != d) {
        dateError.value = 'This date does not exist';
        return false;
      }
      selectDay(date);
      return true;
    } catch (_) {
      dateError.value = 'Use the format yyyy-MM-dd';
      return false;
    }
  }

  List<DayIncome> dailyIncome() {
    try {
      final m = incomeMonth.value;
      final days = daysInIncomeMonth;
      final list = List<DayIncome>.generate(
        days,
            (i) => DayIncome(DateTime(m.year, m.month, i + 1)),
      );
      for (final r in payments) {
        final d = r.date;
        if (d == null) continue;
        if (d.year != m.year || d.month != m.month) continue;
        list[d.day - 1].add(r);
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  List<PaymentRow> paymentsOn(DateTime d) {
    try {
      final list = payments.where((r) {
        final x = r.date;
        return x != null && x.year == d.year && x.month == d.month && x.day == d.day;
      }).toList()
        ..sort((a, b) =>
            (a.date ?? DateTime(1970)).compareTo(b.date ?? DateTime(1970)));
      return list;
    } catch (_) {
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
    } catch (_) {
      return [];
    }
  }

  int get totalBookings => bookings.length;
  int get totalPayments => payments.length;

  double get totalRevenue => payments.fold<double>(0.0, (s, p) => s + p.amount);

  double _sumKind(String k) {
    double s = 0.0;
    for (final p in payments) {
      if (k == 'domestic' && p.isDomestic) s += p.amount;
      if (k == 'international' && p.isIntl) s += p.amount;
      if (k == 'other' && !p.isDomestic && !p.isIntl) s += p.amount;
    }
    return s;
  }

  double get domesticRevenue => _sumKind('domestic');
  double get intlRevenue => _sumKind('international');
  double get otherRevenue => _sumKind('other');

  double get avgPayment => totalPayments == 0 ? 0.0 : totalRevenue / totalPayments;

  int get fullyCompletedCount => bookings.where((r) => r.fullyCompleted).length;

  double get completionRate =>
      totalBookings == 0 ? 0.0 : fullyCompletedCount / totalBookings;

  int get stalledCount => bookings.where((r) => r.stalled).length;
  int get bookingsWithoutPayment => bookings.where((r) => !r.hasPayment).length;

  int get blacklistedUsers => userRisks.where((r) => r.blacklisted).length;
  int get blacklistedProviders => providerRisks.where((r) => r.blacklisted).length;
}