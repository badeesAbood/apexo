import 'package:apexo/backend/utils/imgs.dart';
import 'package:apexo/backend/utils/logger.dart';
import 'package:apexo/state/stores/staff/member_model.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';
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

  bool showArchived = false;
  showArchivedChanged(bool? value) {
    showArchived = value ?? false;
    notify();
  }

  // login related state

  // login page state:
  TextEditingController urlField = TextEditingController();
  TextEditingController tokenField = TextEditingController();
  TextEditingController pinField = TextEditingController();
  bool initialStateLoaded = false;
  String loginError = "";
  String loadingIndicator = "";

  // login credentials
  String dbBranchUrl = "";
  String token = "";
  String memberID = "";

  Member? get currentMember {
    return staff.get(memberID);
  }

  /// means we checked and verified that it works
  bool loginActive = false;
  bool showStaffPicker = false;

  /// images that needs to be downloaded
  Map<String, String> imagesToDownload = {};
  Future<void> downloadImgs() async {
    // this is going to be triggered on:
    // 1. adding images
    // 2. when this object is initialized from JSON

    isSyncing++;
    try {
      while (imagesToDownload.isNotEmpty) {
        final url = imagesToDownload.keys.first;
        final String name = imagesToDownload.values.first;
        await saveImageFromUrl(url, name);
        imagesToDownload.remove(url);
      }
    } catch (e) {
      logger(e);
    }
    isSyncing--;
  }

  setLoadingIndicator(String message) {
    loadingIndicator = message;
    notify();
  }

  finishedLoginProcess([String error = ""]) {
    loadingIndicator = "";
    loginError = error;
    notify();
  }

  logout() {
    loginActive = false;
    pinField.text = "";
    showStaffPicker = false;
    dbBranchUrl = "";
    token = "";
    notify();
    return finishedLoginProcess();
  }

  loginButton([bool online = true]) {
    String u = urlField.text;
    String t = tokenField.text;
    activate(u, t, online);
  }

  /// run a series of callbacks that would require the login credentials to be active
  activate(String u, String t, bool online) async {
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

    if (online) {
      for (var callback in activators.values) {
        try {
          await callback([dbBranchUrl, token]);
        } catch (e) {
          logger(e);
        }
      }
    }

    if (staff.docs.isEmpty) {
      loginActive = true;
    } else {
      showStaffPicker = true;
    }

    return finishedLoginProcess();
  }

  openAsCertainStaff() {
    if (currentMember == null) {
      return finishedLoginProcess("Please choose from the dropdown who you are");
    } else if (currentMember?.pin == pinField.text) {
      loginActive = true;
      return finishedLoginProcess("Please choose from the dropdown who you are");
    } else {
      return finishedLoginProcess("Incorrect PIN");
    }
  }

  Map<String, Future Function(List<String>)> activators = {};

  @override
  fromJson(Map<String, dynamic> json) async {
    themeMode = isPositiveInt(json["themeMode"]) ? ThemeMode.values[json["themeMode"]] : themeMode;
    themeAccentColor =
        isPositiveInt(json["themeAccentColor"]) ? Colors.accentColors[json["themeAccentColor"]] : themeAccentColor;
    dbBranchUrl = json["dbBranchUrl"] ?? dbBranchUrl;
    token = json["token"] ?? token;
    memberID = json["memberID"] ?? memberID;
    imagesToDownload = json["imagesToDownload"] == null ? {} : Map<String, String>.from(json["imagesToDownload"]);

    if (dbBranchUrl.isNotEmpty && token.isNotEmpty) {
      urlField = TextEditingController(text: dbBranchUrl);
      tokenField = TextEditingController(text: token);
      await activate(dbBranchUrl, token, true);
    } else {
      loginActive = false;
    }

    downloadImgs();
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    json['themeMode'] = themeMode.index;
    json['themeAccentColor'] = Colors.accentColors.indexWhere((color) => color.value == themeAccentColor.value);
    json['dbBranchUrl'] = dbBranchUrl;
    json['token'] = token;
    json["loginActive"] = loginActive;
    json["memberID"] = memberID;
    json["imagesToDownload"] = imagesToDownload;
    return json;
  }
}

final State state = State("main-state");
