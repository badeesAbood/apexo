import 'package:apexo/core/observable.dart';
import 'package:apexo/services/launch.dart';
import 'package:apexo/services/login.dart';
import 'package:apexo/utils/logger.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:pocketbase/pocketbase.dart';

class _LoginScreenState {
  final urlField = TextEditingController();
  final emailField = TextEditingController();
  final passwordField = TextEditingController();
  final loginError = ObservableState("");
  final loadingIndicator = ObservableState("");
  final selectedTab = ObservableState(0);
  final resetInstructionsSent = ObservableState(false);
  final obscureText = ObservableState(true);
  final proceededOffline = ObservableState(true);

  void finishedLoginProcess([String error = ""]) {
    loadingIndicator("");
    loginError(error);
  }

  void resetButton() async {
    final pb = PocketBase(urlField.text);
    loginError("");
    loadingIndicator("Sending password reset email");
    try {
      await pb.collection("_superusers").requestPasswordReset(emailField.text);
      await pb.collection("users").requestPasswordReset(emailField.text);
    } catch (e, s) {
      logger("Error during resetting password: $e", s);
      loginError("Error while resetting password: $e.");
      loadingIndicator("");
      return;
    }
    loadingIndicator("");
    resetInstructionsSent(true);
  }

  void loginButton([bool online = true]) {
    String url = "http://44.201.207.33:8090";
    String email = emailField.text;
    String password = passwordField.text;
    login.activate(url, [email, password], online);
  }

  _LoginScreenState() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (launch.isDemo) {
        loginButton();
      }
    });
  }
}

final loginCtrl = _LoginScreenState();
