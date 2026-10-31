import 'package:intl/intl.dart';

String formatDateTime(String timestamp) {
  try {
    DateTime dateTime = DateTime.parse(timestamp).toLocal();
    return DateFormat('dd MMM yyyy, h:mm a').format(dateTime);
  }
  catch(e){
    return "";
  }
}