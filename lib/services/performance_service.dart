import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Çarkıfelek animasyonlarının performansını optimize eden servis
class PerformanceService {
  static PerformanceService? _instance;
  static PerformanceService get instance =>
      _instance ??= PerformanceService._();

  PerformanceService._();

  /// Performans seviyesi
  PerformanceLevel _performanceLevel = PerformanceLevel.medium;

  /// Performans seviyesini al
  PerformanceLevel get performanceLevel => _performanceLevel;

  /// Performans seviyesini ayarla
  void setPerformanceLevel(PerformanceLevel level) {
    _performanceLevel = level;
  }

  /// Cihaz performansını otomatik tespit et
  Future<void> detectPerformanceLevel() async {
    try {
      // Platform bilgilerini al
      final platform = Platform.operatingSystem;

      // Android için ek bilgiler
      if (platform == 'android') {
        await _detectAndroidPerformance();
      } else if (platform == 'ios') {
        await _detectIOSPerformance();
      } else {
        // Diğer platformlar için varsayılan
        _performanceLevel = PerformanceLevel.medium;
      }
    } catch (e) {
      // Hata durumunda varsayılan performans seviyesi
      _performanceLevel = PerformanceLevel.medium;
    }
  }

  /// Android cihaz performansını tespit et
  Future<void> _detectAndroidPerformance() async {
    try {
      // Method channel ile Android sistem bilgilerini al
      const platform = MethodChannel('performance_detector');

      final Map<dynamic, dynamic> systemInfo =
          await platform.invokeMethod('getSystemInfo');

      final int ramMB = systemInfo['ramMB'] ?? 2048;
      final int cpuCores = systemInfo['cpuCores'] ?? 4;

      // Performans seviyesini belirle
      if (ramMB >= 4096 && cpuCores >= 8) {
        _performanceLevel = PerformanceLevel.high;
      } else if (ramMB >= 2048 && cpuCores >= 4) {
        _performanceLevel = PerformanceLevel.medium;
      } else {
        _performanceLevel = PerformanceLevel.low;
      }
    } catch (e) {
      // Method channel çalışmazsa varsayılan
      _performanceLevel = PerformanceLevel.medium;
    }
  }

  /// iOS cihaz performansını tespit et
  Future<void> _detectIOSPerformance() async {
    try {
      const platform = MethodChannel('performance_detector');
      final Map<dynamic, dynamic> deviceInfo =
          await platform.invokeMethod('getDeviceInfo');

      final String deviceModel = deviceInfo['model'] ?? '';

      // iPhone modeline göre performans seviyesi
      if (deviceModel.contains('iPhone 12') ||
          deviceModel.contains('iPhone 13') ||
          deviceModel.contains('iPhone 14') ||
          deviceModel.contains('iPhone 15')) {
        _performanceLevel = PerformanceLevel.high;
      } else if (deviceModel.contains('iPhone 10') ||
          deviceModel.contains('iPhone 11')) {
        _performanceLevel = PerformanceLevel.medium;
      } else {
        _performanceLevel = PerformanceLevel.low;
      }
    } catch (e) {
      _performanceLevel = PerformanceLevel.medium;
    }
  }

  /// Çarkıfelek animasyon süresini performansa göre al
  Duration getWheelSpinDuration() {
    switch (_performanceLevel) {
      case PerformanceLevel.high:
        return const Duration(
            seconds: 4); // Yüksek performans: daha uzun animasyon
      case PerformanceLevel.medium:
        return const Duration(seconds: 3); // Orta performans: standart süre
      case PerformanceLevel.low:
        return const Duration(seconds: 2); // Düşük performans: kısa animasyon
    }
  }

  /// Fortune wheel animasyon süresini performansa göre al
  Duration getFortuneWheelDuration() {
    switch (_performanceLevel) {
      case PerformanceLevel.high:
        return const Duration(seconds: 4);
      case PerformanceLevel.medium:
        return const Duration(seconds: 3);
      case PerformanceLevel.low:
        return const Duration(seconds: 2);
    }
  }

  /// Login wheel animasyon hızını performansa göre al
  double getLoginWheelSpeed() {
    switch (_performanceLevel) {
      case PerformanceLevel.high:
        return 2.0; // Daha hızlı
      case PerformanceLevel.medium:
        return 1.5; // Standart
      case PerformanceLevel.low:
        return 1.0; // Daha yavaş
    }
  }

  /// Animasyon curve'ünü performansa göre al
  Curve getAnimationCurve() {
    switch (_performanceLevel) {
      case PerformanceLevel.high:
        return Curves.easeOutQuint; // Daha smooth
      case PerformanceLevel.medium:
        return Curves.easeOutCubic; // Standart
      case PerformanceLevel.low:
        return Curves.easeOut; // Daha basit
    }
  }

  /// Frame rate'i performansa göre al
  int getTargetFrameRate() {
    switch (_performanceLevel) {
      case PerformanceLevel.high:
        return 60; // Yüksek FPS
      case PerformanceLevel.medium:
        return 30; // Orta FPS
      case PerformanceLevel.low:
        return 20; // Düşük FPS
    }
  }
}

/// Performans seviyeleri
enum PerformanceLevel {
  low, // Düşük performanslı cihazlar
  medium, // Orta performanslı cihazlar
  high, // Yüksek performanslı cihazlar
}
