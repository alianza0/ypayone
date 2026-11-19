import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_text.dart';
import '../../core/navigation.dart';
import '../../services/account_prefs_service.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_message.dart';
import 'edit_balance_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static const _textDark = Color(0xFF1F1D2B);
  static const _sectionLabel = Color(0xFF757285);
  static const _muted = Color(0xFF8C899B);
  static const _divider = Color(0xFFF0EEF5);
  static const _purple = Color(0xFF6A1B7A);

  bool _obscurePassword = true;
  String _passwordValue = '••••••••';
  String _vendorCode = '—';

  @override
  void initState() {
    super.initState();
    _loadAccountDetails();
  }

  Future<void> _loadAccountDetails() async {
    final savedPass = await SessionService.lastPassword();
    if (mounted && savedPass != null && savedPass.isNotEmpty) {
      setState(() => _passwordValue = savedPass);
    }

    final cachedVendor = AccountPrefsService.instance.vendorCode;
    if (mounted && cachedVendor != null && cachedVendor.isNotEmpty) {
      setState(() => _vendorCode = cachedVendor);
    }

    final remoteVendor = await AuthService.instance.fetchVendorCode();
    if (remoteVendor != null && remoteVendor.isNotEmpty) {
      await AccountPrefsService.instance.setVendorCode(remoteVendor);
      if (mounted) setState(() => _vendorCode = remoteVendor);
    }
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    showAppMessage(context, '$label copiado.', error: false);
  }

  Future<void> _selectBannerMode(ReceiptBannerMode mode) async {
    await AccountPrefsService.instance.setBannerMode(mode);
    if (mode == ReceiptBannerMode.custom &&
        (AccountPrefsService.instance.customBannerPath == null ||
            AccountPrefsService.instance.customBannerPath!.isEmpty)) {
      if (!mounted) return;
      showAppMessage(
        context,
        'Modo Custom seleccionado. Aquí puedes enlazar tu selector de imagen (image_picker).',
        error: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final rawUsername = user != null
        ? '@${AuthService.instance.usernameOf(user).toLowerCase()}'
        : '@usuario';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AnimatedBuilder(
        animation: AccountPrefsService.instance,
        builder: (context, _) {
          final prefs = AccountPrefsService.instance;

          return Scaffold(
            backgroundColor: const Color(0xFFF4F2FA),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF1F0FA),
                    Color(0xFFF8F0F8),
                    Color(0xFFF0F4FB),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildTopClose(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mi Cuenta',
                              style: appFont(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: _textDark,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gestiona tu perfil y configuraciones maestras.',
                              style: appFont(
                                fontSize: 15,
                                color: _muted,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'DATOS PERSONALES',
                              style: appFont(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _sectionLabel,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _cardContainer(
                              child: Column(
                                children: [
                                  _infoRow(
                                    title: 'Nombre de usuario',
                                    value: rawUsername,
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        color: _muted,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          _copy('Nombre de usuario', rawUsername),
                                    ),
                                  ),
                                  _dividerLine(),
                                  _infoRow(
                                    title: 'Contraseña',
                                    value: _obscurePassword
                                        ? '••••••••'
                                        : _passwordValue,
                                    trailing: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: _muted,
                                        size: 21,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                  ),
                                  _dividerLine(),
                                  _infoRow(
                                    title: 'Código de vendedor',
                                    value: _vendorCode,
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        color: _muted,
                                        size: 20,
                                      ),
                                      onPressed: () => _copy(
                                          'Código de vendedor', _vendorCode),
                                    ),
                                  ),
                                  _dividerLine(),
                                  InkWell(
                                    onTap: () => Navigator.of(context).push(
                                      slideRoute(const EditBalanceScreen()),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 15,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Saldo de cuenta',
                                            style: appFont(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w600,
                                              color: _textDark,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            prefs.formattedBalance,
                                            style: appFont(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: _purple,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            color: _muted,
                                            size: 22,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'VISUALIZACIÓN',
                              style: appFont(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _sectionLabel,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _cardContainer(
                              child: Column(
                                children: [
                                  _switchRow(
                                    title: 'Banners en inicio',
                                    value: prefs.showHomeBanners,
                                    onChanged: (v) =>
                                        prefs.setShowHomeBanners(v),
                                  ),
                                  _dividerLine(),
                                  _switchRow(
                                    title: 'Banner en constancia',
                                    value: prefs.showReceiptBanner,
                                    onChanged: (v) =>
                                        prefs.setShowReceiptBanner(v),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 4, 16, 12),
                                    child: _bannerTabs(prefs.bannerMode),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 16),
                                    child: _bannerPreview(prefs),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopClose() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2A2540).withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.close_rounded,
              color: _textDark,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E4A9E).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _dividerLine() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      color: _divider,
    );
  }

  Widget _infoRow({
    required String title,
    required String value,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
      child: Row(
        children: [
          Text(
            title,
            style: appFont(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: appFont(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _textDark,
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _switchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: appFont(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: _purple,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _bannerTabs(ReceiptBannerMode selected) {
    final entries = <(ReceiptBannerMode, String)>[
      (ReceiptBannerMode.banner1, 'Banner 1'),
      (ReceiptBannerMode.banner2, 'Banner 2'),
      (ReceiptBannerMode.custom, 'Custom'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final entry in entries)
            Expanded(
              child: GestureDetector(
                onTap: () => _selectBannerMode(entry.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected == entry.$1 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: selected == entry.$1
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.$2,
                    style: appFont(
                      fontSize: 13.5,
                      fontWeight: selected == entry.$1
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected == entry.$1 ? _textDark : _muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bannerPreview(AccountPrefsService prefs) {
    if (prefs.bannerMode == ReceiptBannerMode.custom &&
        prefs.customBannerPath != null &&
        prefs.customBannerPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 138,
          width: double.infinity,
          child: Image.file(
            File(prefs.customBannerPath!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final isBanner1 = prefs.bannerMode == ReceiptBannerMode.banner1;
    final isCustom = prefs.bannerMode == ReceiptBannerMode.custom;

    return Container(
      height: 138,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE8F2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCustom
                      ? [const Color(0xFF4A148C), const Color(0xFF7B1FA2)]
                      : isBanner1
                          ? [const Color(0xFF3E1F14), const Color(0xFF1D120E)]
                          : [const Color(0xFF005C53), const Color(0xFF002B27)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(12),
              alignment: Alignment.bottomLeft,
              child: Text(
                isCustom
                    ? 'Banner Custom'
                    : (isBanner1 ? 'Banner 1' : 'Banner 2'),
                style: appFont(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 9,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isCustom
                        ? 'Imagen personalizada'
                        : (isBanner1
                            ? 'Promo activa #1'
                            : 'Promo activa #2'),
                    maxLines: 2,
                    style: appFont(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCustom
                        ? 'Sube una foto para constancia'
                        : 'Se mostrará en constancia',
                    maxLines: 2,
                    style: appFont(
                      fontSize: 11.5,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}