import 'package:flutter/widgets.dart';

// Dikonversi dari src/utils/responsive.ts (base 375×812)
class Responsive {
  static const double _baseWidth  = 375.0;
  static const double _baseHeight = 812.0;

  static double _w = _baseWidth;
  static double _h = _baseHeight;

  static void init(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    _w = size.width;
    _h = size.height;
  }

  // Horizontal scale  → hs() 
  static double hs(double size) => (_w / _baseWidth) * size;

  // Vertical scale    → vs() 
  static double vs(double size) => (_h / _baseHeight) * size;

  // Moderate scale    → ms() 
  static double ms(double size, {double factor = 0.5}) =>
      size + (hs(size) - size) * factor;
}

// Extension: 16.hs / 24.vs / 12.ms
extension ResponsiveNum on num {
  double get hs => Responsive.hs(toDouble());
  double get vs => Responsive.vs(toDouble());
  double get ms => Responsive.ms(toDouble());
}