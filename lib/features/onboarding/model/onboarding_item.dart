import 'package:flutter/widgets.dart';

class OnboardingItem {
  final Color bgColor;
  final String title;
  final String subtitle;
  final Widget illustration;

  const OnboardingItem({
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.illustration,
  });
}
