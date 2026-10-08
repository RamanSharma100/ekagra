import 'package:flutter/material.dart';

class ThemeRadius {
  ThemeRadius._();

  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double m = 16.0;
  static const double l = 20.0;
  static const double xl = 28.0;
  static const double full = 999.0;

  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusM = BorderRadius.all(Radius.circular(m));
  static const BorderRadius radiusL = BorderRadius.all(Radius.circular(l));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(full));
}
