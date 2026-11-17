import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/app_text.dart';
import '../../widgets/app_message.dart';

/// Pantalla "Abrir QR": cámara a pantalla completa con marco, linterna
/// y opción de subir una imagen con QR.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _torchOn = false;
  String? _lastCode;
  DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);

  static const _textDark = Color(0xFF2A2540);
  static const _torchText = Color(0xFF6E6A80);
  static const _iconBg = Color(0xFFF3E6F5);
  static const _iconColor = Color(0xFF7B0E9B);

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  /// Por ahora solo muestra lo que contiene el QR.
  void _handleCode(String? code) {
    if (code == null || code.isEmpty || !mounted) return;
    final now = DateTime.now();
    // Evita repetir el mismo aviso muchas veces por segundo.
    if (code == _lastCode &&
        now.difference(_lastShown) < const Duration(seconds: 3)) {
      return;
    }
    _lastCode = code;
    _lastShown = now;
    showAppMessage(context, 'QR leído: $code', error: false);
  }

  void _onDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    _handleCode(capture.barcodes.first.rawValue);
  }

  Future<void> _toggleTorch() async {
    try {
      await _scanner.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
      if (mounted) {
        showAppMessage(context, 'La linterna no está disponible.');
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final capture = await _scanner.analyzeImage(file.path);
      if (!mounted) return;
      if (capture == null || capture.barcodes.isEmpty) {
        showAppMessage(context, 'No se encontró un QR en la imagen.');
      } else {
        _handleCode(capture.barcodes.first.rawValue);
      }
    } catch (_) {
      if (mounted) {
        showAppMessage(context, 'No se pudo leer la imagen.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.sizeOf(context).width * 0.48;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF3A3944),
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(controller: _scanner, onDetect: _onDetect),
            // Mientras la cámara arranca: fondo gris suave (no negro) que
            // se desvanece apenas llega la imagen.
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: _scanner,
              builder: (_, state, __) => IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: state.isRunning ? 0 : 1,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF5A5866), Color(0xFF3A3944)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Marco central y texto
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: frame,
                    height: frame,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.85),
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Escanea un QR con tu cámara',
                    style: appFont(fontSize: 14.5, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Botón cerrar
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, right: 10),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
            // Linterna y subir imagen
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTorchButton(),
                      const SizedBox(height: 28),
                      _buildUploadCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTorchButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _toggleTorch,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            _torchOn ? 'Apagar linterna' : 'Encender linterna',
            style: appFont(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: _torchText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _pickImage,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: _iconBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: _iconColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Subir una imagen con QR',
                style: appFont(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: _textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
