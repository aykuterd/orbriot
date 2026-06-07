import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import '../controllers/power_up_controller.dart';
import '../controllers/power_up_inventory_controller.dart';

class GameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PowerUpInventoryController>(() => PowerUpInventoryController());
    Get.lazyPut<PowerUpController>(() => PowerUpController());
    Get.lazyPut<GameController>(() => GameController());
  }
}
