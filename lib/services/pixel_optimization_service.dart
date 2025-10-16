import 'package:flutter/material.dart';
import 'pixel_service.dart';

/// Kapsamlı pixel optimizasyon servisi
class PixelOptimizationService {
  static PixelOptimizationService? _instance;
  static PixelOptimizationService get instance =>
      _instance ??= PixelOptimizationService._();

  PixelOptimizationService._();

  /// Layout overflow'ları önleyen güvenli widget wrapper
  Widget createSafeLayout({
    required Widget child,
    required BuildContext context,
    double? maxWidth,
    double? maxHeight,
    EdgeInsets? padding,
    EdgeInsets? margin,
    bool preventOverflow = true,
  }) {
    if (!preventOverflow) return child;

    final screenSize = PixelService.instance.getScreenSize(context);
    final safeArea = PixelService.instance.getSafeAreaPadding(context);

    // Güvenli boyutları hesapla
    final effectiveMaxWidth = maxWidth ?? screenSize.width * 0.95;
    final effectiveMaxHeight = maxHeight ??
        (screenSize.height - safeArea.top - safeArea.bottom) * 0.95;

    return Container(
      constraints: BoxConstraints(
        maxWidth: effectiveMaxWidth,
        maxHeight: effectiveMaxHeight,
      ),
      padding: padding ?? PixelService.instance.getSafePadding(context),
      margin: margin ?? PixelService.instance.getResponsiveMargin(context),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: child,
      ),
    );
  }

  /// Text overflow'ları önleyen güvenli text widget
  Widget createSafeText({
    required String text,
    required BuildContext context,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    bool autoSize = true,
  }) {
    final safeFontSize = fontSize != null
        ? PixelService.instance.getSafeTextSize(context, fontSize)
        : 14.0;

    return Text(
      text,
      style: TextStyle(
        fontSize: safeFontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines ?? (autoSize ? null : 1),
      overflow: overflow ?? TextOverflow.ellipsis,
    );
  }

  /// Responsive grid layout oluştur
  Widget createResponsiveGrid({
    required List<Widget> children,
    required BuildContext context,
    int? crossAxisCount,
    double? childAspectRatio,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
  }) {
    final columns = crossAxisCount ??
        PixelService.instance.getResponsiveGridColumns(context);
    final spacing = crossAxisSpacing ?? 8.0;
    final mainSpacing = mainAxisSpacing ?? 8.0;
    final aspectRatio = childAspectRatio ?? 1.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: mainSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  /// Responsive list view oluştur
  Widget createResponsiveList({
    required List<Widget> children,
    required BuildContext context,
    ScrollPhysics? physics,
    EdgeInsets? padding,
    bool shrinkWrap = true,
  }) {
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: physics ?? const BouncingScrollPhysics(),
      padding: padding ?? PixelService.instance.getSafePadding(context),
      children: children,
    );
  }

  /// Responsive button oluştur
  Widget createResponsiveButton({
    required Widget child,
    required VoidCallback? onPressed,
    required BuildContext context,
    ButtonStyle? style,
    EdgeInsets? padding,
    double? minWidth,
    double? minHeight,
  }) {
    final deviceType = PixelService.instance.getDeviceType(context);

    // Cihaz tipine göre minimum boyutlar
    double effectiveMinWidth = minWidth ?? 100.0;
    double effectiveMinHeight = minHeight ?? 40.0;

    switch (deviceType) {
      case DeviceType.small:
        effectiveMinWidth = 80.0;
        effectiveMinHeight = 36.0;
        break;
      case DeviceType.medium:
        effectiveMinWidth = 100.0;
        effectiveMinHeight = 40.0;
        break;
      case DeviceType.large:
        effectiveMinWidth = 120.0;
        effectiveMinHeight = 44.0;
        break;
      case DeviceType.extraLarge:
        effectiveMinWidth = 150.0;
        effectiveMinHeight = 48.0;
        break;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: effectiveMinWidth,
        minHeight: effectiveMinHeight,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: style?.copyWith(
          padding: MaterialStateProperty.all(
            padding ??
                PixelService.instance.getSafePadding(
                  context,
                  basePadding: 16.0,
                  top: 12.0,
                  bottom: 12.0,
                ),
          ),
        ),
        child: child,
      ),
    );
  }

  /// Responsive card oluştur
  Widget createResponsiveCard({
    required Widget child,
    required BuildContext context,
    EdgeInsets? margin,
    EdgeInsets? padding,
    double? elevation,
    Color? color,
    ShapeBorder? shape,
  }) {
    final deviceType = PixelService.instance.getDeviceType(context);

    // Cihaz tipine göre elevation ayarla
    double effectiveElevation = elevation ?? 4.0;
    switch (deviceType) {
      case DeviceType.small:
        effectiveElevation = 2.0;
        break;
      case DeviceType.medium:
        effectiveElevation = 4.0;
        break;
      case DeviceType.large:
        effectiveElevation = 6.0;
        break;
      case DeviceType.extraLarge:
        effectiveElevation = 8.0;
        break;
    }

    return Card(
      margin: margin ?? PixelService.instance.getResponsiveMargin(context),
      elevation: effectiveElevation,
      color: color,
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              PixelService.instance.getResponsiveBorderRadius(context, 12),
            ),
          ),
      child: Padding(
        padding: padding ?? PixelService.instance.getSafePadding(context),
        child: child,
      ),
    );
  }

  /// Responsive icon oluştur
  Widget createResponsiveIcon({
    required IconData icon,
    required BuildContext context,
    double? size,
    Color? color,
  }) {
    final effectiveSize = size ?? 24.0;
    return Icon(
      icon,
      size: PixelService.instance.getResponsiveIconSize(context, effectiveSize),
      color: color,
    );
  }

  /// Responsive spacing oluştur
  Widget createResponsiveSpacing({
    required BuildContext context,
    double? height,
    double? width,
  }) {
    return SizedBox(
      height: height != null
          ? PixelService.instance.getResponsiveHeight(context, height)
          : null,
      width: width != null
          ? PixelService.instance.getResponsiveWidth(context, width)
          : null,
    );
  }

  /// Layout overflow kontrolü
  bool checkForOverflow(BuildContext context, Widget widget) {
    try {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final size = renderBox.size;
        final screenSize = PixelService.instance.getScreenSize(context);
        final safeArea = PixelService.instance.getSafeAreaPadding(context);

        final availableWidth =
            screenSize.width - safeArea.left - safeArea.right;
        final availableHeight =
            screenSize.height - safeArea.top - safeArea.bottom;

        return size.width > availableWidth || size.height > availableHeight;
      }
    } catch (e) {
      // Hata durumunda güvenli varsayım
      return false;
    }
    return false;
  }

  /// Pixel perfect değerleri optimize et
  double optimizePixelValue(double value, double devicePixelRatio) {
    if (value < 0.5) return 0.0;
    return (value * devicePixelRatio).round() / devicePixelRatio;
  }

  /// Responsive değerleri optimize et
  double optimizeResponsiveValue(double value, double scaleFactor) {
    final optimized = value * scaleFactor;
    return optimized.clamp(0.0, double.infinity);
  }
}
