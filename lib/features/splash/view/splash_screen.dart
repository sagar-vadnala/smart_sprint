import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import '../cubit/splash_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    context.read<SplashCubit>().initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state is SplashNavigateOnboarding) {
          context.go('/onboarding');
        } else if (state is SplashNavigateLogin) {
          context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo mark
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: const _LogoMark(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Wordmark
                  FadeTransition(
                    opacity: _fade,
                    child: Text(
                      'SmartSprint',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Tagline
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      'Work smarter. Ship faster.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white38,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B6FFF), AppColors.brand, AppColors.brandDark],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.bolt_rounded,
        color: Colors.white,
        size: 42,
      ),
    );
  }
}
