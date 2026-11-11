import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../core/app_text.dart';
import '../../models/app_contact.dart';
import '../../widgets/app_message.dart';
import 'widgets/amount_display.dart';

/// Comprobante de envío (versión demo: no se movió dinero real).
class SendReceiptScreen extends StatelessWidget {
  final AppContact contact;
  final double amount;
  final String message;
  final DateTime dateTime;

  const SendReceiptScreen({
    super.key,
    required this.contact,
    required this.amount,
    required this.message,
    required this.dateTime,
  });

  static const _textDark = Color(0xFF2A2540);
  static const _textGrey = Color(0xFF5E5A70);
  static const _label = Color(0xFF6E6A80);
  static const _divider = Color(0xFFE2E0EA);
  static const _teal = Color(0xFF1BB59F);
  static const _darkOrange = Color(0xFFE25500);

  static const _months = [
    'ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.',
    'jul.', 'ago.', 'sept.', 'oct.', 'nov.', 'dic.',
  ];

  String get _date =>
      '${dateTime.day} ${_months[dateTime.month - 1]} ${dateTime.year}';

  String get _time {
    final h = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final m = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour < 12 ? 'a.m.' : 'p.m.';
    return '$h:$m $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.orange,
        body: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                children: [
                  _buildBanner(context),
                  const SizedBox(height: 10),
                  _buildReceiptCard(context),
                  const SizedBox(height: 16),
                  _buildMoreCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Espacio para tu imagen de cabecera + botón cerrar.
  Widget _buildBanner(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'ypayone',
                style: appFont(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 0,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '¡Enviaste!',
                style: appFont(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: sendPurple,
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
                    const Icon(Icons.share_outlined, color: _teal, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Compartir',
                      style: appFont(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: _teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Distintivo fijo: este comprobante es de prueba.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'DEMO · SIN VALOR',
              style: appFont(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF8A6D00),
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'S/',
                  style: appFont(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amount.toStringAsFixed(2),
                style: appFont(
                  fontSize: 52,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                  height: 1.05,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            contact.maskedName,
            style: appFont(
              fontSize: 21,
              fontWeight: FontWeight.w500,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: _textGrey),
              const SizedBox(width: 6),
              Text(_date, style: appFont(fontSize: 16, color: _textGrey)),
              Container(
                width: 1.5,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: _textGrey,
              ),
              const Icon(Icons.access_time_rounded,
                  size: 17, color: _textGrey),
              const SizedBox(width: 6),
              Text(_time, style: appFont(fontSize: 16, color: _textGrey)),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: _divider),
          const SizedBox(height: 18),
          Text(
            'DATOS DE LA TRANSACCIÓN',
            style: appFont(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _label,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          _row('Nro. de celular', contact.maskedPhone),
          _row('Destino', 'ShitCoin'),
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
          Text(label, style: appFont(fontSize: 16, color: _textDark)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: appFont(fontSize: 16, color: _textDark),
            ),
          ),
        ],
      ),
    );
  }

  /// "Más en ShitCoin" + badge "Nuevo" + espacio para tu imagen.
  Widget _buildMoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: _darkOrange,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Más en ShitCoin',
                style: appFont(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC20E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Nuevo',
                  style: appFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Espacio para tu imagen (la pondrás luego).
          Container(
            height: 168,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.image_outlined,
              size: 40,
              color: Color(0xFFD0CDD9),
            ),
          ),
        ],
      ),
    );
  }
}
