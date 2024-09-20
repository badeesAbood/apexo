import 'package:logging/logging.dart';

final log = Logger('ApexoLogger');
void logger(Object msg, [int level = 0]) {
  switch (level) {
    case 1:
      log.severe(msg);
      break;
    case 2:
      log.warning(msg);
      break;
    case 3:
      log.info(msg);
      break;
    default:
      log.info(msg);
      break;
  }
}
