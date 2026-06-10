import 'package:flutter/material.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_cta.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_features.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_hero.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_showcase.dart';
import 'package:smart_sprint/features/landing/view/widgets/marketing_scaffold.dart';

/// The public marketing landing page (web entry point). Already-signed-in
/// visitors are forwarded to /home by [MarketingScaffold].
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MarketingScaffold(
      currentPath: '/',
      redirectIfSignedIn: true,
      sections: [
        LandingHero(),
        LandingLogos(),
        LandingFeatures(),
        LandingShowcase(),
        LandingMetrics(),
        LandingCtaBand(),
      ],
    );
  }
}
