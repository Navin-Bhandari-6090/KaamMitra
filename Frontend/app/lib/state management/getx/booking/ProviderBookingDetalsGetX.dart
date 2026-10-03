import 'package:get/get.dart';

class Providerbookingdetalsgetx extends GetxController
{


  RxBool UpdateStatePhotoUpload=true.obs;

  ChangeUpdateStatePhotoUpload()
  {
    if (UpdateStatePhotoUpload.value == true) {
      UpdateStatePhotoUpload.value = false;
    }
    else {
      UpdateStatePhotoUpload.value = true;
    }
  }

}