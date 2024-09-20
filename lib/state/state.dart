import 'package:apexo/backend/utils/logger.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Locale;
import "package:http/http.dart" as http;
import '../backend/observable/observable.dart';
import '../../backend/utils/validate_database_url.dart';

bool isPositiveInt(int? value) {
  if (value == null) return false;
  if (value < 0) return false;
  return true;
}

class State extends ObservablePersistingObject {
  State(super.identifier);

  // theme related state
  var themeMode = ThemeMode.system;
  var themeAccentColor = Colors.blue;

  int isSyncing = 0;
  bool isOnline = false;
  bool proceededOffline = true;

  // login related state

  // login page state:
  TextEditingController urlField = TextEditingController();
  TextEditingController tokenField = TextEditingController();
  bool initialStateLoaded = false;
  String loginError = "";
  String loadingIndicator = "";

  // login credentials
  String dbBranchUrl = "";
  String token = "";

  /// means we checked and verified that it works
  bool loginActive = false;

  setLoadingIndicator(String message) {
    loadingIndicator = message;
    notify();
  }

  finishedLoginProcess([String error = ""]) {
    loadingIndicator = "";
    loginError = error;
    notify();
  }

  ///
  logout() {
    loginActive = false;
    dbBranchUrl = "";
    token = "";
    notify();
  }

  loginButton([bool online = true]) {
    String u = urlField.text;
    String t = tokenField.text;
    activate(u, t, online);
  }

  /// run a series of callbacks that would require the login credentials to be active
  activate(String u, String t, bool online) async {
    // https://ali-saleem-s-workspace-5hcj8d.us-east-1.xata.sh/db/fleebit:main
    // xau_vmtdcyehunYmhQuf9aPXu4j7vJEbNixb3

    if (validateXataUrl(u) != true) {
      return finishedLoginProcess(
          "Database URL must be in the following format: \n https://[workspace].[region].xata.sh/db/[db]:[table]");
    }

    setLoadingIndicator("Connecting to the server");
    loginError = "";

    if (online) {
      http.Response? res;

      try {
        res = await http.get(Uri.parse(u), headers: {"Authorization": "Bearer $t"});
      } catch (e) {
        logger(e);
        return finishedLoginProcess("Error while connecting to the server");
      }

      if (res.statusCode != 200) {
        return finishedLoginProcess("Error code: ${res.statusCode}\n${res.body}");
      }
      proceededOffline = false;
    }

    /// if we reached here it means it was a successful login

    dbBranchUrl = u;
    token = t;

    for (var callback in activators.values) {
      try {
        await callback([dbBranchUrl, token]);
      } catch (e) {
        logger(e);
      }
    }

    loginActive = true;
    return finishedLoginProcess();
  }

  Map<String, Future Function(List<String>)> activators = {};

  @override
  fromJson(Map<String, dynamic> json) async {
    themeMode = isPositiveInt(json["themeMode"]) ? ThemeMode.values[json["themeMode"]] : themeMode;
    themeAccentColor =
        isPositiveInt(json["themeAccentColor"]) ? Colors.accentColors[json["themeAccentColor"]] : themeAccentColor;
    dbBranchUrl = json["dbBranchUrl"] ?? dbBranchUrl;
    token = json["token"] ?? token;

    if (dbBranchUrl.isNotEmpty && token.isNotEmpty) {
      urlField = TextEditingController(text: dbBranchUrl);
      tokenField = TextEditingController(text: token);
      await activate(dbBranchUrl, token, true);
    } else {
      loginActive = false;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    json['themeMode'] = themeMode.index;
    json['themeAccentColor'] = Colors.accentColors.indexWhere((color) => color.value == themeAccentColor.value);
    json['dbBranchUrl'] = dbBranchUrl;
    json['token'] = token;
    json["loginActive"] = loginActive;
    return json;
  }
}

final State state = State("main-state");
