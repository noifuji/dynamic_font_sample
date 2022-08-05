import 'package:flutter/cupertino.dart';

class AppSettings extends ChangeNotifier {
String _fontFamily = "default";

String get fontFamily => _fontFamily;

  set fontFamily(String value) {
    _fontFamily = value;
    notifyListeners();
  }
}