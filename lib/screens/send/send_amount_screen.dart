import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_text.dart';
import '../../core/navigation.dart';
import '../../models/app_contact.dart';
import '../../widgets/app_message.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/skeleton_box.dart';
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
  final _amountCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  final _messageCtrl = TextEditingController();

  /// Primero se muestra la carga (skeleton) y luego el contenido + teclado.
  bool _loading = true;
  static const _loadingTime = Duration(seconds: 3);
  static const _reveal = Duration(milliseconds: 350);

  static const _textDark = Color(0xFF2A2540);
  static const _chipBg = Color(0xFFF1EFF8);
  static const _divider = Color(0xFFE2E0EA);
  static const _disabledText = Color(0xFFBDBAC9);
  static const _error = Color(0xFFD64545);

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(() => setState(() {}));
    Future.delayed(_loadingTime, () {
      if (!mounted) return;
      setState(() => _loading = false);
      // Abre el teclado cuando ya terminó de aparecer el contenido.
      Future.delayed(_reveal, () {
        if (mounted) _amountFocus.requestFocus();
      });
    });
  }

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
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Quita "Enviando", "Enviar a" y "Lista" y deja el comprobante sobre el Home.
    navigator.pushAndRemoveUntil(
      fadeRoute(SendReceiptScreen(
        contact: widget.contact,
        amount: amount,
        message: message,
        dateTime: when,
      )),
      (route) => route.isFirst,
    );
  }

  void _otherBanks() {
    showAppMessage(context, 'Otros bancos estará disponible pronto.',
        error: false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        // Blanco: también es el color que queda detrás del teclado.
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
                                widget.contact.name,
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
                // El monto queda centrado en el espacio libre
                // (sube solo cuando aparece el teclado).
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
                          enabled: _canSend,
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
