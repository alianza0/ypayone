import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';

/// Campo redondeado como en el diseño: la etiqueta va DENTRO del recuadro
/// (grande cuando está vacío, pequeña y morada arriba cuando tiene texto).
class AppInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isPassword;
  final bool numeric;

  /// Usuario: siempre en MAYÚSCULAS, sin espacios.
  final bool isUsername;
  final String? Function(String?)? validator;
  final TextInputAction action;

  const AppInput({
    super.key,
    required this.controller,
    required this.label,
    this.isPassword = false,
    this.numeric = false,
    this.isUsername = false,
    this.validator,
    this.action = TextInputAction.next,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  final _focus = FocusNode();
  bool _focused = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  List<TextInputFormatter>? get _formatters {
    if (widget.numeric) return [FilteringTextInputFormatter.digitsOnly];
    if (widget.isUsername) {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9._-]')),
        _UpperCaseFormatter(),
      ];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => widget.validator?.call(widget.controller.text),
      builder: (state) {
        final hasError = state.hasError;
        final borderColor = hasError
            ? AppColors.error
            : (_focused ? AppColors.accent : AppColors.border);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minHeight: 62),
              padding: EdgeInsets.only(
                left: 24,
                right: widget.isPassword ? 8 : 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: borderColor,
                  width: (_focused || hasError) ? 1.8 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      obscureText: widget.isPassword && _obscure,
                      keyboardType: widget.numeric
                          ? TextInputType.number
                          : TextInputType.text,
                      inputFormatters: _formatters,
                      textCapitalization: widget.isUsername
                          ? TextCapitalization.characters
                          : TextCapitalization.none,
                      textInputAction: widget.action,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (_) {
                        if (state.hasError) state.validate();
                      },
                      style: appFont(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                      decoration: InputDecoration(
                        labelText: widget.label,
                        labelStyle: appFont(
                          color: AppColors.hint,
                          fontSize: 18,
                        ),
                        floatingLabelStyle: appFont(
                          color: AppColors.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (widget.isPassword) _buildShowButton(),
                ],
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 6),
                child: Text(
                  state.errorText!,
                  style: appFont(color: AppColors.error, fontSize: 13),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildShowButton() {
    return GestureDetector(
      onTap: () => setState(() => _obscure = !_obscure),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.chip,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _obscure ? 'Mostrar' : 'Ocultar',
          style: appFont(
            color: AppColors.accent,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
