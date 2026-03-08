import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cypcar/core/theme/app_theme.dart';
import 'package:cypcar/features/auth/domain/models/user_model.dart';
import 'package:cypcar/features/auth/presentation/providers/auth_provider.dart';
import 'package:cypcar/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:cypcar/features/profile/data/profile_repository.dart';
import 'package:cypcar/features/profile/domain/models/profile_model.dart';
import 'package:cypcar/features/profile/presentation/providers/profile_provider.dart';
import 'package:cypcar/shared/models/app_settings_model.dart';
import 'package:cypcar/shared/models/exchange_rate_model.dart';
import 'package:cypcar/shared/providers/app_settings_provider.dart';
import 'package:cypcar/shared/providers/exchange_rate_provider.dart';
import 'package:cypcar/shared/widgets/listing_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool? _isBlocked;
  bool _blockLoading = false;

  bool _isOwn(UserModel? me) => me != null && me.id == widget.userId;

  Future<void> _refreshAll() async {
    ref.invalidate(profileProvider(widget.userId));
    if (_isOwn(ref.read(authProvider).valueOrNull)) {
      await ref.read(authProvider.notifier).refresh();
    }
  }

  // ── Block ─────────────────────────────────────────────────────────────

  Future<void> _toggleBlock() async {
    if (_blockLoading) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_isBlocked == true ? 'Engeli Kaldır' : 'Kullanıcıyı Engelle'),
        content: Text(
          _isBlocked == true
              ? 'Bu kullanıcının engelini kaldırmak istiyor musunuz?'
              : 'Bu kullanıcıyı engellemek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            child: const Text('Evet'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _blockLoading = true);
    try {
      final newState =
          await ref.read(profileRepositoryProvider).toggleBlock(widget.userId);
      if (mounted) {
        setState(() => _isBlocked = newState);
        if (newState) context.pop();
      }
    } catch (e) {
      if (mounted) _showError(_parseError(e));
    } finally {
      if (mounted) setState(() => _blockLoading = false);
    }
  }

  // ── Photo ─────────────────────────────────────────────────────────────

  Future<void> _showPhotoOptions(bool isDark, UserModel? me) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(isDark),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndUploadPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeri'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndUploadPhoto(ImageSource.gallery);
              },
            ),
            if (me?.profilePhotoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Fotoğrafı Kaldır',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ref.read(profileRepositoryProvider).deletePhoto();
                    await _refreshAll();
                    if (mounted) _showSuccess('Fotoğraf kaldırıldı');
                  } catch (e) {
                    if (mounted) _showError(_parseError(e));
                  }
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    if (!kIsWeb) {
      final permission = source == ImageSource.camera ? Permission.camera : Permission.photos;
      final status = await permission.request();
      if (!status.isGranted && !status.isLimited) {
        if (mounted) _showPermissionDialog(source);
        return;
      }
    }

    final file = await ImagePicker()
        .pickImage(source: source, imageQuality: 80, maxWidth: 800);
    if (file == null) return;
    try {
      await ref.read(profileRepositoryProvider).uploadPhoto(file);
      await _refreshAll();
      if (mounted) _showSuccess('Fotoğraf güncellendi');
    } catch (e) {
      if (mounted) _showError(_parseError(e));
    }
  }

  void _showPermissionDialog(ImageSource source) {
    final izinTuru = source == ImageSource.camera ? 'kamera' : 'galeri';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İzin Gerekli'),
        content: Text(
          'Fotoğraf eklemek için $izinTuru iznine ihtiyacımız var. Ayarlar\'dan izin verebilirsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text('Ayarlara Git',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  // ── Edit Sheets ───────────────────────────────────────────────────────

  Future<void> _showNameSheet(bool isDark, String current) async {
    final ctrl = TextEditingController(text: current);
    await _showSimpleSheet(
      isDark: isDark,
      title: 'Ad Soyad',
      fields: [_FieldCfg(label: 'Ad Soyad', controller: ctrl)],
      onSave: () async {
        final v = ctrl.text.trim();
        if (v.length < 2) throw Exception('En az 2 karakter');
        await ref.read(profileRepositoryProvider).updateName(v);
        await _refreshAll();
      },
    );
    ctrl.dispose();
  }

  Future<void> _showWhatsAppSheet(bool isDark, String? current) async {
    final ctrl = TextEditingController(text: current ?? '');
    await _showSimpleSheet(
      isDark: isDark,
      title: 'WhatsApp Numarası',
      fields: [
        _FieldCfg(
          label: 'WhatsApp',
          hint: '+90 5XX XXX XX XX',
          controller: ctrl,
          keyboardType: TextInputType.phone,
        )
      ],
      onSave: () async {
        final v = ctrl.text.trim();
        await ref
            .read(profileRepositoryProvider)
            .updateWhatsapp(v.isEmpty ? null : v);
        await _refreshAll();
      },
    );
    ctrl.dispose();
  }

  Future<void> _showEmailSheet(bool isDark, String current) async {
    final emailCtrl = TextEditingController(text: current);
    final passCtrl = TextEditingController();
    await _showSimpleSheet(
      isDark: isDark,
      title: 'E-posta Değiştir',
      fields: [
        _FieldCfg(
          label: 'Yeni E-posta',
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        _FieldCfg(label: 'Şifreniz', controller: passCtrl, obscure: true),
      ],
      onSave: () async {
        await ref
            .read(profileRepositoryProvider)
            .changeEmail(emailCtrl.text.trim(), passCtrl.text);
        await _refreshAll();
      },
    );
    emailCtrl.dispose();
    passCtrl.dispose();
  }

  Future<void> _showPhoneSheet(bool isDark, String current) async {
    final phoneCtrl = TextEditingController(text: current);
    final passCtrl = TextEditingController();
    await _showSimpleSheet(
      isDark: isDark,
      title: 'Telefon Değiştir',
      fields: [
        _FieldCfg(
          label: 'Yeni Telefon',
          hint: '+90 5XX XXX XX XX',
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
        ),
        _FieldCfg(label: 'Şifreniz', controller: passCtrl, obscure: true),
      ],
      onSave: () async {
        await ref
            .read(profileRepositoryProvider)
            .changePhone(phoneCtrl.text.trim(), passCtrl.text);
        await _refreshAll();
      },
    );
    phoneCtrl.dispose();
    passCtrl.dispose();
  }

  Future<void> _showPasswordSheet(bool isDark) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    await _showSimpleSheet(
      isDark: isDark,
      title: 'Şifre Değiştir',
      fields: [
        _FieldCfg(label: 'Mevcut Şifre', controller: currentCtrl, obscure: true),
        _FieldCfg(label: 'Yeni Şifre', controller: newCtrl, obscure: true),
        _FieldCfg(
            label: 'Yeni Şifre (Tekrar)',
            controller: confirmCtrl,
            obscure: true),
      ],
      extraValidation: () {
        if (newCtrl.text != confirmCtrl.text) return 'Şifreler eşleşmiyor';
        if (newCtrl.text.length < 8) return 'En az 8 karakter';
        if (!RegExp(r'[a-zA-Z]').hasMatch(newCtrl.text)) return 'En az bir harf içermeli';
        if (!RegExp(r'[0-9]').hasMatch(newCtrl.text)) return 'En az bir rakam içermeli';
        return null;
      },
      onSave: () async {
        await ref
            .read(profileRepositoryProvider)
            .changePassword(currentCtrl.text, newCtrl.text);
      },
    );
    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  Future<void> _showDeleteAccountSheet(bool isDark) async {
    final passCtrl = TextEditingController();
    String? error;
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(isDark),
                const Text(
                  'Hesabı Sil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Bu işlem geri alınamaz. Tüm ilanlarınız ve verileriniz kalıcı olarak silinecek.',
                    style: TextStyle(fontSize: 13, color: Colors.red),
                  ),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Şifrenizi Girin',
                  hint: '••••••••',
                  controller: passCtrl,
                  obscure: true,
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: loading
                        ? null
                        : () async {
                            setS(() {
                              loading = true;
                              error = null;
                            });
                            try {
                              await ref
                                  .read(profileRepositoryProvider)
                                  .deleteAccount(passCtrl.text);
                              await ref.read(authProvider.notifier).logout();
                              if (mounted) context.go('/');
                            } catch (e) {
                              setS(() {
                                loading = false;
                                error = _parseError(e);
                              });
                            }
                          },
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Hesabı Kalıcı Olarak Sil',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    passCtrl.dispose();
  }

  // ── Generic Sheet ─────────────────────────────────────────────────────

  Future<void> _showSimpleSheet({
    required bool isDark,
    required String title,
    required List<_FieldCfg> fields,
    String? Function()? extraValidation,
    required Future<void> Function() onSave,
  }) async {
    String? error;
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(isDark),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                ...fields.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AuthTextField(
                        label: f.label,
                        hint: f.hint ?? f.label,
                        controller: f.controller,
                        keyboardType: f.keyboardType ?? TextInputType.text,
                        obscure: f.obscure,
                        textInputAction: f == fields.last
                            ? TextInputAction.done
                            : TextInputAction.next,
                      ),
                    )),
                if (error != null) ...[
                  const SizedBox(height: 4),
                  Text(error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (extraValidation != null) {
                              final err = extraValidation();
                              if (err != null) {
                                setS(() => error = err);
                                return;
                              }
                            }
                            setS(() {
                              loading = true;
                              error = null;
                            });
                            try {
                              await onSave();
                              if (mounted) {
                                Navigator.pop(ctx);
                                _showSuccess('Güncellendi');
                              }
                            } catch (e) {
                              setS(() {
                                loading = false;
                                error = _parseError(e);
                              });
                            }
                          },
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Kaydet',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('401') ||
        msg.contains('password') ||
        msg.contains('credential')) return 'Şifre hatalı';
    if (msg.contains('409') ||
        msg.contains('already') ||
        msg.contains('exist')) return 'Bu bilgi zaten kullanımda';
    if (msg.contains('422')) return 'Geçersiz bilgi girdiniz';
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Bağlantı hatası';
    }
    return 'Bir hata oluştu, tekrar deneyin';
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _sheetHandle(bool isDark) => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white24 : Colors.black12,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  String _memberSinceText(DateTime date) {
    final months =
        (DateTime.now().year - date.year) * 12 + (DateTime.now().month - date.month);
    if (months < 1) return 'Bu ay katıldı';
    if (months < 12) return '$months ay üye';
    final years = months ~/ 12;
    return '$years yıl üye';
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}B';
    return n.toString();
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(profileProvider(widget.userId));
    final exchangeRate = ref.watch(exchangeRateProvider).valueOrNull;
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final me = ref.watch(authProvider).valueOrNull;
    final isOwn = _isOwn(me);

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : const Color(0xFFF5F6FA),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildErrorState(context, isDark),
        data: (profile) => _buildContent(
            context, isDark, profile, isOwn, me, exchangeRate, settings),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_off_outlined,
                      size: 56,
                      color: isDark ? Colors.white24 : Colors.black26),
                  const SizedBox(height: 16),
                  Text(
                    'Profil bulunamadı',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Geri Dön'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isDark,
    PublicProfile profile,
    bool isOwn,
    UserModel? me,
    ExchangeRate? exchangeRate,
    AppSettings? settings,
  ) {
    return CustomScrollView(
      slivers: [
        // ── AppBar ──────────────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          backgroundColor:
              isDark ? AppTheme.backgroundDark : const Color(0xFFF5F6FA),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(
            isOwn ? 'Profilim' : profile.fullName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          actions: [
            if (isOwn && me != null)
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _showSettingsSheet(isDark, me),
              )
            else if (!isOwn)
              _blockLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (val) {
                        if (val == 'block') _toggleBlock();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(
                                _isBlocked == true
                                    ? Icons.person_add_outlined
                                    : Icons.block_outlined,
                                size: 18,
                                color: _isBlocked == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isBlocked == true
                                    ? 'Engeli Kaldır'
                                    : 'Kullanıcıyı Engelle',
                                style: TextStyle(
                                  color: _isBlocked == true
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
          ],
        ),

        // ── Header ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildHeader(isDark, profile, isOwn, me),
        ),

        // ── Listings title ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            child: Row(
              children: [
                Text(
                  'İlanlar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${profile.totalListings}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Listings grid ────────────────────────────────────────────────
        if (profile.listings.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.car_rental_outlined,
                      size: 52,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Henüz ilan yok',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final listing = profile.listings[i];
                  final badge = isOwn ? _statusBadge(listing.status) : null;
                  if (badge == null) {
                    return ListingCard(
                      listing: listing,
                      exchangeRate: exchangeRate,
                      settings: settings,
                    );
                  }
                  return Stack(
                    children: [
                      Opacity(
                        opacity: 0.5,
                        child: ListingCard(
                          listing: listing,
                          exchangeRate: exchangeRate,
                          settings: settings,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: badge,
                      ),
                    ],
                  );
                },
                childCount: profile.listings.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }

  Widget _buildHeader(
      bool isDark, PublicProfile profile, bool isOwn, UserModel? me) {
    final textSecondary = isDark ? Colors.white38 : Colors.black38;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: profile.profilePhotoUrl != null && profile.profilePhotoUrl!.isNotEmpty
                    ? () => _showPhotoFullscreen(profile.profilePhotoUrl!)
                    : null,
                child: _buildAvatar(profile.fullName, profile.profilePhotoUrl, 84),
              ),
              if (isOwn)
                GestureDetector(
                  onTap: () => _showPhotoOptions(isDark, me),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppTheme.backgroundDark
                            : const Color(0xFFF5F6FA),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // İsim
          Text(
            profile.fullName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Üyelik tarihi
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: textSecondary),
              const SizedBox(width: 4),
              Text(
                _memberSinceText(profile.memberSince),
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      isDark, 'İlan', _formatCount(profile.totalListings))),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(isDark, 'Görüntülenme',
                      _formatCount(profile.totalViews))),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _statusBadge(String status) {
    switch (status) {
      case 'PENDING_REVIEW':
        return _badge('İnceleniyor', const Color(0xFFF59E0B));
      case 'REJECTED':
        return _badge('Reddedildi', Colors.red);
      case 'EXPIRED':
        return _badge('Süresi Doldu', Colors.grey);
      default:
        return null;
    }
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  void _showPhotoFullscreen(String photoUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                width: 280,
                height: 280,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: -12,
              right: -12,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String fullName, String? photoUrl, double size) {
    final initials = fullName
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _avatarFallback(initials, size),
          errorWidget: (_, __, ___) => _avatarFallback(initials, size),
        ),
      );
    }
    return _avatarFallback(initials, size);
  }

  Widget _avatarFallback(String initials, double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.33,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );

  Widget _buildStatCard(bool isDark, String label, String value) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      );

  Future<void> _showSettingsSheet(bool isDark, UserModel me) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.backgroundDark : const Color(0xFFF5F6FA),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _sheetHandle(isDark),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'Ayarlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: _buildSettingsSection(ctx, isDark, me),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
      BuildContext context, bool isDark, UserModel me) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Profil Bilgileri
          _sectionLabel('Profil Bilgileri', isDark),
          const SizedBox(height: 8),
          _settingsGroup(isDark, [
            _TileData(
              icon: Icons.person_outline_rounded,
              label: 'Ad Soyad',
              value: me.fullName,
              onTap: () => _showNameSheet(isDark, me.fullName),
            ),
            _TileData(
              icon: Icons.chat_outlined,
              label: 'WhatsApp',
              value: me.whatsappNumber ?? 'Eklenmedi',
              onTap: () => _showWhatsAppSheet(isDark, me.whatsappNumber),
            ),
          ]),

          const SizedBox(height: 20),

          // Hesap
          _sectionLabel('Hesap', isDark),
          const SizedBox(height: 8),
          _settingsGroup(isDark, [
            _TileData(
              icon: Icons.email_outlined,
              label: 'E-posta',
              value: me.email,
              onTap: () => _showEmailSheet(isDark, me.email),
            ),
            _TileData(
              icon: Icons.phone_outlined,
              label: 'Telefon',
              value: me.phone ?? 'Eklenmedi',
              onTap: () => _showPhoneSheet(isDark, me.phone ?? ''),
            ),
            _TileData(
              icon: Icons.lock_outline_rounded,
              label: 'Şifre',
              value: '••••••••',
              onTap: () => _showPasswordSheet(isDark),
            ),
          ]),

          const SizedBox(height: 20),

          // Çıkış & Sil
          const SizedBox(height: 20),

          // Hukuki
          _sectionLabel('Hukuki', isDark),
          const SizedBox(height: 8),
          _settingsGroup(isDark, [
            _TileData(
              icon: Icons.description_outlined,
              label: 'Kullanıcı Sözleşmesi',
              onTap: () => launchUrl(
                Uri.parse('https://orhunkenger.github.io/cypcar-legal/terms'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            _TileData(
              icon: Icons.privacy_tip_outlined,
              label: 'Gizlilik Politikası',
              onTap: () => launchUrl(
                Uri.parse('https://orhunkenger.github.io/cypcar-legal/privacy'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // Çıkış & Sil
          _settingsGroup(isDark, [
            _TileData(
              icon: Icons.logout_rounded,
              label: 'Çıkış Yap',
              color: Colors.red,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Çıkış Yap'),
                    content: const Text(
                        'Hesabınızdan çıkmak istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary),
                        child: const Text('Çıkış Yap'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(authProvider.notifier).logout();
                  if (mounted) context.go('/');
                }
              },
            ),
            _TileData(
              icon: Icons.delete_outline_rounded,
              label: 'Hesabı Sil',
              color: Colors.red.withValues(alpha: 0.65),
              onTap: () => _showDeleteAccountSheet(isDark),
            ),
          ]),
        ],
      );
  }

  Widget _sectionLabel(String text, bool isDark) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      );

  Widget _settingsGroup(bool isDark, List<_TileData> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            _buildTileWidget(isDark, tiles[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildTileWidget(bool isDark, _TileData tile) {
    final labelColor =
        tile.color ?? (isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87);
    final valueColor = isDark ? Colors.white38 : Colors.black38;
    final iconColor =
        tile.color ?? (isDark ? Colors.white60 : Colors.black54);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: tile.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(tile.icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tile.label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: labelColor),
                  ),
                  if (tile.value != null)
                    Text(
                      tile.value!,
                      style: TextStyle(fontSize: 12, color: valueColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _TileData {
  final IconData icon;
  final String label;
  final String? value;
  final Color? color;
  final VoidCallback onTap;

  const _TileData({
    required this.icon,
    required this.label,
    this.value,
    this.color,
    required this.onTap,
  });
}

class _FieldCfg {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;

  const _FieldCfg({
    required this.label,
    this.hint,
    required this.controller,
    this.keyboardType,
    this.obscure = false,
  });
}
