import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (mounted) {
      if (success) {
        final authState = ref.read(authProvider);
        if (authState.status == AuthStatus.unconfirmed) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Email', style: TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.bold)),
              content: Text(
                'A verification link has been sent to ${_emailController.text.trim()}.\n\nPlease check your inbox and verify your email before signing in to enable Cloud Sync.',
                style: const TextStyle(fontFamily: 'PublicSans'),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(fontFamily: 'PublicSans')),
                ),
              ],
            ),
          );
          if (mounted) {
            context.pop(); // Pop RegisterPage
          }
        } else {
          // Go back to the screen before login (e.g., Settings)
          context.pop(); // Pop RegisterPage
          context.pop(); // Pop LoginPage
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully! Cloud Sync enabled.')),
          );
        }
      } else {
        final errorMsg = ref.read(authProvider).error ?? 'Registration failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salin', style: TextStyle(fontFamily: 'IBMPlexMono', fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.carbonText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign up to safely sync your finances across devices',
                style: TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 14,
                  color: AppTheme.carbonText.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
                style: const TextStyle(fontFamily: 'PublicSans', color: AppTheme.carbonText),
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: TextStyle(fontFamily: 'PublicSans'),
                  border: UnderlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email.';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                enabled: !isLoading,
                style: const TextStyle(fontFamily: 'PublicSans', color: AppTheme.carbonText),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(fontFamily: 'PublicSans'),
                  border: UnderlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password.';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Confirm Password field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                enabled: !isLoading,
                style: const TextStyle(fontFamily: 'PublicSans', color: AppTheme.carbonText),
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: TextStyle(fontFamily: 'PublicSans'),
                  border: UnderlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password.';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48),

              // Register Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.carbonText,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'CREATE ACCOUNT',
                          style: TextStyle(
                            fontFamily: 'PublicSans',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Back to Login link
              Center(
                child: TextButton(
                  onPressed: isLoading ? null : () => context.pop(),
                  child: Text(
                    'Already have an account? Sign in',
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      color: AppTheme.carbonText.withOpacity(0.6),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
