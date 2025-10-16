import 'package:flutter/material.dart';

/// BorderPainter hatalarını çözen servis
class BorderPainterFix {
  static BorderPainterFix? _instance;
  static BorderPainterFix get instance => _instance ??= BorderPainterFix._();

  BorderPainterFix._();

  /// Pixel perfect border oluştur
  static Border createPixelPerfectBorder({
    Color? color,
    double width = 1.0,
    BorderStyle style = BorderStyle.solid,
    double? devicePixelRatio,
  }) {
    // Device pixel ratio'ya göre border width'i ayarla
    final effectiveWidth = devicePixelRatio != null
        ? (width * devicePixelRatio).round() / devicePixelRatio
        : width;

    return Border.all(
      color: color ?? Colors.grey,
      width: effectiveWidth,
      style: style,
    );
  }

  /// Pixel perfect border radius oluştur
  static BorderRadius createPixelPerfectBorderRadius({
    double radius = 0.0,
    double? devicePixelRatio,
  }) {
    final effectiveRadius = devicePixelRatio != null
        ? (radius * devicePixelRatio).round() / devicePixelRatio
        : radius;

    return BorderRadius.circular(effectiveRadius);
  }

  /// Container için pixel perfect decoration oluştur
  static BoxDecoration createPixelPerfectDecoration({
    Color? color,
    Border? border,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
    double? devicePixelRatio,
  }) {
    return BoxDecoration(
      color: color,
      border: border,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      gradient: gradient,
    );
  }

  /// InkWell için pixel perfect border radius
  static BorderRadius createInkWellBorderRadius({
    double radius = 0.0,
    double? devicePixelRatio,
  }) {
    return createPixelPerfectBorderRadius(
      radius: radius,
      devicePixelRatio: devicePixelRatio,
    );
  }

  /// Card için pixel perfect elevation
  static double createPixelPerfectElevation({
    double elevation = 4.0,
    double? devicePixelRatio,
  }) {
    if (devicePixelRatio == null) return elevation;

    // Yüksek DPI ekranlarda elevation'ı artır
    if (devicePixelRatio >= 3.0) {
      return elevation * 1.2;
    } else if (devicePixelRatio >= 2.0) {
      return elevation * 1.1;
    }

    return elevation;
  }

  /// ListTile için pixel perfect padding
  static EdgeInsets createListTilePadding({
    double? devicePixelRatio,
    EdgeInsets? basePadding,
  }) {
    final padding =
        basePadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

    if (devicePixelRatio == null) return padding;

    // Yüksek DPI ekranlarda padding'i artır
    final scaleFactor = devicePixelRatio >= 3.0 ? 1.1 : 1.0;

    return EdgeInsets.only(
      left: padding.left * scaleFactor,
      right: padding.right * scaleFactor,
      top: padding.top * scaleFactor,
      bottom: padding.bottom * scaleFactor,
    );
  }

  /// Icon için pixel perfect size
  static double createIconSize({
    double baseSize = 24.0,
    double? devicePixelRatio,
  }) {
    if (devicePixelRatio == null) return baseSize;

    // Yüksek DPI ekranlarda icon size'ı artır
    if (devicePixelRatio >= 3.0) {
      return baseSize * 1.1;
    } else if (devicePixelRatio >= 2.0) {
      return baseSize * 1.05;
    }

    return baseSize;
  }

  /// Text için pixel perfect font size
  static double createFontSize({
    double baseSize = 14.0,
    double? devicePixelRatio,
  }) {
    if (devicePixelRatio == null) return baseSize;

    // Yüksek DPI ekranlarda font size'ı artır
    if (devicePixelRatio >= 3.0) {
      return baseSize * 1.1;
    } else if (devicePixelRatio >= 2.0) {
      return baseSize * 1.05;
    } else if (devicePixelRatio <= 1.0) {
      return baseSize * 0.9;
    }

    return baseSize;
  }

  /// Button için pixel perfect padding
  static EdgeInsets createButtonPadding({
    double? devicePixelRatio,
    EdgeInsets? basePadding,
  }) {
    final padding =
        basePadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

    if (devicePixelRatio == null) return padding;

    // Yüksek DPI ekranlarda button padding'i artır
    final scaleFactor = devicePixelRatio >= 3.0 ? 1.1 : 1.0;

    return EdgeInsets.only(
      left: padding.left * scaleFactor,
      right: padding.right * scaleFactor,
      top: padding.top * scaleFactor,
      bottom: padding.bottom * scaleFactor,
    );
  }

  /// Divider için pixel perfect thickness
  static double createDividerThickness({
    double baseThickness = 1.0,
    double? devicePixelRatio,
  }) {
    if (devicePixelRatio == null) return baseThickness;

    // Yüksek DPI ekranlarda divider thickness'i artır
    if (devicePixelRatio >= 3.0) {
      return baseThickness * 1.5;
    } else if (devicePixelRatio >= 2.0) {
      return baseThickness * 1.2;
    }

    return baseThickness;
  }
}
