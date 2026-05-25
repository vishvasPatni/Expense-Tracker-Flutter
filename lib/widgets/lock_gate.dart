import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_lock_provider.dart';
import '../providers/privacy_provider.dart';
import '../screens/security/lock_screen.dart';
import '../services/platform_service.dart';

class LockGate extends StatefulWidget {
  final Widget child;

  const LockGate({
    super.key,
    required this.child,
  });

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final appLockProvider = context.read<AppLockProvider>();
    
    switch (state) {
      case AppLifecycleState.resumed:
        appLockProvider.onAppResumed();
        break;
      case AppLifecycleState.paused:
        // Trigger privacy mode hiding when app goes to background
        final privacyProvider = context.read<PrivacyProvider>();
        privacyProvider.onAppPaused();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLockProvider>(
      builder: (context, appLockProvider, child) {
        if (appLockProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (appLockProvider.isLocked) {
          // Enable screenshot protection when locked
          PlatformService.enableScreenshotProtection();
          return const LockScreen();
        } else {
          // Disable screenshot protection when unlocked
          PlatformService.disableScreenshotProtection();
          return widget.child;
        }
      },
    );
  }
}