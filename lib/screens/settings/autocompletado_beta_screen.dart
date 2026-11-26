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

/// Mantiene vivo el estado y las peticiones aunque salgas a Ajustes y regreses.
class AutocompletadoController extends ChangeNotifier {
  AutocompletadoController._();
  static final AutocompletadoController instance = AutocompletadoController._();

  static const _keyServerUrl = 'ypayone_server_url_v1';
  static const _keyVelocidad = 'ypayone_velocidad_v1';

  String serverUrl = 'http://192.168.0.104:3000';
  String velocidad = 'NORMAL';
  CuentaVinculadaModel? cuentaActiva;
  int busquedasUsadasHoy = 0;

  bool sesionOnline = false;
  bool ocupado = false;
  bool deteniendo = false;
  bool enviandoCaptcha = false;

  String mensajeEstado = 'Listo para iniciar sesión.';
  bool esError = false;

  String? captchaBase64;
  Uint8List? captchaBytes;

  int? sesionExpiraEnMs;
  Timer? _relojTimer;
  String tiempoRestanteTexto = '13:00';
  bool menosDeUnMinuto = false;

  bool _inicializado = false;

  String get baseUrl {
    var url = serverUrl.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    return url;
  }

  int get limiteDiario => LimiteBusquedasStorage.limiteDiario;
  int get intentosRestantes =>
      (limiteDiario - busquedasUsadasHoy).clamp(0, limiteDiario);
  bool get limiteAgotado => busquedasUsadasHoy >= limiteDiario;

  Future<void> inicializarSiHaceFalta(String fallbackUrl) async {
    if (!_inicializado) {
      serverUrl = fallbackUrl;
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_keyServerUrl);
      final savedVel = prefs.getString(_keyVelocidad);

      if (savedUrl != null && savedUrl.isNotEmpty) {
        serverUrl = savedUrl;
      }
      if (savedVel != null && ['TURBO', 'NORMAL', 'LENTO'].contains(savedVel)) {
        velocidad = savedVel;
      }
      _inicializado = true;
    }

    await recargarCuentaYLimite();

    // Si no hay una petición en curso ni un captcha pendiente, sincroniza con el servidor
    if (!ocupado && !enviandoCaptcha && captchaBase64 == null) {
      await consultarEstadoSesion();
    } else if (sesionExpiraEnMs != null) {
      actualizarRelojVisual();
    }
  }

  Future<void> recargarCuentaYLimite({CuentaVinculadaModel? preferida}) async {
    final cuentas = await CuentasVinculadasStorage.obtenerCuentas();
    final activaId = await CuentasVinculadasStorage.obtenerCuentaActivaId();

    CuentaVinculadaModel? encontrada = preferida;
    if (encontrada == null && cuentas.isNotEmpty) {
      encontrada = cuentas.where((c) => c.id == activaId).firstOrNull ??
          cuentas.first;
    }

    cuentaActiva = encontrada;
    busquedasUsadasHoy =
        await LimiteBusquedasStorage.obtenerUsadasHoy(cuentaActiva?.dni);
    notifyListeners();
  }

  Future<void> actualizarServerUrl(String nuevaUrl) async {
    final limpia = nuevaUrl.trim();
    if (limpia.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, limpia);
    serverUrl = limpia;
    notifyListeners();
    await consultarEstadoSesion();
  }

  Future<void> actualizarVelocidad(String nuevaVel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVelocidad, nuevaVel);
    velocidad = nuevaVel;
    notifyListeners();
  }

  void _setCaptcha(String? base64Str) {
    captchaBase64 = base64Str;
    if (base64Str == null || base64Str.isEmpty) {
      captchaBytes = null;
      return;
    }
    try {
      final limpio =
          base64Str.contains(',') ? base64Str.split(',').last : base64Str;
      captchaBytes = base64Decode(limpio);
    } catch (_) {
      captchaBytes = null;
    }
  }

  Map<String, dynamic>? _parseJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  Future<void> consultarEstadoSesion() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/estado-sesion'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = _parseJson(res.body);
        if (data == null) return;
        if (data['activa'] == true && data['expiraEn'] != null) {
          _iniciarContadorVisual((data['expiraEn'] as num).toInt());
          sesionOnline = true;
          _setCaptcha(null);
          mensajeEstado = 'Sesión activa en curso.';
          esError = false;
          notifyListeners();
        } else if (sesionOnline) {
          _detenerContadorVisual();
          sesionOnline = false;
          mensajeEstado = 'Sesión finalizada o desconectada.';
          esError = false;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void _iniciarContadorVisual(int expiraEnMs) {
    _relojTimer?.cancel();
    sesionExpiraEnMs = expiraEnMs;
    actualizarRelojVisual();
    _relojTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      actualizarRelojVisual();
    });
  }

  void _detenerContadorVisual() {
    _relojTimer?.cancel();
    _relojTimer = null;
    sesionExpiraEnMs = null;
  }

  void actualizarRelojVisual() {
    if (sesionExpiraEnMs == null) return;
    final ahora = DateTime.now().millisecondsSinceEpoch;
    final restanteMs = (sesionExpiraEnMs! - ahora).clamp(0, 999999999);
    final totalSeg = (restanteMs / 1000).ceil();
    final min = (totalSeg ~/ 60).toString().padLeft(2, '0');
    final seg = (totalSeg % 60).toString().padLeft(2, '0');

    tiempoRestanteTexto = '$min:$seg';
    menosDeUnMinuto = totalSeg <= 60;

    if (restanteMs <= 0) {
      _detenerContadorVisual();
      sesionOnline = false;
      mensajeEstado = 'Sesión finalizada (13 min cumplidos).';
      esError = true;
    }
    notifyListeners();
  }

  Future<void> iniciarFlujo() async {
    if (ocupado || cuentaActiva == null) return;

    ocupado = true;
    deteniendo = false;
    _setCaptcha(null);
    mensajeEstado = 'Iniciando navegador y autocompletando DNI...';
    esError = false;
    notifyListeners();

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/iniciar'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'dni': cuentaActiva!.dni,
              'clave': cuentaActiva!.clave,
              'velocidad': velocidad,
            }),
          )
          .timeout(const Duration(seconds: 40));

      final data = _parseJson(res.body);
      if (data == null) {
        mensajeEstado = 'Respuesta inválida del servidor.';
        esError = true;
      } else if (data['ok'] == true) {
        if (data['captchaBase64'] != null) {
          _setCaptcha(data['captchaBase64'].toString());
          mensajeEstado = 'Ingresa el código Captcha para continuar.';
          esError = false;
        } else {
          mensajeEstado = 'DNI ingresado, pero no se capturó el Captcha.';
          esError = true;
        }
      } else {
        mensajeEstado = data['error']?.toString() ?? 'Error al iniciar sesión.';
        esError = true;
      }
    } catch (_) {
      mensajeEstado = 'Conexión con el servidor perdida.';
      esError = true;
    } finally {
      ocupado = false;
      notifyListeners();
    }
  }

  Future<void> cambiarCaptcha() async {
    if (enviandoCaptcha) return;
    enviandoCaptcha = true;
    mensajeEstado = 'Solicitando otro código Captcha...';
    esError = false;
    notifyListeners();

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/cambiar-captcha'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 15));

      final data = _parseJson(res.body);
      if (data == null) {
        mensajeEstado = 'Respuesta inválida al cambiar el Captcha.';
        esError = true;
      } else {
        if (data['nuevoCaptcha'] != null) {
          _setCaptcha(data['nuevoCaptcha'].toString());
        }
        mensajeEstado = data['ok'] == true
            ? (data['mensaje']?.toString() ?? 'Nuevo Captcha listo.')
            : (data['error']?.toString() ?? 'No se pudo cambiar el Captcha.');
        esError = data['ok'] != true;
      }
    } catch (_) {
      mensajeEstado = 'Error al solicitar nuevo Captcha.';
      esError = true;
    } finally {
      enviandoCaptcha = false;
      notifyListeners();
    }
  }

  Future<bool> enviarCaptcha(String codigo) async {
    if (enviandoCaptcha) return false;
    enviandoCaptcha = true;
    mensajeEstado = 'Validando Captcha y autocompletando clave...';
    esError = false;
    notifyListeners();

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/resolver-captcha'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'captcha': codigo}),
          )
          .timeout(const Duration(seconds: 40));

      final data = _parseJson(res.body);
      if (data == null) {
        mensajeEstado = 'Respuesta inválida al validar el Captcha.';
        esError = true;
        return false;
      }

      if (data['ok'] == true) {
        sesionOnline = true;
        _setCaptcha(null);
        mensajeEstado =
            data['mensaje']?.toString() ?? 'Sesión iniciada correctamente.';
        esError = false;
        if (data['expiraEn'] != null) {
          _iniciarContadorVisual((data['expiraEn'] as num).toInt());
        }
        return true;
      } else {
        mensajeEstado = data['error']?.toString() ?? 'Captcha incorrecto.';
        esError = true;
        if (data['nuevoCaptcha'] != null) {
          _setCaptcha(data['nuevoCaptcha'].toString());
        }
        return false;
      }
    } catch (_) {
      mensajeEstado = 'Error de conexión al validar Captcha.';
      esError = true;
      return false;
    } finally {
      enviandoCaptcha = false;
      notifyListeners();
    }
  }

  Future<void> detenerSistema() async {
    if (ocupado) return;
    ocupado = true;
    deteniendo = true;
    mensajeEstado = 'Deteniendo sesión y cerrando navegador...';
    esError = false;
    notifyListeners();

    try {
      final res = await http
          .get(Uri.parse('$baseUrl/cerrar'))
          .timeout(const Duration(seconds: 15));
      _detenerContadorVisual();
      sesionOnline = false;
      _setCaptcha(null);
      mensajeEstado = res.statusCode == 200 ? res.body : 'Navegador cerrado.';
      esError = false;
    } catch (_) {
      _detenerContadorVisual();
      sesionOnline = false;
      _setCaptcha(null);
      mensajeEstado = 'Conexión con el servidor perdida.';
      esError = true;
    } finally {
      ocupado = false;
      deteniendo = false;
      notifyListeners();
    }
  }
}

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
  static const _textDark = Color(0xFF1F1D2B);
  static const _sectionLabel = Color(0xFF757285);
  static const _muted = Color(0xFF8C899B);
  static const _divider = Color(0xFFF0EEF5);
  static const _purple = Color(0xFF6A1B7A);
  static const _green = Color(0xFF28A745);
  static const _red = Color(0xFFE5383B);
  static const _redBg = Color(0xFFFCDDE0);

  final _ctrl = AutocompletadoController.instance;
  final _captchaController = TextEditingController();
  String? _ultimoCaptchaMostrado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ultimoCaptchaMostrado = _ctrl.captchaBase64;
    _ctrl.inicializarSiHaceFalta(widget.initialServerUrl);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captchaController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_ctrl.sesionExpiraEnMs != null) {
        _ctrl.actualizarRelojVisual();
      }
      _ctrl.recargarCuentaYLimite();
      if (!_ctrl.ocupado && !_ctrl.enviandoCaptcha && _ctrl.captchaBase64 == null) {
        _ctrl.consultarEstadoSesion();
      }
    }
  }

  Future<void> _abrirCuentasVinculadas() async {
    final resultado = await Navigator.of(context).push<CuentaVinculadaModel?>(
      slideRoute(
        CuentasVinculadasScreen(
          cuentaSeleccionadaId: _ctrl.cuentaActiva?.id,
        ),
      ),
    );
    await _ctrl.recargarCuentaYLimite(preferida: resultado);
  }

  Future<void> _iniciarFlujo() async {
    if (_ctrl.cuentaActiva == null) {
      showAppMessage(
        context,
        'Primero vincula o selecciona una cuenta guardada.',
        error: true,
      );
      await _abrirCuentasVinculadas();
      return;
    }
    await _ctrl.iniciarFlujo();
  }

  Future<void> _enviarCaptcha() async {
    final codigo = _captchaController.text.trim();
    if (codigo.isEmpty) {
      showAppMessage(
        context,
        'Escribe el código de la imagen Captcha.',
        error: true,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final ok = await _ctrl.enviarCaptcha(codigo);
    if (ok && mounted) {
      _captchaController.clear();
    }
  }

  Future<void> _editarUrlServidor() async {
    final tempCtrl = TextEditingController(text: _ctrl.serverUrl);
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
    tempCtrl.dispose();

    if (nuevaUrl != null && nuevaUrl.isNotEmpty) {
      await _ctrl.actualizarServerUrl(nuevaUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          // Si llegó un captcha nuevo (incluso estando fuera de la pantalla), limpia el input
          if (_ctrl.captchaBase64 != _ultimoCaptchaMostrado) {
            _ultimoCaptchaMostrado = _ctrl.captchaBase64;
            _captchaController.clear();
          }

          return Scaffold(
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
                    _buildTopBack(context),
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
                                              _ctrl.sesionOnline
                                                  ? 'ONLINE'
                                                  : 'OFFLINE',
                                              style: appFont(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: _ctrl.sesionOnline
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
                                                color: _ctrl.sesionOnline
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
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      14,
                                      18,
                                      14,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Búsquedas hoy',
                                              style: appFont(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w600,
                                                color: _textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _ctrl.cuentaActiva == null
                                                  ? 'Sin DNI vinculado'
                                                  : _ctrl.limiteAgotado
                                                      ? 'Límite agotado · Reinicia 00:00'
                                                      : 'Te quedan ${_ctrl.intentosRestantes} intentos hoy',
                                              style: appFont(
                                                fontSize: 12.5,
                                                color: _ctrl.limiteAgotado
                                                    ? _red
                                                    : _muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${_ctrl.busquedasUsadasHoy} / ${_ctrl.limiteDiario}',
                                          style: appFont(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: _ctrl.limiteAgotado
                                                ? _red
                                                : _purple,
                                          ),
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
                                        color: _ctrl.esError
                                            ? _redBg
                                            : const Color(0xFFF4F2FA),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        _ctrl.mensajeEstado,
                                        style: appFont(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: _ctrl.esError
                                              ? _red
                                              : _textDark,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_ctrl.sesionExpiraEnMs != null) ...[
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
                                            _ctrl.tiempoRestanteTexto,
                                            style: appFont(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: _ctrl.menosDeUnMinuto
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
                                      onPressed: _ctrl.ocupado
                                          ? null
                                          : _iniciarFlujo,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _green,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: _ctrl.ocupado && !_ctrl.deteniendo
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
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
                                      onPressed: _ctrl.ocupado
                                          ? null
                                          : _ctrl.detenerSistema,
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.92),
                                        foregroundColor: _textDark,
                                        side: const BorderSide(
                                          color: Color(0xFFE6E2F0),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: _ctrl.deteniendo
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: _textDark,
                                              ),
                                            )
                                          : Text(
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

                            if (_ctrl.captchaBase64 != null) ...[
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            onPressed: _ctrl.enviandoCaptcha
                                                ? null
                                                : _ctrl.cambiarCaptcha,
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
                                      if (_ctrl.captchaBytes != null) ...[
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
                                              _ctrl.captchaBytes!,
                                              height: 60,
                                              fit: BoxFit.contain,
                                              gaplessPlayback: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _captchaController,
                                        enabled: !_ctrl.enviandoCaptcha,
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
                                            borderRadius:
                                                BorderRadius.circular(14),
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
                                          onPressed: _ctrl.enviandoCaptcha
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
                                            _ctrl.enviandoCaptcha
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
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          _ctrl.cuentaActiva?.iniciales ?? '+',
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
                                              _ctrl.cuentaActiva?.alias ??
                                                  'Vincular cuenta guardada',
                                              style: appFont(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w600,
                                                color: _textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _ctrl.cuentaActiva
                                                      ?.dniEnmascarado ??
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
                                              _ctrl.serverUrl,
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
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _ctrl.velocidad,
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
                                              onChanged: (val) {
                                                if (val != null) {
                                                  _ctrl
                                                      .actualizarVelocidad(val);
                                                }
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
          );
        },
      ),
    );
  }

  Widget _buildTopBack(BuildContext context) {
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
              Icons.arrow_back_rounded,
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