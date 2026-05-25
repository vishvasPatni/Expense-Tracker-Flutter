import 'package:flutter/foundation.dart';

/// Bumped after transaction mutations so tabs under [IndexedStack] reload data.
class TransactionRefresh extends ChangeNotifier {
  void bump() => notifyListeners();
}
