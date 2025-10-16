import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';

/// Pixel density ve responsive tasarım sorunlarını çözen servis
class PixelService {
  static PixelService? _instance;
  static PixelService get instance => _instance ??= PixelService._();

  PixelService._();

  /// Cihazın pixel density'sini al
  double getDevicePixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// Cihazın ekran boyutunu al
  Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// Cihazın platform bilgisini al
  String getPlatform() {
    return Platform.operatingSystem;
  }

  /// Pixel density'ye göre font boyutunu ayarla
  double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final pixelRatio = getDevicePixelRatio(context);

    // Yüksek pixel density'li cihazlarda font boyutunu artır
    if (pixelRatio >= 3.0) {
      return baseFontSize * 1.1;
    } else if (pixelRatio >= 2.0) {
      return baseFontSize * 1.05;
    } else if (pixelRatio <= 1.0) {
      return baseFontSize * 0.9;
    }

    return baseFontSize;
  }

  /// Ekran boyutuna göre responsive padding değeri
  EdgeInsets getResponsivePadding(
    BuildContext context, {
    double basePadding = 16.0,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    final screenSize = getScreenSize(context);
    final scaleFactor = _getScaleFactor(screenSize);

    return EdgeInsets.only(
      top: (top ?? basePadding) * scaleFactor,
      bottom: (bottom ?? basePadding) * scaleFactor,
      left: (left ?? basePadding) * scaleFactor,
      right: (right ?? basePadding) * scaleFactor,
    );
  }

  /// Ekran boyutuna göre responsive margin değeri
  EdgeInsets getResponsiveMargin(
    BuildContext context, {
    double baseMargin = 8.0,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    final screenSize = getScreenSize(context);
    final scaleFactor = _getScaleFactor(screenSize);

    return EdgeInsets.only(
      top: (top ?? baseMargin) * scaleFactor,
      bottom: (bottom ?? baseMargin) * scaleFactor,
      left: (left ?? baseMargin) * scaleFactor,
      right: (right ?? baseMargin) * scaleFactor,
    );
  }

  /// Ekran boyutuna göre responsive border radius
  double getResponsiveBorderRadius(BuildContext context, double baseRadius) {
    final screenSize = getScreenSize(context);
    final scaleFactor = _getScaleFactor(screenSize);

    return baseRadius * scaleFactor;
  }

  /// Ekran boyutuna göre responsive icon boyutu
  double getResponsiveIconSize(BuildContext context, double baseSize) {
    final screenSize = getScreenSize(context);
    final scaleFactor = _getScaleFactor(screenSize);

    return baseSize * scaleFactor;
  }

  /// Ekran boyutuna göre responsive container boyutu
  double getResponsiveSize(BuildContext context, double baseSize) {
    final screenSize = getScreenSize(context);
    final scaleFactor = _getScaleFactor(screenSize);

    return baseSize * scaleFactor;
  }

  /// Ekran boyutuna göre responsive width
  double getResponsiveWidth(BuildContext context, double baseWidth) {
    final screenSize = getScreenSize(context);
    final scaleFactor = _getScaleFactor(screenSize);

    return baseWidth * scaleFactor;
  }

  /// Ekran boyutuna göre responsive height
  double getResponsiveHeight(BuildContext context, double baseHeight) {
    final screenSize = getScreenSize(context);
    final scaleFactor = _getScaleFactor(screenSize);

    return baseHeight * scaleFactor;
  }

  /// Ekran boyutuna göre scale factor hesapla
  double _getScaleFactor(Size screenSize) {
    final diagonal = _calculateDiagonal(screenSize);

    if (diagonal <= 600) {
      return 0.8; // Küçük ekranlar
    } else if (diagonal <= 800) {
      return 0.9; // Orta ekranlar
    } else if (diagonal <= 1000) {
      return 1.0; // Standart ekranlar
    } else if (diagonal <= 1200) {
      return 1.1; // Büyük ekranlar
    } else {
      return 1.2; // Çok büyük ekranlar
    }
  }

  /// Ekran diagonal'ını hesapla
  double _calculateDiagonal(Size size) {
    return sqrt(size.width * size.width + size.height * size.height);
  }

  /// Pixel perfect border radius
  double getPixelPerfectBorderRadius(BuildContext context, double baseRadius) {
    final pixelRatio = getDevicePixelRatio(context);
    // Optimize: avoid unnecessary calculations for small values
    if (baseRadius < 0.5) return 0.0;
    return (baseRadius * pixelRatio).round() / pixelRatio;
  }

  /// Pixel perfect padding
  EdgeInsets getPixelPerfectPadding(
      BuildContext context, EdgeInsets basePadding) {
    final pixelRatio = getDevicePixelRatio(context);

    return EdgeInsets.only(
      top: (basePadding.top * pixelRatio).round() / pixelRatio,
      bottom: (basePadding.bottom * pixelRatio).round() / pixelRatio,
      left: (basePadding.left * pixelRatio).round() / pixelRatio,
      right: (basePadding.right * pixelRatio).round() / pixelRatio,
    );
  }

  /// Pixel perfect margin
  EdgeInsets getPixelPerfectMargin(
      BuildContext context, EdgeInsets baseMargin) {
    final pixelRatio = getDevicePixelRatio(context);

    return EdgeInsets.only(
      top: (baseMargin.top * pixelRatio).round() / pixelRatio,
      bottom: (baseMargin.bottom * pixelRatio).round() / pixelRatio,
      left: (baseMargin.left * pixelRatio).round() / pixelRatio,
      right: (baseMargin.right * pixelRatio).round() / pixelRatio,
    );
  }

  /// Pixel perfect size
  double getPixelPerfectSize(BuildContext context, double baseSize) {
    final pixelRatio = getDevicePixelRatio(context);
    // Optimize: avoid unnecessary calculations for very small values
    if (baseSize < 0.5) return 0.0;
    return (baseSize * pixelRatio).round() / pixelRatio;
  }

  /// Cihaz tipini belirle
  DeviceType getDeviceType(BuildContext context) {
    final screenSize = getScreenSize(context);
    final diagonal = _calculateDiagonal(screenSize);

    if (diagonal <= 600) {
      return DeviceType.small;
    } else if (diagonal <= 800) {
      return DeviceType.medium;
    } else if (diagonal <= 1000) {
      return DeviceType.large;
    } else {
      return DeviceType.extraLarge;
    }
  }

  /// Responsive grid column sayısı
  int getResponsiveGridColumns(BuildContext context) {
    final screenSize = getScreenSize(context);

    if (screenSize.width <= 480) {
      return 2; // Küçük ekranlar
    } else if (screenSize.width <= 768) {
      return 3; // Orta ekranlar
    } else if (screenSize.width <= 1024) {
      return 4; // Büyük ekranlar
    } else {
      return 5; // Çok büyük ekranlar
    }
  }

  /// Responsive font scale
  double getResponsiveFontScale(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.small:
        return 0.9;
      case DeviceType.medium:
        return 1.0;
      case DeviceType.large:
        return 1.1;
      case DeviceType.extraLarge:
        return 1.2;
    }
  }

  /// Safe area padding'i al
  EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Status bar height'i al
  double getStatusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// Bottom navigation bar height'i al
  double getBottomNavigationBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// Text overflow protection - güvenli text boyutu
  double getSafeTextSize(BuildContext context, double baseSize) {
    final deviceType = getDeviceType(context);

    // Minimum ve maksimum boyut sınırları
    double minSize = 10.0;
    double maxSize = 32.0;

    // Cihaz tipine göre ayarlama
    switch (deviceType) {
      case DeviceType.small:
        maxSize = 24.0;
        break;
      case DeviceType.medium:
        maxSize = 28.0;
        break;
      case DeviceType.large:
        maxSize = 32.0;
        break;
      case DeviceType.extraLarge:
        maxSize = 36.0;
        break;
    }

    final adjustedSize = getResponsiveFontSize(context, baseSize);
    return adjustedSize.clamp(minSize, maxSize);
  }

  /// Layout overflow protection - güvenli container boyutu
  Size getSafeContainerSize(BuildContext context, Size baseSize) {
    final screenSize = getScreenSize(context);
    final deviceType = getDeviceType(context);

    // Ekran boyutunun %90'ını geçmeyecek şekilde sınırla
    final maxWidth = screenSize.width * 0.9;
    final maxHeight = screenSize.height * 0.8;

    // Cihaz tipine göre minimum boyutlar
    double minWidth = 100.0;
    double minHeight = 50.0;

    switch (deviceType) {
      case DeviceType.small:
        minWidth = 80.0;
        minHeight = 40.0;
        break;
      case DeviceType.medium:
        minWidth = 100.0;
        minHeight = 50.0;
        break;
      case DeviceType.large:
        minWidth = 120.0;
        minHeight = 60.0;
        break;
      case DeviceType.extraLarge:
        minWidth = 150.0;
        minHeight = 80.0;
        break;
    }

    final adjustedWidth = getResponsiveWidth(context, baseSize.width);
    final adjustedHeight = getResponsiveHeight(context, baseSize.height);

    return Size(
      adjustedWidth.clamp(minWidth, maxWidth),
      adjustedHeight.clamp(minHeight, maxHeight),
    );
  }

  /// Responsive padding with overflow protection
  EdgeInsets getSafePadding(
    BuildContext context, {
    double basePadding = 16.0,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    final deviceType = getDeviceType(context);

    // Maksimum padding sınırları
    double maxPadding = 32.0;
    double minPadding = 4.0;

    switch (deviceType) {
      case DeviceType.small:
        maxPadding = 24.0;
        break;
      case DeviceType.medium:
        maxPadding = 28.0;
        break;
      case DeviceType.large:
        maxPadding = 32.0;
        break;
      case DeviceType.extraLarge:
        maxPadding = 40.0;
        break;
    }

    final responsivePadding = getResponsivePadding(
      context,
      basePadding: basePadding,
      top: top,
      bottom: bottom,
      left: left,
      right: right,
    );

    return EdgeInsets.only(
      top: responsivePadding.top.clamp(minPadding, maxPadding),
      bottom: responsivePadding.bottom.clamp(minPadding, maxPadding),
      left: responsivePadding.left.clamp(minPadding, maxPadding),
      right: responsivePadding.right.clamp(minPadding, maxPadding),
    );
  }
}

/// Cihaz tipleri
enum DeviceType {
  small, // Küçük telefonlar
  medium, // Orta boy telefonlar
  large, // Büyük telefonlar ve tabletler
  extraLarge, // Büyük tabletler ve desktop
}
