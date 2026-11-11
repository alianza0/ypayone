import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_text.dart';

const Color sendPurple = Color(0xFF7B0E9B);
const Color sendGrey = Color(0xFFB5B2C6);

/// Monto grande "S/ 0" con cursor parpadeante.
/// Por debajo hay un campo invisible que recibe lo que se teclea.
class AmountDisplay extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Abre el teclado apenas se muestra la pantalla.
  final bool autofocus;

  const AmountDisplay({
    super.key,
    required this.controller,
    required this.focusNode,
    this.autofocus = false,
  });

  @override
  State<AmountDisplay> createState() => _AmountDisplayState();
}

class _AmountDisplayState extends State<AmountDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    widget.focusNode.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    widget.focusNode.removeListener(_refresh);
    _blink.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final focused = widget.focusNode.hasFocus;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.focusNode.requestFocus(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'S/',
                style: appFont(fontSize: 28, color: sendGrey),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text.isEmpty ? '0' : text,
              style: appFont(
                fontSize: 64,
                fontWeight: FontWeight.w400,
                color: sendPurple,
                height: 1.05,
              ),
            ),
            if (focused)
              FadeTransition(
                opacity: _blink,
                child: Container(
                  width: 2.5,
                  height: 58,
                  margin: const EdgeInsets.only(left: 3, top: 6),
                  color: sendGrey,
                ),
              ),
            // Campo invisible que abre el teclado numérico con punto decimal.
            SizedBox(
              width: 1,
              height: 1,
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  autofocus: widget.autofocus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [_AmountFormatter()],
                  showCursor: false,
                  enableInteractiveSelection: false,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Solo permite montos tipo 1234.56 (hasta 4 enteros y 2 decimales).
class _AmountFormatter extends TextInputFormatter {
  static final _valid = RegExp(r'^\d{0,4}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var t = newValue.text.replaceAll(',', '.');
    if (t == '.') t = '0.';
    // Quita ceros a la izquierda: "05" → "5"
    while (t.length > 1 && t.startsWith('0') && !t.startsWith('0.')) {
      t = t.substring(1);
    }
    if (!_valid.hasMatch(t)) return oldValue;
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}
