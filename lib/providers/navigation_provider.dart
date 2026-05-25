import 'package:flutter/foundation.dart';

/// Bottom-nav index for [MainShell]; allows switching tabs programmatically.
class NavigationNotifier extends ChangeNotifier {
  int _index = 0;
  int get currentIndex => _index;

  void setIndex(int i) {
    if (i == _index || i < 0 || i > 4) return;
    _index = i;
    notifyListeners();
  }
}
