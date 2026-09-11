import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';

class HeaderGetX extends GetxController {
  // ============================================================
  // HEADER HOVER STATE
  // ============================================================

  // -1 means nothing is being hovered.
  RxInt HeaderHoveredIndex = (-1).obs;

  void HeaderHoveredIndexMethod(int NewIndex)
  {
    HeaderHoveredIndex.value = NewIndex;
  }

  void HeaderHoverClearMethod()
  {
    HeaderHoveredIndex.value = -1;
  }


}