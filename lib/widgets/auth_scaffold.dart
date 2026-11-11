import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import 'wave_painter.dart';

/// Plantilla común de Login / Registro / Recuperar:
/// cabecera morada fija + panel blanco que sube desde abajo
/// y sus elementos aparecen uno tras otro.
class AuthScaffold extends StatefulWidget {
  final String eyebrow;
  final String title;
  final VoidCallback? onBack;
  final GlobalKey<FormState>? formKey;
  final List<Widget> children;

  const AuthScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.children,
    this.onBack,
    this.formKey,
  });

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _stagger(int index, Widget child) {
    final begin = (0.30 + index * 0.045).clamp(0.0, 0.85).toDouble();
    final end = (begin + 0.35).clamp(0.0, 1.0).toDouble();
    final anim = _c.drive(
      CurveTween(curve: Interval(begin, end, curve: Curves.easeOutCubic)),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: anim.drive(
          Tween(begin: const Offset(0, 0.5), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheetSlide = _c.drive(
      Tween(begin: const Offset(0, 1), end: Offset.zero).chain(
        CurveTween(curve: const Interval(0, 0.5, curve: Curves.easeOutCubic)),
      ),
    );

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 32),
        for (int i = 0; i < widget.children.length; i++)
          _stagger(i, widget.children[i]),
      ],
    );
    if (widget.formKey != null) {
      content = Form(key: widget.formKey, child: content);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Stack(
          children: [
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 300,
              child: CustomPaint(painter: WavePainter()),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SafeArea(bottom: false, child: _buildHeader()),
                Expanded(
                  child: SlideTransition(
                    position: sheetSlide,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(36)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                        child: content,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, widget.onBack != null ? 36 : 48, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.onBack != null) ...[
            GestureDetector(
              onTap: widget.onBack,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(right: 16, top: 4, bottom: 4),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
          Text(
            widget.eyebrow,
            style: appFont(
              color: AppColors.headerLabel,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.title,
            style: appFont(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Textos reutilizables del panel blanco.
class SheetLabel extends StatelessWidget {
  final String text;
  const SheetLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: appFont(
        color: AppColors.accent,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 3,
      ),
    );
  }
}

class SheetSubtitle extends StatelessWidget {
  final String text;
  const SheetSubtitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: appFont(color: AppColors.textGrey, fontSize: 16, height: 1.4),
    );
  }
}
