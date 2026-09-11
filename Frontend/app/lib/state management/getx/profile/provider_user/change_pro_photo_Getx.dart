import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class ProviderGetx extends GetxController
{
  RxBool ChangePhotoClick=false.obs;

  final RxBool actionTilePressed = false.obs;

  void ChangePhotoClickChange()
  {
    if(ChangePhotoClick.value==false)
    {
      ChangePhotoClick.value=true;
    }
    else{
      ChangePhotoClick.value=false;
    }
  }

  void setActionTilePressed(bool value)
  {
    actionTilePressed.value = value;
  }

}