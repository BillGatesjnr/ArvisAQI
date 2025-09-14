import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _signedIn = true; // Assume signed in for now
  String _userEmail = 'user@example.com';

  bool get signedIn => _signedIn;
  String get userEmail => _userEmail;

  void signOut() {
    _signedIn = false;
    notifyListeners();
    // Add real sign out logic here
  }

  void manageAccount() {
    // Placeholder for manage account logic (change email/password, etc.)
    notifyListeners();
  }
}
