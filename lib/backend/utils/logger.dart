import 'package:logging/logging.dart';

final log = Logger('ApexoLogger');

/// 1 = severe, 2 = warning, 3 = info
void logger(Object msg, StackTrace? stacktrace, [int importance = 0]) {
  switch (importance) {
    case 1:
      log.severe("\x1B[31m$msg\x1B[0m");
      break;
    case 2:
      log.warning("\x1B[33m$msg\x1B[0m");
      break;
    case 3:
      log.info("\x1B[34m$msg\x1B[0m");
      break;
    default:
      log.severe("\x1B[31m$msg\x1B[0m");
      break;
  }
  if (stacktrace != null) log.info("\n\x1B[35mSTACKTRACE:\n$stacktrace\x1B[0m");
}
