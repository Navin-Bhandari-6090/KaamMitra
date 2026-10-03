import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import '../web/common widget/getx_cont_pick_single_photo_int.dart';
import '../web/common widget/single_video_pick_getx.dart';
import '../web/common widget/toast.dart';
import '../web/common widget/toast_long_period.dart';

//video file photo size limit
const String VideoSize="500 MB";
const String PhotoSize="100 MB";
const String FileSize="100 MB";

//video file photo cont for pick
final change_photo_cont_getx=Get.put(pick_single_photo_getx_int());
final change_video_cont_getx=Get.put(PickSingleVideoController());

//files extension
const String VideoExtension=".mp4";
const String PhotoExtension=".jpg , .png , .jpeg";
const String FileExtension=".pdf";

//toast message
//short time
final Toast= Toastget();
//long toast
final LongToast=Toastget_Long_Period();