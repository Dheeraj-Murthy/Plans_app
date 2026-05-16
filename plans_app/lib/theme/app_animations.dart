import 'package:flutter/widgets.dart';

class AppAnimations {
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve easeOutQuart = Curves.easeOutQuart;
  static const Curve spring = Curves.fastOutSlowIn;

  static const SpringDescription gentleSpring = SpringDescription(
    mass: 1,
    stiffness: 180,
    damping: 20,
  );

  static const SpringDescription snappySpring = SpringDescription(
    mass: 1,
    stiffness: 260,
    damping: 22,
  );
}
