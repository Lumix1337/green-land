import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/greenhouse_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController =
      TextEditingController(text: 'erlan.agrotech@gmail.com');
  final _passwordController = TextEditingController(text: '••••••••••••');
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GreenhouseProvider>();
    final l10n = provider.l10n;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        actions: [
          // Language Switcher (RU / KZ)
          TextButton.icon(
            onPressed: () => provider.toggleLanguage(),
            icon: const Icon(Icons.language_rounded,
                color: AppTheme.primary, size: 18),
            label: Text(
              provider.language == AppLanguage.ru
                  ? 'РУС'
                  : (provider.language == AppLanguage.kz ? 'ҚАЗ' : 'ENG'),
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon / Logo
                  Center(
                    child: Image.asset('assets/figma/logo.png',
                        width: 82, height: 82),
                  ),
                  const SizedBox(height: 24),

                  // App Name & Tagline
                  Text(
                    l10n.tr('app_name'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.tr('login_subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 36),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email Input
                          Text(
                            l10n.tr('email_label'),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.email_outlined,
                                  color: AppTheme.textMuted),
                              hintText: 'erlan.agrotech@gmail.com',
                              fillColor: AppTheme.surfaceLight,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Password Input
                          Text(
                            l10n.tr('password_label'),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline_rounded,
                                  color: AppTheme.textMuted),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppTheme.textMuted,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              hintText: '••••••••',
                              fillColor: AppTheme.surfaceLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Login Button
                  ElevatedButton(
                    onPressed: () {
                      provider.login(
                          _emailController.text, _passwordController.text);
                      widget.onLoginSuccess();
                    },
                    child: Text(l10n.tr('login_btn')),
                  ),
                  const SizedBox(height: 14),

                  // Quick Demo Button (Persona Erlan)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side:
                          const BorderSide(color: AppTheme.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      _emailController.text = 'erlan.agrotech@gmail.com';
                      _passwordController.text = 'erlan2026';
                      provider.login(
                          _emailController.text, _passwordController.text);
                      widget.onLoginSuccess();
                    },
                    child: Text(
                      l10n.tr('quick_demo_login'),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
