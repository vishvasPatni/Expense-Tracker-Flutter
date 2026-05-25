import 'package:flutter/foundation.dart';
import '../services/security_service.dart';

class PrivacyProvider extends ChangeNotifier {
  final SecurityService _securityService = SecurityService();
  
  bool _isPrivacyModeEnabled = false;
  bool _isTemporarilyRevealed = false;
  bool _isLoading = false;

  bool get isPrivacyModeEnabled => _isPrivacyModeEnabled;
  bool get isTemporarilyRevealed => _isTemporarilyRevealed;
  bool get isLoading => _isLoading;
  bool get shouldHideValues => _isPrivacyModeEnabled && !_isTemporarilyRevealed;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _isPrivacyModeEnabled = await _securityService.isPrivacyModeEnabled();
    } catch (e) {
      _isPrivacyModeEnabled = false;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setPrivacyMode(bool enabled) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _securityService.setPrivacyModeEnabled(enabled);
      _isPrivacyModeEnabled = enabled;
      
      // Reset temporary reveal when toggling privacy mode
      _isTemporarilyRevealed = false;
      
      // Force immediate UI update
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // Handle error - could show snackbar
    }
  }

  void temporarilyReveal() {
    if (!_isPrivacyModeEnabled) return;
    
    _isTemporarilyRevealed = true;
    notifyListeners();
    
    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (_isTemporarilyRevealed) {
        _isTemporarilyRevealed = false;
        notifyListeners();
      }
    });
  }

  void hideValues() {
    if (_isTemporarilyRevealed) {
      _isTemporarilyRevealed = false;
      notifyListeners();
    }
  }

  void onAppPaused() {
    // Hide values when app goes to background
    if (_isPrivacyModeEnabled && _isTemporarilyRevealed) {
      _isTemporarilyRevealed = false;
      notifyListeners();
    }
  }

  // Force refresh privacy state - useful for debugging glitches
  void forceRefresh() {
    notifyListeners();
  }
}