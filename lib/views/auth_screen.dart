import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/greenhouse_provider.dart';
import '../theme/app_theme.dart';

enum _AuthStep { signIn, signUp, verify }

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  _AuthStep _step = _AuthStep.signIn;
  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _show(_AuthStep step) {
    _form.currentState?.reset();
    _password.clear();
    _confirmation.clear();
    setState(() {
      _step = step;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    final provider = context.read<GreenhouseProvider>();

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = _email.text.trim();
      final password = _password.text;
      final registering = _step == _AuthStep.signUp;
      final result = registering
          ? await provider.authService.signUp(email: email, password: password)
          : await provider.authService.signIn(email: email, password: password);
      if (!mounted) return;
      if (result.isSuccess && result.requiresVerification) {
        _show(_AuthStep.verify);
      } else if (result.isSuccess) {
        await provider.setSignedInAccount(result.email ?? email);
        if (!mounted) return;
        widget.onLoginSuccess();
      } else {
        setState(() {
          _error = result.errorMessage ?? 'Unable to sign in. Please try again.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not connect. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _field(
    String label,
    String hint,
    TextEditingController controller, {
    bool secret = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: !_busy,
          obscureText: secret && obscure,
          keyboardType: secret
              ? TextInputType.visiblePassword
              : TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: hint,
            fillColor: AppTheme.surfaceLight,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: secret && onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
          ),
          validator: validate,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GreenhouseProvider>();
    final l10n = provider.l10n;
    final registering = _step == _AuthStep.signUp;
    final verifying = _step == _AuthStep.verify;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AuthHeader(l10n: l10n),
                  Transform.translate(
                    offset: const Offset(0, -31),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _form,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  verifying
                                      ? l10n.tr('auth_check_email')
                                      : registering
                                          ? l10n.tr('auth_create_account')
                                          : l10n.tr('auth_welcome_back'),
                                  style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  verifying
                                      ? l10n.tr('auth_verify_desc')
                                      : registering
                                          ? l10n.tr('auth_signup_desc')
                                          : l10n.tr('auth_signin_desc'),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                if (!verifying) ...[
                                  _field(
                                    l10n.tr('email_label'),
                                    'you@example.com',
                                    _email,
                                    validate: (value) =>
                                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                                .hasMatch(value?.trim() ?? '')
                                            ? null
                                            : l10n.tr('auth_invalid_email'),
                                  ),
                                  const SizedBox(height: 12),
                                  _field(
                                    l10n.tr('password_label'),
                                    registering
                                        ? 'Create a password'
                                        : 'Enter your password',
                                    _password,
                                    secret: true,
                                    obscure: _obscurePassword,
                                    onToggleObscure: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                    validate: (value) =>
                                        (value?.length ?? 0) >= 6
                                            ? null
                                            : l10n.tr('auth_short_password'),
                                  ),
                                  if (registering) ...[
                                    const SizedBox(height: 12),
                                    _field(
                                      l10n.tr('auth_confirm_password'),
                                      'Re-enter your password',
                                      _confirmation,
                                      secret: true,
                                      obscure: _obscureConfirm,
                                      onToggleObscure: () => setState(() =>
                                          _obscureConfirm = !_obscureConfirm),
                                      validate: (value) =>
                                          value == _password.text
                                              ? null
                                              : l10n.tr(
                                                  'auth_passwords_mismatch'),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                ],
                                if (_error != null) ...[
                                  Text(_error!,
                                      style: const TextStyle(
                                          color: AppTheme.statusDanger)),
                                  const SizedBox(height: 12),
                                ],
                                ElevatedButton(
                                  onPressed: _busy
                                      ? null
                                      : verifying
                                          ? () => _show(_AuthStep.signIn)
                                          : _submit,
                                  child: Text(_busy
                                      ? l10n.tr('auth_please_wait')
                                      : verifying
                                          ? l10n.tr('auth_back_to_signin')
                                          : registering
                                              ? l10n.tr('auth_signup_btn')
                                              : l10n.tr('auth_signin_btn')),
                                ),
                                if (!verifying) ...[
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _show(registering
                                            ? _AuthStep.signIn
                                            : _AuthStep.signUp),
                                    child: Text(registering
                                        ? l10n.tr('auth_switch_to_signin')
                                        : l10n.tr('auth_switch_to_signup')),
                                  ),
                                ],
                                if (provider.supabaseService.isMockMode) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    l10n.tr('auth_offline_mode_note'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
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

class _AuthHeader extends StatelessWidget {
  final AppLocalizations l10n;

  const _AuthHeader({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CustomPaint(
          painter: _GreenhouseArches(),
          child: Container(
            constraints: const BoxConstraints(minHeight: 233),
            padding: const EdgeInsets.fromLTRB(22, 23, 22, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/figma/logo.png', width: 57, height: 57),
                const SizedBox(height: 7),
                const Text('GreenLand',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                Text(l10n.tr('auth_header_subtitle'),
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GreenhouseArches extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0x3DFFFFFF)
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width - 73, 143);
    for (final radius in [66.0, 49.0, 32.0, 15.0]) {
      final bounds = Rect.fromCircle(center: center, radius: radius);
      final arch = Path()
        ..moveTo(bounds.left, size.height)
        ..lineTo(bounds.left, center.dy)
        ..arcTo(bounds, 3.141592653589793, 3.141592653589793, false)
        ..lineTo(bounds.right, size.height);
      canvas.drawPath(arch, stroke);
    }
  }

  @override
  bool shouldRepaint(_GreenhouseArches oldDelegate) => false;
}
