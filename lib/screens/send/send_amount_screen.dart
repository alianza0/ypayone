import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_text.dart';
import '../../core/navigation.dart';
import '../../models/app_contact.dart';
import '../../services/account_prefs_service.dart';
import '../../widgets/app_message.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/skeleton_box.dart';
import '../settings/cuentas_vinculadas_screen.dart';
import 'send_receipt_screen.dart';
import 'widgets/amount_display.dart';
import 'widgets/sending_overlay.dart';

/// Pantalla "Enviar a": monto, mensaje y botones.
class SendAmountScreen extends StatefulWidget {
  final AppContact contact;

  const SendAmountScreen({super.key, required this.contact});

  /// Límite diario (provisional, luego vendrá de Firebase).
  static const double dailyLimit = 500;

  @override
  State<SendAmountScreen> createState() => _SendAmountScreenState();
}

class _SendAmountScreenState extends State<SendAmountScreen> {
  static const _keyServerUrl = 'ypayone_server_url_v1';
  static const _defaultServerUrl = 'http://192.168.0.104:3000';

  final _amountCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  final _messageCtrl = TextEditingController();

  /// Se mantiene en true hasta que termine la consulta del titular en el servidor.
  bool _loading = true;
  static const _reveal = Duration(milliseconds: 350);

  late String _displayedTitle;
  List<String> _otrasEntidades = [];
  bool _sinYape = false;

  static const _textDark = Color(0xFF2A2540);
  static const _chipBg = Color(0xFFF1EFF8);
  static const _divider = Color(0xFFE2E0EA);
  static const _disabledText = Color(0xFFBDBAC9);
  static const _error = Color(0xFFD64545);

  String get _numeroLimpio =>
      widget.contact.phone.replaceAll(RegExp(r'\D'), '');

  String _formatearCelular(String raw) {
    final digitos = raw.replaceAll(RegExp(r'\D'), '');
    if (digitos.length == 9) {
      return '${digitos.substring(0, 3)} ${digitos.substring(3, 6)} ${digitos.substring(6)}';
    }
    return raw;
  }

  Future<String> _obtenerServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    var url = (prefs.getString(_keyServerUrl) ?? _defaultServerUrl).trim();
    if (url.isEmpty) url = _defaultServerUrl;
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    return url;
  }

  Future<Map<String, dynamic>?> _llamarBuscarContacto({
    required String numero,
    String? bancoForzado,
  }) async {
    try {
      final baseUrl = await _obtenerServerUrl();
      final res = await http
          .post(
            Uri.parse('$baseUrl/buscar-contacto'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'numero': numero.trim(),
              'bancoForzado': bancoForzado,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  @override
  void initState() {
    super.initState();
    _displayedTitle = widget.contact.name.trim().isNotEmpty
        ? widget.contact.name.trim()
        : _formatearCelular(_numeroLimpio);
    _amountCtrl.addListener(() => setState(() {}));
    _consultarTitularEnServidor();
  }

  Future<void> _consultarTitularEnServidor() async {
    final numero = _numeroLimpio;
    if (numero.length == 9) {
      final cuentas = await CuentasVinculadasStorage.obtenerCuentas();
      final activaId = await CuentasVinculadasStorage.obtenerCuentaActivaId();
      final cuentaActiva = cuentas.where((c) => c.id == activaId).firstOrNull ??
          (cuentas.isNotEmpty ? cuentas.first : null);

      final tieneCupo = await LimiteBusquedasStorage.consumirBusquedaHoy(
        cuentaActiva?.dni,
      );

      if (!mounted) return;

      if (!tieneCupo) {
        _displayedTitle = _formatearCelular(numero);
        _sinYape = true;
        showAppMessage(
          context,
          'Límite de ${LimiteBusquedasStorage.limiteDiario}/${LimiteBusquedasStorage.limiteDiario} búsquedas alcanzado hoy para este DNI. Se reinicia a las 00:00.',
          error: true,
        );
      } else {
        final data = await _llamarBuscarContacto(
          numero: numero,
          bancoForzado: null,
        );
        if (!mounted) return;

        final success = data?['success'] == true;
        final nombreRaw = data?['nombre']?.toString().trim() ?? '';

        if (success &&
            nombreRaw.isNotEmpty &&
            nombreRaw.toLowerCase() != 'no leído') {
          _displayedTitle = nombreRaw;
          _sinYape = false;
          _otrasEntidades = [];
        } else {
          _displayedTitle = _formatearCelular(numero);
          _sinYape = true;
          final rawEnt = data?['entidades'];
          if (rawEnt is List) {
            _otrasEntidades = rawEnt.map((e) => e.toString()).toList();
          }
        }
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);

    Future.delayed(_reveal, () {
      if (mounted) _amountFocus.requestFocus();
    });
  }

  AppContact get _contactoActual => widget.contact;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _amountFocus.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0;
  bool get _overLimit => _amount > SendAmountScreen.dailyLimit;
  bool get _canSend => _amount > 0 && !_overLimit;
  bool get _canOpenOtherBanks =>
      !_loading && (_canSend || _sinYape || _otrasEntidades.isNotEmpty);

  /// La ✕ cierra todo el flujo y vuelve al inicio.
  void _closeFlow() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final navigator = Navigator.of(context);
    final amount = _amount;
    final message = _messageCtrl.text.trim();
    final when = DateTime.now();

    showSendingOverlay(context);
    final currentBalance = AccountPrefsService.instance.balance;
    await AccountPrefsService.instance.setBalance(currentBalance - amount);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    navigator.pushAndRemoveUntil(
      slideRoute(
        SendReceiptScreen(
          contact: _contactoActual,
          amount: amount,
          message: message,
          dateTime: when,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  Future<void> _otherBanks() async {
    final numero = _numeroLimpio;
    if (numero.length != 9) {
      showAppMessage(context, 'Número de celular inválido.', error: true);
      return;
    }

    if (_otrasEntidades.isEmpty) {
      showAppMessage(
        context,
        'Buscando otras entidades...',
        error: false,
      );
      final data = await _llamarBuscarContacto(
        numero: numero,
        bancoForzado: null,
      );
      if (!mounted) return;
      final rawEnt = data?['entidades'];
      if (rawEnt is List && rawEnt.isNotEmpty) {
        setState(() {
          _otrasEntidades = rawEnt.map((e) => e.toString()).toList();
        });
      } else {
        showAppMessage(
          context,
          data?['error']?.toString() ??
              'No se encontraron otras entidades disponibles.',
          error: false,
        );
        return;
      }
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Otras entidades',
                style: appFont(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Número ${_formatearCelular(numero)}:',
                style: appFont(fontSize: 14, color: const Color(0xFF6E6A80)),
              ),
              const SizedBox(height: 12),
              ..._otrasEntidades.map(
                (entidad) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: sendPurple.withValues(alpha: 0.12),
                    child: Text(
                      entidad.isNotEmpty ? entidad[0].toUpperCase() : 'B',
                      style: appFont(
                        fontWeight: FontWeight.w700,
                        color: sendPurple,
                      ),
                    ),
                  ),
                  title: Text(
                    entidad,
                    style: appFont(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    Navigator.pop(ctx);
                    setState(() => _loading = true);
                    final dataEnt = await _llamarBuscarContacto(
                      numero: numero,
                      bancoForzado: entidad,
                    );
                    if (!mounted) return;
                    final nombreEnt =
                        dataEnt?['nombre']?.toString().trim() ?? '';
                    setState(() {
                      _loading = false;
                      if (dataEnt?['success'] == true &&
                          nombreEnt.isNotEmpty &&
                          nombreEnt.toLowerCase() != 'no leído') {
                        _displayedTitle = nombreEnt;
                      } else {
                        _displayedTitle = _formatearCelular(numero);
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    height: 64,
                    child: AnimatedSwitcher(
                      duration: _reveal,
                      child: _loading
                          ? const SkeletonBox(
                              key: ValueKey('name-skeleton'),
                              width: double.infinity,
                              height: 64,
                              radius: 2,
                            )
                          : Align(
                              key: const ValueKey('name'),
                              alignment: Alignment.topCenter,
                              child: Text(
                                _displayedTitle,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: appFont(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: sendPurple,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IgnorePointer(
                            ignoring: _loading,
                            child: AmountDisplay(
                              controller: _amountCtrl,
                              focusNode: _amountFocus,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 24,
                            child: AnimatedSwitcher(
                              duration: _reveal,
                              child: _loading
                                  ? const SkeletonBox(
                                      key: ValueKey('chip-skeleton'),
                                      width: 160,
                                      height: 24,
                                      radius: 12,
                                    )
                                  : KeyedSubtree(
                                      key: const ValueKey('chip'),
                                      child: _buildLimitChip(),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildMessageField(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          text: 'Otros bancos',
                          filled: false,
                          enabled: _canOpenOtherBanks,
                          onTap: _otherBanks,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ActionButton(
                          text: 'Enviar',
                          filled: true,
                          enabled: _canSend,
                          onTap: _send,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.arrow_back_rounded,
            heroTag: navBackHeroTag,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Enviar a',
              style: appFont(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ),
          CircleIconButton(
            icon: Icons.close_rounded,
            onTap: _closeFlow,
          ),
        ],
      ),
    );
  }

  Widget _buildLimitChip() {
    final over = _overLimit;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: over ? _error.withValues(alpha: 0.1) : _chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        over
            ? 'Superas tu límite diario de S/ 500'
            : 'Tu límite diario es S/ 500',
        style: appFont(
          fontSize: 13,
          color: over ? _error : const Color(0xFF4A4660),
        ),
      ),
    );
  }

  Widget _buildMessageField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          TextField(
            controller: _messageCtrl,
            textAlign: TextAlign.center,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            style: appFont(fontSize: 17, color: _textDark),
            decoration: InputDecoration(
              counterText: '',
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              hintText: 'Agregar mensaje',
              hintStyle: appFont(fontSize: 17, color: _disabledText),
            ),
          ),
          Container(height: 1, color: _divider),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final bool filled;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.text,
    required this.filled,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const disabledBorder = Color(0xFFE3E1EC);
    const disabledFill = Color(0xFFE6E4EE);
    const disabledText = Color(0xFFBDBAC9);

    final Color bg = filled
        ? (enabled ? sendPurple : disabledFill)
        : Colors.white;
    final Color border = filled
        ? Colors.transparent
        : (enabled ? sendPurple : disabledBorder);
    final Color fg = filled
        ? (enabled ? Colors.white : disabledText)
        : (enabled ? sendPurple : disabledText);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 2),
        ),
        child: Center(
          child: Text(
            text,
            style: appFont(fontSize: 17, fontWeight: FontWeight.w500, color: fg),
          ),
        ),
      ),
    );
  }
}