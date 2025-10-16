import 'package:flutter/material.dart';
import '../services/pixel_service.dart';

/// Responsive tasarım için yardımcı widget'lar
class ResponsiveWidget extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final double? maxHeight;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const ResponsiveWidget({
    super.key,
    required this.child,
    this.maxWidth,
    this.maxHeight,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? double.infinity,
        maxHeight: maxHeight ?? double.infinity,
      ),
      padding: padding ?? PixelService.instance.getResponsivePadding(context),
      margin: margin ?? PixelService.instance.getResponsiveMargin(context),
      child: child,
    );
  }
}

/// Responsive text widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    required this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: PixelService.instance.getSafeTextSize(context, fontSize),
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow:
          overflow ?? TextOverflow.ellipsis, // Default overflow protection
    );
  }
}

/// Responsive container widget
class ResponsiveContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Decoration? decoration;
  final Alignment? alignment;

  const ResponsiveContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.decoration,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width != null
          ? PixelService.instance.getResponsiveWidth(context, width!)
          : null,
      height: height != null
          ? PixelService.instance.getResponsiveHeight(context, height!)
          : null,
      padding: padding != null
          ? PixelService.instance
              .getSafePadding(context, basePadding: padding!.left)
          : null,
      margin: margin != null
          ? PixelService.instance.getPixelPerfectMargin(context, margin!)
          : null,
      decoration: decoration,
      alignment: alignment,
      child: child,
    );
  }
}

/// Responsive button widget
class ResponsiveButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final EdgeInsets? padding;

  const ResponsiveButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: style?.copyWith(
        padding: MaterialStateProperty.all(
          padding ??
              PixelService.instance.getResponsivePadding(
                context,
                basePadding: 16,
                top: 12,
                bottom: 12,
                left: 24,
                right: 24,
              ),
        ),
      ),
      child: child,
    );
  }
}

/// Responsive card widget
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? elevation;
  final Color? color;
  final ShapeBorder? shape;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.elevation,
    this.color,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? PixelService.instance.getResponsiveMargin(context),
      elevation: elevation ?? 4,
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
}

/// Responsive icon widget
class ResponsiveIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const ResponsiveIcon(
    this.icon, {
    super.key,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: PixelService.instance.getResponsiveIconSize(context, size),
      color: color,
    );
  }
}

/// Responsive spacing widget
class ResponsiveSpacing extends StatelessWidget {
  final double height;
  final double? width;

  const ResponsiveSpacing({
    super.key,
    required this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PixelService.instance.getResponsiveHeight(context, height),
      width: width != null
          ? PixelService.instance.getResponsiveWidth(context, width!)
          : null,
    );
  }
}

/// Responsive border radius widget
class ResponsiveBorderRadius extends BorderRadius {
  ResponsiveBorderRadius.circular(BuildContext context, double radius)
      : super.circular(
          PixelService.instance.getResponsiveBorderRadius(context, radius),
        );

  ResponsiveBorderRadius.only({
    required BuildContext context,
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) : super.only(
          topLeft: Radius.circular(
            PixelService.instance.getResponsiveBorderRadius(context, topLeft),
          ),
          topRight: Radius.circular(
            PixelService.instance.getResponsiveBorderRadius(context, topRight),
          ),
          bottomLeft: Radius.circular(
            PixelService.instance
                .getResponsiveBorderRadius(context, bottomLeft),
          ),
          bottomRight: Radius.circular(
            PixelService.instance
                .getResponsiveBorderRadius(context, bottomRight),
          ),
        );
}
