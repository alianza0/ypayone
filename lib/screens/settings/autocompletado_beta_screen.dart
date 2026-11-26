import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_text.dart';
import '../../core/navigation.dart';
import '../../widgets/app_message.dart';
import 'cuentas_vinculadas_screen.dart';

class AutocompletadoBetaScreen extends StatefulWidget {
  final String initialServerUrl;

  const AutocompletadoBetaScreen({
    super.key,
    this.initialServerUrl = 'http://192.168.0.104:3000',
  });

  @override
  State<AutocompletadoBetaScreen> createState() =>
      _AutocompletadoBetaScreenState();
}

class _AutocompletadoBetaScreenState extends State<AutocompletadoBetaScreen>
    with WidgetsBindingObserver {
  static const _keyServerUrl = 'ypayone_server_url_v1';
  static const _keyVelocidad = 'ypayone_velocidad_v1';

  static const _textDark = Color(0xFF1F1D2B);
  static const _sectionLabel = Color(0xFF757285);
  static const _muted = Color(0xFF8C899B);
  static const _divider = Color(0xFFF0EEF5);
  static const _purple = Color(0xFF6A1B7A);
  static const _green = Color(0xFF28A745);
  static const _red = Color(0xFFE5383B);
  static const _redBg = Color(0xFFFCDDE0);

  final _captchaController = TextEditingController();
  final _serverUrlController = TextEditingController();

  CuentaVinculadaModel? _cuentaActiva;
  String _velocidad = 'NORMAL';
  bool _sesionOnline = false;
  bool _ocupado = false;
  bool _enviandoCaptcha = false;

  String _mensajeEstado = 'Listo para iniciar sesión.';
  bool _esError = false;

  String? _captchaBase64;
  int? _sesionExpiraEnMs;
  Timer? _relojTimer;
  String _tiempoRestanteTexto = '13:00';
  bool _menosDeUnMinuto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _serverUrlController.text = widget.initialServerUrl;
    _inicializar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _relojTimer?.cancel();
    _captchaController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_sesionExpiraEnMs != null) {
        _actualizarRelojVisual();
      }
      _consultarEstadoSesion();
    }
  }

  String get _baseUrl {
    var url = _serverUrlController.text.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    return url;
  }

  Future<void> _inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_keyServerUrl);
    final savedVel = prefs.getString(_keyVelocidad);

    if (savedUrl != null && savedUrl.isNotEmpty) {
      _serverUrlController.text = savedUrl;
    }
    if (savedVel != null && ['TURBO', 'NORMAL', 'LENTO'].contains(savedVel)) {
      _velocidad = savedVel;
    }

    final cuentas = await CuentasVinculadasStorage.obtenerCuentas();
    final activaId = await CuentasVinculadasStorage.obtenerCuentaActivaId();

    CuentaVinculadaModel? encontrada;
    if (cuentas.isNotEmpty) {
      encontrada = cuentas.where((c) => c.id == activaId).firstOrNull ??
          cuentas.first;
    }

    if (!mounted) return;
    setState(() => _cuentaActiva = encontrada);

    await _consultarEstadoSesion();
  }

  Future<void> _consultarEstadoSesion() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/estado-sesion'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['activa'] == true && data['expiraEn'] != null) {
          _iniciarContadorVisual((data['expiraEn'] as num).toInt());
          if (!mounted) return;
          setState(() {
            _sesionOnline = true;
            _mensajeEstado = 'Sesión activa en curso.';
            _esError = false;
          });
        } else if (_sesionOnline) {
          _detenerContadorVisual();
          if (!mounted) return;
          setState(() {
            _sesionOnline = false;
            _mensajeEstado = 'Sesión finalizada o desconectada.';
            _esError = false;
          });
        }
      }
    } catch (_) {}
  }

  void _iniciarContadorVisual(int expiraEnMs) {
    _relojTimer?.cancel();
    _sesionExpiraEnMs = expiraEnMs;
    _actualizarRelojVisual();
    _relojTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _actualizarRelojVisual();
    });
  }

  void _detenerContadorVisual() {
    _relojTimer?.cancel();
    _relojTimer = null;
    _sesionExpiraEnMs = null;
  }

  void _actualizarRelojVisual() {
    if (_sesionExpiraEnMs == null) return;
    final ahora = DateTime.now().millisecondsSinceEpoch;
    final restanteMs = (_sesionExpiraEnMs! - ahora).clamp(0, 999999999);
    final totalSeg = (restanteMs / 1000).ceil();
    final min = (totalSeg ~/ 60).toString().padLeft(2, '0');
    final seg = (totalSeg % 60).toString().padLeft(2, '0');

    if (!mounted) return;
    setState(() {
      _tiempoRestanteTexto = '$min:$seg';
      _menosDeUnMinuto = totalSeg <= 60;
    });

    if (restanteMs <= 0) {
      _detenerContadorVisual();
      setState(() {
        _sesionOnline = false;
        _mensajeEstado = 'Sesión finalizada (13 min cumplidos).';
        _esError = true;
      });
    }
  }

  Future<void> _abrirCuentasVinculadas() async {
    final resultado = await Navigator.of(context).push<CuentaVinculadaModel?>(
      slideRoute(
        CuentasVinculadasScreen(
          cuentaSeleccionadaId: _cuentaActiva?.id,
        ),
      ),
    );

    final cuentas = await CuentasVinculadasStorage.obtenerCuentas();
    final activaId = await CuentasVinculadasStorage.obtenerCuentaActivaId();
    if (!mounted) return;
    setState(() {
      _cuentaActiva = resultado ??
          cuentas.where((c) => c.id == activaId).firstOrNull ??
          (cuentas.isNotEmpty ? cuentas.first : null);
    });
  }

  Future<void> _iniciarFlujo() async {
    if (_cuentaActiva == null) {
      showAppMessage(
        context,
        'Primero vincula o selecciona una cuenta guardada.',
        error: true,
      );
      await _abrirCuentasVinculadas();
      return;
    }

    setState(() {
      _ocupado = true;
      _captchaBase64 = null;
      _mensajeEstado = 'Iniciando navegador y autocompletando DNI...';
      _esError = false;
    });

    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/iniciar'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'dni': _cuentaActiva!.dni,
              'clave': _cuentaActiva!.clave,
              'velocidad': _velocidad,
            }),
          )
          .timeout(const Duration(seconds: 40));

      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (data['ok'] == true) {
        if (data['captchaBase64'] != null) {
          _captchaController.clear();
          setState(() {
            _captchaBase64 = data['captchaBase64'];
            _mensajeEstado = 'Ingresa el código Captcha para continuar.';
            _esError = false;
          });
        } else {
          setState(() {
            _mensajeEstado = 'DNI ingresado, pero no se capturó el Captcha.';
            _esError = true;
          });
        }
      } else {
        setState(() {
          _mensajeEstado = data['error'] ?? 'Error al iniciar sesión.';
          _esError = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mensajeEstado = 'Conexión con el servidor perdida.';
        _esError = true;
      });
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _cambiarCaptcha() async {
    if (_enviandoCaptcha) return;
    setState(() {
      _enviandoCaptcha = true;
      _mensajeEstado = 'Solicitando otro código Captcha...';
      _esError = false;
    });

    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/cambiar-captcha'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);
      if (!mounted) return;

      setState(() {
        if (data['nuevoCaptcha'] != null) {
          _captchaBase64 = data['nuevoCaptcha'];
          _captchaController.clear();
        }
        _mensajeEstado = data['ok'] == true
            ? (data['mensaje'] ?? 'Nuevo Captcha listo.')
            : (data['error'] ?? 'No se pudo cambiar el Captcha.');
        _esError = data['ok'] != true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mensajeEstado = 'Error al solicitar nuevo Captcha.';
        _esError = true;
      });
    } finally {
      if (mounted) setState(() => _enviandoCaptcha = false);
    }
  }

  Future<void> _enviarCaptcha() async {
    if (_enviandoCaptcha) return;
    final codigo = _captchaController.text.trim();
    if (codigo.isEmpty) {
      showAppMessage(context, 'Escribe el código de la imagen Captcha.', error: true);
      return;
    }

    setState(() {
      _enviandoCaptcha = true;
      _mensajeEstado = 'Validando Captcha y autocompletando clave...';
      _esError = false;
    });

    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/resolver-captcha'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'captcha': codigo}),
          )
          .timeout(const Duration(seconds: 40));

      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (data['ok'] == true) {
        setState(() {
          _sesionOnline = true;
          _captchaBase64 = null;
          _mensajeEstado = data['mensaje'] ?? 'Sesión iniciada correctamente.';
          _esError = false;
        });
        if (data['expiraEn'] != null) {
          _iniciarContadorVisual((data['expiraEn'] as num).toInt());
        }
      } else {
        setState(() {
          _mensajeEstado = data['error'] ?? 'Captcha incorrecto.';
          _esError = true;
          if (data['nuevoCaptcha'] != null) {
            _captchaBase64 = data['nuevoCaptcha'];
            _captchaController.clear();
          }
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mensajeEstado = 'Error de conexión al validar Captcha.';
        _esError = true;
      });
    } finally {
      if (mounted) setState(() => _enviandoCaptcha = false);
    }
  }

  Future<void> _detenerSistema() async {
    setState(() {
      _ocupado = true;
      _mensajeEstado = 'Deteniendo sesión y cerrando navegador...';
      _esError = false;
    });

    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/cerrar'))
          .timeout(const Duration(seconds: 15));
      _detenerContadorVisual();
      if (!mounted) return;
      setState(() {
        _sesionOnline = false;
        _captchaBase64 = null;
        _mensajeEstado = res.statusCode == 200 ? res.body : 'Navegador cerrado.';
        _esError = false;
      });
    } catch (_) {
      _detenerContadorVisual();
      if (!mounted) return;
      setState(() {
        _sesionOnline = false;
        _captchaBase64 = null;
        _mensajeEstado = 'Conexión con el servidor perdida.';
        _esError = true;
      });
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _editarUrlServidor() async {
    final tempCtrl = TextEditingController(text: _serverUrlController.text);
    final nuevaUrl = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Dirección del servidor',
          style: appFont(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        content: TextField(
          controller: tempCtrl,
          style: appFont(fontSize: 15, color: _textDark),
          decoration: InputDecoration(
            hintText: 'http://192.168.0.104:3000',
            hintStyle: appFont(fontSize: 14, color: _muted),
            filled: true,
            fillColor: const Color(0xFFF4F2FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: appFont(color: _muted, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, tempCtrl.text.trim()),
            child: Text(
              'Guardar',
              style: appFont(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (nuevaUrl != null && nuevaUrl.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyServerUrl, nuevaUrl);
      setState(() => _serverUrlController.text = nuevaUrl);
      _consultarEstadoSesion();
    }
  }

  Uint8List? _decodificarBase64(String dataUri) {
    try {
      final limpio = dataUri.contains(',') ? dataUri.split(',').last : dataUri;
      return base64Decode(limpio);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytesCaptcha =
        _captchaBase64 != null ? _decodificarBase64(_captchaBase64!) : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
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
                _buildTopClose(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Auto-completado',
                              style: appFont(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: _textDark,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _purple.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'BETA',
                                style: appFont(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _purple,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Activa y controla tu sesión vinculada.',
                          style: appFont(fontSize: 15, color: _muted),
                        ),
                        const SizedBox(height: 22),

                        Text(
                          'MONITOR DE ESTADO',
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
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  15,
                                  18,
                                  15,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Estado de sesión',
                                      style: appFont(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w600,
                                        color: _textDark,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          _sesionOnline ? 'ONLINE' : 'OFFLINE',
                                          style: appFont(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: _sesionOnline
                                                ? _green
                                                : _muted,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _sesionOnline
                                                ? _green
                                                : _muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              _dividerLine(),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _esError
                                        ? _redBg
                                        : const Color(0xFFF4F2FA),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    _mensajeEstado,
                                    style: appFont(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: _esError ? _red : _textDark,
                                    ),
                                  ),
                                ),
                              ),
                              if (_sesionExpiraEnMs != null) ...[
                                _dividerLine(),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    14,
                                    18,
                                    16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Tiempo restante',
                                        style: appFont(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w600,
                                          color: _textDark,
                                        ),
                                      ),
                                      Text(
                                        _tiempoRestanteTexto,
                                        style: appFont(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: _menosDeUnMinuto
                                              ? _red
                                              : _purple,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _ocupado ? null : _iniciarFlujo,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _green,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Iniciar sesión',
                                    style: appFont(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: _ocupado ? null : _detenerSistema,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.92),
                                    foregroundColor: _textDark,
                                    side: const BorderSide(
                                      color: Color(0xFFE6E2F0),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Detener',
                                    style: appFont(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _textDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_captchaBase64 != null) ...[
                          const SizedBox(height: 22),
                          Text(
                            'VERIFICACIÓN CAPTCHA',
                            style: appFont(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _sectionLabel,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _cardContainer(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Código de seguridad',
                                        style: appFont(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w600,
                                          color: _textDark,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: _enviandoCaptcha
                                            ? null
                                            : _cambiarCaptcha,
                                        icon: const Icon(
                                          Icons.refresh_rounded,
                                          size: 18,
                                          color: _purple,
                                        ),
                                        label: Text(
                                          'Cambiar',
                                          style: appFont(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: _purple,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (bytesCaptcha != null) ...[
                                    const SizedBox(height: 8),
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF4F2FA),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Image.memory(
                                          bytesCaptcha,
                                          height: 60,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _captchaController,
                                    enabled: !_enviandoCaptcha,
                                    maxLength: 6,
                                    textAlign: TextAlign.center,
                                    style: appFont(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _textDark,
                                      letterSpacing: 3,
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      hintText: 'Escribe el código aquí',
                                      hintStyle: appFont(
                                        fontSize: 14,
                                        color: _muted,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF4F2FA),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onSubmitted: (_) => _enviarCaptcha(),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 46,
                                    child: ElevatedButton(
                                      onPressed: _enviandoCaptcha
                                          ? null
                                          : _enviarCaptcha,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _purple,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Text(
                                        _enviandoCaptcha
                                            ? 'Validando...'
                                            : 'Confirmar y autocompletar clave',
                                        style: appFont(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),

                        Text(
                          'CUENTAS VINCULADAS',
                          style: appFont(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _sectionLabel,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _cardContainer(
                          child: InkWell(
                            onTap: _abrirCuentasVinculadas,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _purple.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _cuentaActiva?.iniciales ?? '+',
                                      style: appFont(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: _purple,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _cuentaActiva?.alias ??
                                              'Vincular cuenta guardada',
                                          style: appFont(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w600,
                                            color: _textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _cuentaActiva?.dniEnmascarado ??
                                              'Toca para guardar DNI y clave',
                                          style: appFont(
                                            fontSize: 13,
                                            color: _muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: _muted,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        Text(
                          'AJUSTES DE OPERACIÓN',
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
                              InkWell(
                                onTap: _editarUrlServidor,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 15,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Servidor',
                                        style: appFont(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w600,
                                          color: _textDark,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          _serverUrlController.text,
                                          overflow: TextOverflow.ellipsis,
                                          style: appFont(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: _muted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _dividerLine(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Velocidad',
                                      style: appFont(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w600,
                                        color: _textDark,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF4F2FA),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _velocidad,
                                          isDense: true,
                                          dropdownColor: Colors.white,
                                          style: appFont(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _purple,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'TURBO',
                                              child: Text('Turbo'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'NORMAL',
                                              child: Text('Normal'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'LENTO',
                                              child: Text('Lento'),
                                            ),
                                          ],
                                          onChanged: (val) async {
                                            if (val == null) return;
                                            final prefs =
                                                await SharedPreferences
                                                    .getInstance();
                                            await prefs.setString(
                                              _keyVelocidad,
                                              val,
                                            );
                                            setState(() => _velocidad = val);
                                          },
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopClose(BuildContext context) {
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
}