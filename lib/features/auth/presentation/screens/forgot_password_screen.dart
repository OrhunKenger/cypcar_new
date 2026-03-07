import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cypcar/core/theme/app_theme.dart';
import 'package:cypcar/features/auth/data/auth_repository.dart';
import 'package:cypcar/features/auth/presentation/widgets/auth_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  int _step = 0; // 0: email, 1: OTP, 2: yeni şifre

  // Step 0
  final _emailCtrl = TextEditingController();

  // Step 1 - OTP
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  int _countdown = 60;
  Timer? _timer;

  // Step 2
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    _emailCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Geçerli bir e-posta girin');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      _startCountdown();
      setState(() { _step = 1; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Kod gönderilemedi, tekrar deneyin'; _isLoading = false; });
    }
  }

  Future<void> _resend() async {
    if (_countdown > 0) return;
    setState(() => _error = null);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_emailCtrl.text.trim());
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kod tekrar gönderildi'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      setState(() => _error = 'Kod gönderilemedi');
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length < 6) {
      setState(() => _error = '6 haneli kodu eksiksiz girin');
      return;
    }
    setState(() { _step = 2; _error = null; });
  }

  Future<void> _resetPassword() async {
    final pass = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;
    if (pass.length < 8) {
      setState(() => _error = 'Şifre en az 8 karakter olmalı');
      return;
    }
    if (!pass.contains(RegExp(r'[a-zA-Z]')) || !pass.contains(RegExp(r'[0-9]'))) {
      setState(() => _error = 'Şifre en az bir harf ve bir rakam içermeli');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Şifreler eşleşmiyor');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
        _emailCtrl.text.trim(), _otp, pass,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Şifreniz başarıyla sıfırlandı'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      setState(() => _error = _parseError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('400') || msg.contains('Geçersiz')) return 'Kod hatalı veya süresi dolmuş';
    if (msg.contains('404')) return 'Kullanıcı bulunamadı';
    return 'Bir hata oluştu, tekrar deneyin';
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (_step > 0) {
              setState(() { _step--; _error = null; });
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          _step == 0 ? 'Şifremi Unuttum' : _step == 1 ? 'Kod Doğrulama' : 'Yeni Şifre',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _step == 0
                ? _buildEmailStep(isDark)
                : _step == 1
                    ? _buildOtpStep(isDark)
                    : _buildNewPasswordStep(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(bool isDark) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.lock_reset_rounded, color: AppTheme.primary, size: 36),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'E-posta adresini gir',
          style: TextStyle(
            fontSize: 16, color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 20),
        AuthTextField(
          label: 'E-posta',
          hint: 'ornek@email.com',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onEditingComplete: _sendCode,
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorBox(message: _error!),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendCode,
            child: _isLoading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Kod Gönder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildOtpStep(bool isDark) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Center(
          child: Text(
            '${_emailCtrl.text.trim()}\nadresine kod gönderdik',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, color: isDark ? Colors.white54 : Colors.black45, height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 48, height: 56,
              child: KeyboardListener(
                focusNode: FocusNode(), // Sadece klavye olaylarını dinlemek için geçici, TextField odağıyla çakışmaz
                onKeyEvent: (event) {
                  if (event.logicalKey == LogicalKeyboardKey.backspace &&
                      _otpControllers[i].text.isEmpty && i > 0) {
                    _otpFocusNodes[i - 1].requestFocus();
                  }
                },
                child: TextField(
                  controller: _otpControllers[i],
                  focusNode: _otpFocusNodes[i],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center, // Dikeyde tam merkez
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.w800,
                    height: 1.0, // Satır yüksekliğini sabitle
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    contentPadding: EdgeInsets.zero, // İç boşluğu sıfırla ki sığsın
                    fillColor: isDark ? AppTheme.cardDark : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                    ),
                  ),
                  onChanged: (v) => _onOtpChanged(i, v),
                ),
              ),
            );
          }),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          _ErrorBox(message: _error!),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _otp.length < 6 ? null : _verifyOtp,
            child: const Text('Devam Et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: _countdown > 0
              ? Text('Kodu tekrar gönder ($_countdown s)',
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.black38))
              : GestureDetector(
                  onTap: _resend,
                  child: const Text('Kodu Tekrar Gönder',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildNewPasswordStep(bool isDark) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Yeni şifreni belirle',
            style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : Colors.black54)),
        const SizedBox(height: 20),
        AuthTextField(
          label: 'Yeni Şifre',
          hint: '••••••••',
          controller: _newPassCtrl,
          obscure: true,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Şifre Tekrar',
          hint: '••••••••',
          controller: _confirmPassCtrl,
          obscure: true,
          textInputAction: TextInputAction.done,
          onEditingComplete: _resetPassword,
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorBox(message: _error!),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            child: _isLoading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Şifreyi Sıfırla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
