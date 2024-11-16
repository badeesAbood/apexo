import 'package:logging/logging.dart';

final log = Logger('ApexoLogger');

/// 1 = severe, 2 = warning, 3 = info
void logger(Object msg, StackTrace stacktrace, [int importance = 0]) {
  switch (importance) {
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
      log.severe(msg);
      break;
  }
  log.fine(stacktrace);
}
