import 'package:get/get.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/saved_works/bindings/saved_works_binding.dart';
import '../modules/saved_works/views/saved_works_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SAVED_WORKS;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.SAVED_WORKS,
      page: () => const SavedWorksView(),
      binding: SavedWorksBinding(),
    ),
  ];
}
