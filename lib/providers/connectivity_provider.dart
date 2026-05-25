import 'package:flutter/foundation.dart';

import '../utils/connectivity_utils.dart';

/// Online/offline for banners and disabling writes.
class ConnectivityNotifier extends ChangeNotifier {
  ConnectivityNotifier() {
    _monitor.listen((online) {
      if (_isOnline != online) {
        _isOnline = online;
        notifyListeners();
      }
    });
    _check();
  }

  final ConnectivityMonitor _monitor = ConnectivityMonitor();
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> _check() async {
    final o = await _monitor.isOnline();
    _isOnline = o;
    Future.microtask(() => notifyListeners());
  }

  Future<void> recheck() => _check();

  @override
  void dispose() {
    _monitor.dispose();
    super.dispose();
  }
}
