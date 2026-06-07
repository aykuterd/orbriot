import 'package:get/get.dart';
import 'tr_tr.dart';
import 'en_us.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'tr_TR': trTR,
        'en_US': enUS,
      };
}
