import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ReceiptBannerMode { banner1, banner2, custom }

/// Estado reactivo y persistente para Mi Cuenta, saldo y banners.
class AccountPrefsService extends ChangeNotifier {
  AccountPrefsService._();
  static final AccountPrefsService instance = AccountPrefsService._();

  static const _kHomeBanners = 'pref_home_banners';
  static const _kReceiptBanner = 'pref_receipt_banner';
  static const _kBannerMode = 'pref_receipt_banner_mode';
  static const _kCustomBannerPath = 'pref_custom_banner_path';
  static const _kBalance = 'pref_account_balance';
  static const _kCachedVendorCode = 'pref_cached_vendor_code';

  bool _loaded = false;
  bool _showHomeBanners = true;
  bool _showReceiptBanner = true;
  ReceiptBannerMode _bannerMode = ReceiptBannerMode.banner1;
  String? _customBannerPath;
  double _balance = -80.0;
  String? _vendorCode;

  bool get isLoaded => _loaded;
  bool get showHomeBanners => _showHomeBanners;
  bool get showReceiptBanner => _showReceiptBanner;
  ReceiptBannerMode get bannerMode => _bannerMode;
  String? get customBannerPath => _customBannerPath;
  double get balance => _balance;
  String? get vendorCode => _vendorCode;

  String get formattedBalance {
    final isNegative = _balance < 0;
    final absVal = _balance.abs().toStringAsFixed(2);
    return isNegative ? 'S/ -$absVal' : 'S/ $absVal';
  }

  /// Formato compacto para el Home ("S/ -80.00", "S/ 0.00", "S/ 25.50").
  String get homeBalanceText => formattedBalance;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _showHomeBanners = prefs.getBool(_kHomeBanners) ?? true;
    _showReceiptBanner = prefs.getBool(_kReceiptBanner) ?? true;

    final modeName = prefs.getString(_kBannerMode);
    _bannerMode = ReceiptBannerMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => ReceiptBannerMode.banner1,
    );

    _customBannerPath = prefs.getString(_kCustomBannerPath);
    _balance = prefs.getDouble(_kBalance) ?? -80.0;
    _vendorCode = prefs.getString(_kCachedVendorCode);
    _loaded = true;
    notifyListeners();
  }

  Future<void> setShowHomeBanners(bool value) async {
    _showHomeBanners = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHomeBanners, value);
  }

  Future<void> setShowReceiptBanner(bool value) async {
    _showReceiptBanner = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReceiptBanner, value);
  }

  Future<void> setBannerMode(ReceiptBannerMode mode) async {
    _bannerMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBannerMode, mode.name);
  }

  Future<void> setCustomBannerPath(String? path) async {
    _customBannerPath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.isEmpty) {
      await prefs.remove(_kCustomBannerPath);
    } else {
      await prefs.setString(_kCustomBannerPath, path);
    }
  }

  Future<void> setBalance(double newBalance) async {
    _balance = newBalance;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kBalance, newBalance);
  }

  Future<void> setVendorCode(String? code) async {
    final clean = code?.trim();
    _vendorCode = (clean == null || clean.isEmpty) ? null : clean;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_vendorCode == null) {
      await prefs.remove(_kCachedVendorCode);
    } else {
      await prefs.setString(_kCachedVendorCode, _vendorCode!);
    }
  }
}