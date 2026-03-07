import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cypcar/core/theme/app_theme.dart';
import 'package:cypcar/features/auth/presentation/providers/auth_provider.dart';
import 'package:cypcar/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:cypcar/features/auth/presentation/widgets/social_login_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _error = null);

    await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );

    final state = ref.read(authProvider);
    if (state.hasError) {
      setState(() => _error = _parseError(state.error));
    } else if (state.valueOrNull != null && mounted) {
      context.go('/');
    }
  }

  String _parseError(Object? error) {
    final msg = error.toString();
    if (msg.contains('401') || msg.contains('credentials') || msg.contains('password')) {
      return 'E-posta veya şifre hatalı';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Bağlantı hatası, tekrar deneyin';
    }
    return 'Giriş yapılamadı, tekrar deneyin';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Logo & başlık
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/app_logo.png',
                        height: 160,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'CypCar',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kıbrıs\'ın Araç Pazarı',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Giriş Yap',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hesabına giriş yaparak devam et',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),

                const SizedBox(height: 28),

                // Email
                AuthTextField(
                  label: 'E-posta',
                  hint: 'ornek@email.com',
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => _passFocus.requestFocus(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Gerekli';
                    if (!v.contains('@')) return 'Geçersiz e-posta';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Şifre
                AuthTextField(
                  label: 'Şifre',
                  hint: '••••••••',
                  controller: _passCtrl,
                  focusNode: _passFocus,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _login,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Gerekli';
                    if (v.length < 6) return 'En az 6 karakter';
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // Şifremi unuttum
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Şifremi Unuttum',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),

                // Hata mesajı
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.red, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Giriş Yap butonu
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Giriş Yap',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),

                const SizedBox(height: 28),

                // Ayırıcı
                _Divider(isDark: isDark),

                const SizedBox(height: 20),

                // Google
                SocialLoginButton(provider: SocialProvider.google),
                const SizedBox(height: 12),

                // Apple
                SocialLoginButton(provider: SocialProvider.apple),

                const SizedBox(height: 32),

                // Kayıt ol linki
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hesabın yok mu? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: const Text(
                          'Kayıt Ol',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark ? Colors.white12 : Colors.black12,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'veya',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white30 : Colors.black.withValues(alpha: 0.30),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark ? Colors.white12 : Colors.black12,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
