import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cypcar/core/theme/app_theme.dart';
import 'package:cypcar/features/auth/presentation/providers/auth_provider.dart';
import 'package:cypcar/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:cypcar/features/auth/presentation/widgets/social_login_button.dart';

const _countryCodes = [
  (code: '+90', flag: '🇹🇷', name: 'Türkiye'),
  (code: '+357', flag: '🇨🇾', name: 'Kıbrıs'),
  (code: '+44', flag: '🇬🇧', name: 'İngiltere'),
  (code: '+49', flag: '🇩🇪', name: 'Almanya'),
  (code: '+33', flag: '🇫🇷', name: 'Fransa'),
  (code: '+1', flag: '🇺🇸', name: 'ABD'),
];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  String _countryCode = '+90';
  bool _termsAccepted = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_termsAccepted) {
      setState(() => _error = 'Devam etmek için sözleşmeleri kabul etmelisiniz');
      return;
    }
    setState(() => _error = null);

    await ref.read(authProvider.notifier).register(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: '$_countryCode${_phoneCtrl.text.trim()}',
          password: _passCtrl.text,
        );

    final state = ref.read(authProvider);
    if (state.hasError) {
      setState(() => _error = _parseError(state.error));
    } else if (state.valueOrNull != null && mounted) {
      final email = _emailCtrl.text.trim();
      context.go('/email-verification?email=${Uri.encodeComponent(email)}');
    }
  }

  String _parseError(Object? error) {
    final msg = error.toString();
    if (msg.contains('409') || msg.contains('already') || msg.contains('exist')) {
      return 'Bu e-posta zaten kayıtlı';
    }
    if (msg.contains('phone')) return 'Geçersiz telefon numarası';
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Bağlantı hatası, tekrar deneyin';
    }
    return 'Kayıt olunamadı, tekrar deneyin';
  }

  void _showCountryPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ..._countryCodes.map((c) => ListTile(
                  leading: Text(c.flag,
                      style: const TextStyle(fontSize: 24)),
                  title: Text('${c.name} (${c.code})',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: _countryCode == c.code
                      ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _countryCode = c.code);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFF5F6FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                Text(
                  'Hesap Oluştur',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'CypCar\'a katıl, ilanını ver',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),

                const SizedBox(height: 28),

                // Ad Soyad
                AuthTextField(
                  label: 'Ad Soyad',
                  hint: 'Adınız Soyadınız',
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().length < 6) return 'En az 6 karakter';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email
                AuthTextField(
                  label: 'E-posta',
                  hint: 'ornek@email.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Gerekli';
                    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(v.trim())) return 'Geçersiz e-posta adresi';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Telefon
                Text(
                  'Telefon Numarası',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 8),
                FormField<String>(
                  validator: (v) {
                    final val = _phoneCtrl.text.trim().replaceAll(' ', '');
                    if (val.isEmpty) return 'Gerekli';
                    
                    if (_countryCode == '+90') {
                      if (val.length != 10) return 'Numara 10 hane olmalıdır (5XX...)';
                      if (!val.startsWith('5')) return 'Numara 5 ile başlamalıdır';
                    } else {
                      if (val.length < 7) return 'Geçersiz numara';
                    }
                    return null;
                  },
                  builder: (state) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: state.hasError
                                ? Colors.redAccent.withValues(alpha: 0.5)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.08)),
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Ülke kodu seçici
                              GestureDetector(
                                onTap: _showCountryPicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(14),
                                      bottomLeft: Radius.circular(14),
                                    ),
                                    border: Border(
                                      right: BorderSide(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.black.withValues(alpha: 0.08),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _countryCodes
                                            .firstWhere(
                                                (c) => c.code == _countryCode)
                                            .flag,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _countryCode,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black
                                                  .withValues(alpha: 0.70),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.keyboard_arrow_down_rounded,
                                          size: 16,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38),
                                    ],
                                  ),
                                ),
                              ),
                              // Numara
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneCtrl,
                                  textAlignVertical: TextAlignVertical.center,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (v) => state.didChange(v),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9 ]')),
                                  ],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: false,
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    hintText: '5XX XXX XX XX',
                                    hintStyle: TextStyle(
                                      fontSize: 15,
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.black26,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 22),
                                    errorStyle: const TextStyle(
                                        fontSize: 0, height: 0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            state.errorText ?? '',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Şifre
                AuthTextField(
                  label: 'Şifre',
                  hint: 'En az 6 karakter',
                  controller: _passCtrl,
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Gerekli';
                    if (v.length < 8) return 'En az 8 karakter';
                    if (!v.contains(RegExp(r'[a-zA-Z]'))) return 'En az bir harf içermeli';
                    if (!v.contains(RegExp(r'[0-9]'))) return 'En az bir rakam içermeli';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Şifre tekrar
                AuthTextField(
                  label: 'Şifre Tekrar',
                  hint: '••••••••',
                  controller: _passConfirmCtrl,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _register,
                  validator: (v) {
                    if (v != _passCtrl.text) return 'Şifreler eşleşmiyor';
                    return null;
                  },
                ),

                // Hata mesajı
                if (_error != null) ...[
                  const SizedBox(height: 16),
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
                                fontSize: 13,
                                color: Colors.red,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Sözleşme checkbox
                GestureDetector(
                  onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _termsAccepted,
                          onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                          activeColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.black45,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(text: 'Kaydolarak '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => launchUrl(
                                    Uri.parse('https://orhunkenger.github.io/cypcar-legal/terms'),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                  child: const Text(
                                    'Kullanıcı Sözleşmesi',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: "'ni ve "),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => launchUrl(
                                    Uri.parse('https://orhunkenger.github.io/cypcar-legal/privacy'),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                  child: const Text(
                                    'Gizlilik Politikası',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: "'nı okuduğumu ve kabul ettiğimi onaylıyorum."),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Kayıt Ol butonu
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _register,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Kayıt Ol',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),

                const SizedBox(height: 28),

                // Ayırıcı
                _Divider(isDark: isDark),
                const SizedBox(height: 20),

                SocialLoginButton(provider: SocialProvider.google),
                const SizedBox(height: 12),
                SocialLoginButton(provider: SocialProvider.apple),

                const SizedBox(height: 32),

                // Giriş yap linki
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Zaten hesabın var mı? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Text(
                          'Giriş Yap',
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
                color: isDark ? Colors.white12 : Colors.black12, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('veya',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white30 : Colors.black.withValues(alpha: 0.30))),
        ),
        Expanded(
            child: Divider(
                color: isDark ? Colors.white12 : Colors.black12, thickness: 1)),
      ],
    );
  }
}
