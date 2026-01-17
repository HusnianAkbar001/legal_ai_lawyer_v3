import 'package:flutter/material.dart';

class AppResponsive {
  static double scale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 340) return 0.88;
    if (width < 360) return 0.92;
    if (width < 400) return 0.96;
    if (width < 480) return 1.0;
    if (width < 600) return 1.05;
    return 1.1;
  }

  static double heightScale(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    if (height < 620) return 0.9;
    if (height < 700) return 0.95;
    if (height < 780) return 1.0;
    if (height < 900) return 1.05;
    return 1.1;
  }

  static double spacing(BuildContext context, double base) {
    return base * scale(context);
  }

  static double font(BuildContext context, double base) {
    return base * scale(context);
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final base = width >= 900 ? 28.0 : 20.0;
    final scaled = base * scale(context);
    return EdgeInsets.symmetric(horizontal: scaled, vertical: scaled);
  }

  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 900;
    if (width >= 900) return 820;
    if (width >= 700) return 720;
    return width;
  }

  static double clampTextScale(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final maxScale = width < 360 ? 1.0 : width < 420 ? 1.1 : 1.2;
    final scale = media.textScaleFactor;
    if (scale < 0.9) return 0.9;
    if (scale > maxScale) return maxScale;
    return scale;
  }
}
