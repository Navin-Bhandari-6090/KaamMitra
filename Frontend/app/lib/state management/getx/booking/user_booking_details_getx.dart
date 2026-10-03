import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class UserBookingDetailsGetx extends GetxController
{

  RxBool UpdateStatePhotoUpload=true.obs;

  ChangeUpdateStatePhotoUpload(){
    if(UpdateStatePhotoUpload.value==true){
      UpdateStatePhotoUpload.value=false;
    }
    else{
      UpdateStatePhotoUpload.value=true;
    }



  }

}