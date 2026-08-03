import 'package:get/get.dart';

import '../../controllers/global_search_controller.dart';

class MainBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GlobalSearchController>(() => GlobalSearchController());
  }
}
