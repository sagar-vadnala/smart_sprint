import 'package:flutter/material.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_cta.dart';
import 'package:smart_sprint/features/landing/view/widgets/marketing_scaffold.dart';
import 'package:smart_sprint/features/landing/view/widgets/page_sections.dart';

class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MarketingScaffold(
      currentPath: '/pricing',
      sections: [
        PageHero(
          kicker: 'Pricing',
          title: 'Simple pricing\nthat scales with you.',
          lede:
              'Start free and stay free for solo work and small teams. Upgrade only '
              'when you need more room and advanced collaboration.',
        ),
        PricingTiers(
          tiers: [
            PricingTier(
              name: 'Free',
              price: '\$0',
              period: 'forever',
              blurb: 'For solo makers and trying things out.',
              cta: 'Get started',
              features: [
                'Personal workspace',
                'Unlimited tasks & subtasks',
                'List & Board views',
                'Sprints & backlog',
                'Dark & light themes',
              ],
            ),
            PricingTier(
              name: 'Pro',
              price: '\$8',
              period: 'per user / mo',
              blurb: 'For small teams shipping together.',
              highlighted: true,
              cta: 'Start free trial',
              features: [
                'Everything in Free',
                'Shared team organizations',
                'Invite teammates by email',
                'Assignees & activity timeline',
                'Threaded comments',
                'Command search across the org',
              ],
            ),
            PricingTier(
              name: 'Business',
              price: '\$16',
              period: 'per user / mo',
              blurb: 'For growing teams that need control.',
              cta: 'Talk to us',
              features: [
                'Everything in Pro',
                'Roles & permissions',
                'Multiple organizations',
                'Priority support',
                'Advanced security',
              ],
            ),
          ],
        ),
        FaqList(
          index: '02',
          items: [
            ('Is there really a free plan?',
                'Yes. Solo work and small teams can use SmartSprint free, forever — no credit card required to start.'),
            ('Can I switch plans later?',
                'Absolutely. Upgrade or downgrade any time; changes take effect immediately and billing is prorated.'),
            ('Do you offer a trial of Pro?',
                'Every new team gets a free Pro trial so you can try shared organizations and collaboration before paying.'),
            ('How does per-user pricing work?',
                'You only pay for active members in your team organizations. Your personal space is always free.'),
          ],
        ),
        LandingCtaBand(),
      ],
    );
  }
}
