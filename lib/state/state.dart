import 'package:apexo/backend/utils/constants.dart';
import 'package:apexo/backend/utils/imgs.dart';
import 'package:apexo/backend/utils/logger.dart';
import 'package:apexo/state/stores/staff/member_model.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Locale;
import '../backend/observable/observable.dart';
import 'package:pocketbase/pocketbase.dart';

bool isPositiveInt(int? value) {
  if (value == null) return false;
  if (value < 0) return false;
  return true;
}

class State extends ObservablePersistingObject {
  State(super.identifier);

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
  TextEditingController emailField = TextEditingController();
  TextEditingController passwordField = TextEditingController();
  bool initialStateLoaded = false;
  String loginError = "";
  String loadingIndicator = "";
  int selectedTab = 0;
  bool resetInstructionsSent = false;

  // login credentials
  String url = "";
  String email = "";
  String password = "";
  String token = "";

  // PocketBase instance
  PocketBase? pb;

  Member? get currentMember {
    return staff.getByEmail(email);
  }

  /// means we checked and verified that it works
  bool loginActive = false;

  bool get isAdmin {
    if (pb == null) return false;
    return pb!.authStore.model is AdminModel;
  }

  /// images that needs to be downloaded
  List<String> imagesToDownload = [];
  Future<void> downloadImgs() async {
    // this is going to be triggered on:
    // 1. adding images
    // 2. when this object is initialized from JSON

    isSyncing++;
    try {
      while (imagesToDownload.isNotEmpty) {
        final targetURL = imagesToDownload.first;
        await saveImageFromUrl(targetURL);
        imagesToDownload.removeWhere((element) => element == targetURL);
        notify();
      }
    } catch (e, s) {
      logger("Error during downloading image: $e", s);
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
    url = "";
    email = "";
    password = "";
    token = "";
    pb!.authStore.clear();
    notify();
    return finishedLoginProcess();
  }

  resetButton() async {
    final pb = PocketBase(urlField.text);
    loginError = '';
    loadingIndicator = "Sending password reset email";
    notify();
    try {
      await pb.admins.requestPasswordReset(emailField.text);
      await pb.collection("users").requestPasswordReset(emailField.text);
    } catch (e, s) {
      logger("Error during resetting password: $e", s);
      loginError = "Error while resetting password: $e.";
      loadingIndicator = "";
      notify();
      return;
    }
    loadingIndicator = "";
    resetInstructionsSent = true;
    notify();
  }

  loginButton([bool online = true]) {
    String url = urlField.text.replaceFirst(RegExp(r'/+$'), "");
    String email = emailField.text;
    String password = passwordField.text;
    activate(url, [email, password], online);
  }

  Future<String> authenticateWithPassword(String email, String password) async {
    try {
      final auth = await pb!.admins.authWithPassword(email, password);
      return auth.token;
    } catch (e) {
      final auth = await pb!.collection("users").authWithPassword(email, password);
      return auth.token;
    }
  }

  Future<String> authenticateWithToken(String token) async {
    try {
      final auth = await pb!.admins.refresh();
      return auth.token;
    } catch (e) {
      final auth = await pb!.collection("users").authRefresh();
      return auth.token;
    }
  }

  /// run a series of callbacks that would require the login credentials to be active
  activate(String inputURL, List<String> credentials, bool online) async {
    if (pb == null || pb?.baseUrl.isEmpty == true) {
      pb = PocketBase(inputURL);
    }

    setLoadingIndicator("Connecting to the server");
    loginError = "";

    if (online) {
      try {
        // email and password authentication
        if (credentials.length == 2) {
          token = await authenticateWithPassword(credentials[0], credentials[1]);
          email = credentials[0];
          url = inputURL;
        }
        // token authentication
        if (credentials.length == 1) {
          pb!.authStore.save(credentials[0], null);
          if (pb!.authStore.isValid == false) {
            throw Exception("Invalid token");
          }
          token = await authenticateWithToken(token);
          url = inputURL;
        }

        // create database if it doesn't exist
        try {
          try {
            await pb!.collections.getOne(dataCollectionName);
            await pb!.collections.getOne(publicCollectionName);
          } catch (e) {
            if (isAdmin) {
              await pb!.collections.import([dataCollectionImport, publicCollectionImport]);
              await pb!.collections.update("users", body: {"createRule": null});
            } else {
              logger(
                "ERROR: The needed database can not be created because the logged-in user is not admin.",
                StackTrace.current,
              );
            }
          }
        } catch (e) {
          throw Exception("Error while creating the collection for the first time: $e");
        }
      } catch (e, s) {
        if (e.runtimeType != ClientException) {
          loginError = "Error while logging-in: $e.";
        } else if ((e as ClientException).statusCode == 404) {
          loginError = "Invalid server, make sure PocketBase is installed and running.";
        } else if (e.statusCode == 400) {
          loginError = "Invalid email or password.";
        } else if (e.statusCode == 0) {
          loginError = "Unable to connect, please check your internet connection, firewall, or the server URL field.";
        } else {
          loginError = "Unknown client exception while authenticating: $e.";
        }
        logger("Could not login due to the following error: $e", s, 2);
        return finishedLoginProcess(loginError);
      }

      proceededOffline = false;
    }

    /// if we reached here it means it was a successful login

    if (online) {
      for (var callback in activators.values) {
        try {
          await callback();
        } catch (e, s) {
          logger("Error during running activators: $e", s);
        }
      }
    }
    loginActive = true;
    return finishedLoginProcess();
  }

  Map<String, Future Function()> activators = {};

  @override
  fromJson(Map<String, dynamic> json) async {
    url = json["url"] ?? url;
    email = json["email"] ?? email;
    imagesToDownload = json["imagesToDownload"] == null ? [] : List<String>.from(json["imagesToDownload"]);
    token = json["token"] ?? token;

    urlField.text = url;
    emailField.text = email;

    if (token.isNotEmpty) {
      await activate(url, [token], true);
    } else {
      loginActive = false;
    }

    downloadImgs();
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    json['url'] = url;
    json['email'] = email;
    json["loginActive"] = loginActive;
    json["imagesToDownload"] = imagesToDownload;
    json["token"] = token;
    return json;
  }
}

final State state = State("main-state");
