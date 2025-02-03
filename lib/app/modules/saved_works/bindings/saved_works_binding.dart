import 'package:get/get.dart';

import '../controllers/saved_works_controller.dart';

class SavedWorksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SavedWorksController>(
      () => SavedWorksController(),
    );
  }
}
