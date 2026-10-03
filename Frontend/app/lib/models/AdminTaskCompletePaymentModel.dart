import 'BookingInfoModel.dart';
import 'ProTaskCompPayInfoModel.dart';

class AdminTaskCompletePaymentModel {
  AdminTaskCompletePaymentModel({
    ProTaskCompPayInfoModel? paymentInfo,
    BookingInfoModel? bookingInfo,
  }) {
    _paymentInfo = paymentInfo;
    _bookingInfo = bookingInfo;
  }

  AdminTaskCompletePaymentModel.fromJson(dynamic json) {
    if (json['paymentInfo'] != null) {
      _paymentInfo =
          ProTaskCompPayInfoModel.fromJson(
            json['paymentInfo'],
          );
    } else {
      _paymentInfo = null;
    }

    if (json['bookingInfo'] != null) {
      _bookingInfo =
          BookingInfoModel.fromJson(
            json['bookingInfo'],
          );
    } else {
      _bookingInfo = null;
    }
  }

  ProTaskCompPayInfoModel? _paymentInfo;
  BookingInfoModel? _bookingInfo;

  ProTaskCompPayInfoModel? get paymentInfo =>
      _paymentInfo;

  BookingInfoModel? get bookingInfo =>
      _bookingInfo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    map['paymentInfo'] =
        _paymentInfo?.toJson();

    map['bookingInfo'] =
        _bookingInfo?.toJson();

    return map;
  }
}