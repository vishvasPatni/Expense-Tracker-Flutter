import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

typedef OnlineCallback = void Function(bool online);

/// Subscribes to connectivity changes.
final class ConnectivityMonitor {
  ConnectivityMonitor() : _connectivity = Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  Stream<List<ConnectivityResult>> get onChange => _connectivity.onConnectivityChanged;

  Future<bool> isOnline() async {
    final r = await _connectivity.checkConnectivity();
    return _resultsOnline(r);
  }

  static bool _resultsOnline(List<ConnectivityResult> r) =>
      r.isNotEmpty && !r.every((e) => e == ConnectivityResult.none);

  void listen(OnlineCallback onOnline) {
    _sub?.cancel();
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      onOnline(_resultsOnline(results));
    });
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
