import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/features/auth/bloc/auth_bloc.dart';
import 'package:smart_sprint/features/auth/bloc/auth_event.dart';
import 'package:smart_sprint/features/auth/bloc/auth_state.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_event.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() != true) return;
    context.read<AuthBloc>().add(
      AuthLoginSubmitted(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          // We now have a token — (re)load the user's workspace data, then go.
          context.read<WorkspaceBloc>().add(WorkspaceLoaded());
          context.go('/home');
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // Logo mark small
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF8B6FFF), AppColors.brand],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Heading
                      Text(
                        'Welcome back.',
                        style: theme.textTheme.displaySmall?.copyWith(
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to your workspace.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Email field
                      _FieldLabel(label: 'Email address', isDark: isDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'you@company.com',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            size: 18,
                            color: AppColors.lightTextMuted,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(v.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password field
                      _FieldLabel(label: 'Password', isDark: isDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(context),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: AppColors.lightTextMuted,
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: AppColors.lightTextMuted,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < 6) {
                            return 'Must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brand,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Continue button
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;
                          return ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () => _submit(context),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Continue'),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Divider
                      _OrDivider(isDark: isDark),
                      const SizedBox(height: 20),

                      // Google sign-in
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;
                          return OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () => context.read<AuthBloc>().add(
                                    AuthGoogleSignInRequested(),
                                  ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _GoogleG(),
                                const SizedBox(width: 10),
                                Text(
                                  'Continue with Google',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkText
                                        : AppColors.lightText,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),

                      // Sign up link
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/signup'),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                              children: [
                                const TextSpan(text: "New here? "),
                                TextSpan(
                                  text: 'Create an account',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brand,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _FieldLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkText : AppColors.lightText,
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  final bool isDark;

  const _OrDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Row(
      children: [
        Expanded(child: Divider(color: borderColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
        ),
        Expanded(child: Divider(color: borderColor, thickness: 1)),
      ],
    );
  }
}

class _GoogleG extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      child: Text(
        'G',
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF4285F4),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
