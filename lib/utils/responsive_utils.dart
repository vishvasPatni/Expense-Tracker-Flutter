import 'package:flutter/material.dart';

/// Responsive utility class for adaptive sizing across different screen sizes
class ResponsiveUtils {
  final BuildContext context;
  late final Size _screenSize;
  late final double _width;
  late final double _height;
  
  ResponsiveUtils(this.context) {
    _screenSize = MediaQuery.of(context).size;
    _width = _screenSize.width;
    _height = _screenSize.height;
  }
  
  /// Screen size categories
  bool get isSmallScreen => _width < 360;
  bool get isMediumScreen => _width >= 360 && _width < 400;
  bool get isLargeScreen => _width >= 400 && _width < 600;
  bool get isTablet => _width >= 600;
  bool get isLandscape => _width > _height;
  
  /// Responsive width (percentage of screen width)
  double wp(double percentage) => _width * percentage / 100;
  
  /// Responsive height (percentage of screen height)
  double hp(double percentage) => _height * percentage / 100;
  
  /// Responsive font size
  double sp(double size) {
    if (isSmallScreen) return size * 0.85;
    if (isMediumScreen) return size * 0.92;
    if (isTablet) return size * 1.15;
    return size;
  }
  
  /// Responsive padding
  EdgeInsets responsivePadding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    final multiplier = isSmallScreen ? 0.8 : (isTablet ? 1.2 : 1.0);
    
    if (all != null) {
      return EdgeInsets.all(all * multiplier);
    }
    
    return EdgeInsets.fromLTRB(
      (left ?? horizontal ?? 0) * multiplier,
      (top ?? vertical ?? 0) * multiplier,
      (right ?? horizontal ?? 0) * multiplier,
      (bottom ?? vertical ?? 0) * multiplier,
    );
  }
  
  /// Responsive spacing
  double spacing(double size) {
    if (isSmallScreen) return size * 0.75;
    if (isTablet) return size * 1.25;
    return size;
  }
  
  /// Responsive icon size
  double iconSize(double size) {
    if (isSmallScreen) return size * 0.85;
    if (isTablet) return size * 1.2;
    return size;
  }
  
  /// Get responsive value based on screen size
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? smallScreen,
  }) {
    if (isSmallScreen && smallScreen != null) return smallScreen;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
  
  /// Standard responsive padding for screens
  EdgeInsets get screenPadding {
    return EdgeInsets.fromLTRB(
      wp(6),  // 6% left
      hp(10), // 10% top
      wp(6),  // 6% right
      hp(15), // 15% bottom
    );
  }
  
  /// Standard responsive padding for cards
  EdgeInsets get cardPadding {
    return responsivePadding(all: 16);
  }
  
  /// Standard responsive margin
  EdgeInsets get cardMargin {
    return responsivePadding(horizontal: 16, vertical: 8);
  }
}

/// Extension to easily access responsive utils
extension ResponsiveContext on BuildContext {
  ResponsiveUtils get responsive => ResponsiveUtils(this);
}
