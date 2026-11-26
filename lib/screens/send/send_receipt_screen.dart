import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_text.dart';
import '../../models/app_contact.dart';
import '../../services/account_prefs_service.dart';
import '../../widgets/app_message.dart';

/// Comprobante de envío con diseño actualizado.
class SendReceiptScreen extends StatelessWidget {
  final AppContact contact;
  final double amount;
  final String message;
  final DateTime dateTime;
  final String destination;

  const SendReceiptScreen({
    super.key,
    required this.contact,
    required this.amount,
    required this.message,
    required this.dateTime,
    this.destination = 'Yape',
  });

  static const _bgPurple = Color(0xFF742384);
  static const _cardDarkPurple = Color(0xFF5D186B);
  static const _titlePurple = Color(0xFF742384);
  static const _textDark = Color(0xFF2A2540);
  static const _textGrey = Color(0xFF5E5A70);
  static const _label = Color(0xFF6E6A80);
  static const _divider = Color(0xFFE9E7F0);
  static const _teal = Color(0xFF1BB59F);
  static const _codeBoxBg = Color(0xFFF1EFF6);

  static const _months = [
    'ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.',
    'jul.', 'ago.', 'sept.', 'oct.', 'nov.', 'dic.',
  ];

  bool get _esYape => destination.trim().toLowerCase() == 'yape';

  /// En Yape muestra primer nombre + 3 letras del primer apellido ("Rosa Fab*").
  /// En otros bancos muestra el nombre tal cual llegó del servidor.
  String get _displayName => _esYape ? contact.maskedName : contact.name;

  /// Entero sin decimales ("13"); con decimales siempre dos ("4.50").
  String get _amountText => amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);

  String get _date {
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$day ${_months[dateTime.month - 1]} ${dateTime.year}';
  }

  String get _time {
    final h = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final m = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour < 12 ? 'a.m.' : 'p.m.';
    return '$h:$m $suffix';
  }

  /// 3 dígitos estables derivados del timestamp de la operación.
  List<String> get _securityDigits {
    final seed = (dateTime.millisecondsSinceEpoch ~/ 1000) % 900 + 100;
    return seed.toString().split('');
  }

  /// Nro. de operación de 8 dígitos estable para este comprobante.
  String get _operationNumber {
    final seed = 10000000 + (dateTime.millisecondsSinceEpoch % 89999999);
    return seed.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AnimatedBuilder(
        animation: AccountPrefsService.instance,
        builder: (context, _) {
          final prefs = AccountPrefsService.instance;

          return Scaffold(
            backgroundColor: _bgPurple,
            body: SingleChildScrollView(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: Column(
                    children: [
                      _buildBanner(context, prefs),
                      const SizedBox(height: 12),
                      _buildReceiptCard(context),
                      if (prefs.showReceiptBanner) ...[
                        const SizedBox(height: 16),
                        _buildMoreCard(context),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Banner superior configurable desde Mi Cuenta + botón cerrar.
  Widget _buildBanner(BuildContext context, AccountPrefsService prefs) {
    Widget bannerContent;

    if (prefs.bannerMode == ReceiptBannerMode.custom &&
        prefs.customBannerPath != null &&
        prefs.customBannerPath!.isNotEmpty) {
      bannerContent = Image.file(
        File(prefs.customBannerPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (prefs.bannerMode == ReceiptBannerMode.banner2) {
      bannerContent = Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF005C53), Color(0xFF002B27)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'BANNER 2 · YPAYONE',
          style: appFont(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.92),
            letterSpacing: -0.5,
          ),
        ),
      );
    } else {
      bannerContent = Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5A1668), Color(0xFF832794), Color(0xFF5A1668)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'yape',
          style: appFont(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.95),
            letterSpacing: -1,
          ),
        ),
      );
    }

    return SizedBox(
      height: 155,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: bannerContent,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.24),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context) {
    final digits = _securityDigits;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado: ¡Yapeaste! + Compartir
          Row(
            children: [
              Text(
                '¡Yapeaste!',
                style: appFont(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _titlePurple,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => showAppMessage(
                  context,
                  'Compartir estará disponible pronto.',
                  error: false,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.share_outlined, color: _teal, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Compartir',
                      style: appFont(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Monto: S/ 13
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'S/',
                  style: appFont(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _amountText,
                style: appFont(
                  fontSize: 50,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                  height: 1.05,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Nombre del titular (enmascarado si es Yape; completo si es otro banco)
          Text(
            _displayName,
            style: appFont(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 10),

          // Fecha y hora
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 15, color: _textGrey),
              const SizedBox(width: 6),
              Text(_date, style: appFont(fontSize: 15, color: _textGrey)),
              Container(
                width: 1.2,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: const Color(0xFFB5B2C2),
              ),
              const Icon(Icons.access_time_rounded,
                  size: 16, color: _textGrey),
              const SizedBox(width: 6),
              Text(_time, style: appFont(fontSize: 15, color: _textGrey)),
            ],
          ),

          const SizedBox(height: 18),
          Container(height: 1, color: _divider),
          const SizedBox(height: 14),

          // CÓDIGO DE SEGURIDAD + 3 casillas
          Row(
            children: [
              Text(
                'CÓDIGO DE SEGURIDAD',
                style: appFont(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _label,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _teal,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'i',
                  style: appFont(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
              const Spacer(),
              for (int i = 0; i < digits.length; i++) ...[
                Container(
                  width: 30,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _codeBoxBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    digits[i],
                    style: appFont(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                ),
                if (i < digits.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),

          const SizedBox(height: 14),
          Container(height: 1, color: _divider),
          const SizedBox(height: 16),

          // DATOS DE LA TRANSACCIÓN
          Text(
            'DATOS DE LA TRANSACCIÓN',
            style: appFont(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _label,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _row('Nro. de celular', contact.maskedPhone),
          _row('Destino', destination),
          _row('Nro. de operación', _operationNumber),
          if (message.isNotEmpty) _row('Mensaje', message),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: appFont(fontSize: 15.5, color: _textDark)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: appFont(
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: _cardDarkPurple,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Más en Yape',
                style: appFont(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC20E),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Nuevo',
                  style: appFont(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3ECF8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 46,
                      color: _bgPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Aprovecha tu',
                        style: appFont(
                          fontSize: 13.5,
                          color: _textDark,
                        ),
                      ),
                      Text(
                        'CRÉDITO',
                        style: appFont(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _textDark,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'preaprobado',
                        style: appFont(
                          fontSize: 14,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => showAppMessage(
                          context,
                          'Créditos estará disponible pronto.',
                          error: false,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Ir a Créditos >',
                            style: appFont(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}