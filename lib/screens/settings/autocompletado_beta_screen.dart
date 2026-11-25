import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  static const String _keyServerUrl = 'ypayone_server_url_v1';
  static const String _keyVelocidad = 'ypayone_velocidad_v1';

  final _captchaController = TextEditingController();
  final _serverUrlController = TextEditingController();

  CuentaVinculadaModel? _cuentaActiva;
  String _velocidad = 'NORMAL';
  bool _sesionOnline = false;
  bool _ocupado = false;
  bool _enviandoCaptcha = false;

  String _mensajeEstado = 'Listo para iniciar sesión';
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

  // Sincroniza al instante si la app vuelve de segundo plano en iOS
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
    setState(() {
      _cuentaActiva = encontrada;
    });

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
            _mensajeEstado = 'Sesión activa en curso';
            _esError = false;
          });
        } else if (_sesionOnline) {
          _detenerContadorVisual();
          if (!mounted) return;
          setState(() {
            _sesionOnline = false;
            _mensajeEstado = 'Sesión finalizada o desconectada';
            _esError = false;
          });
        }
      }
    } catch (_) {
      // Silencioso al verificar en segundo plano
    }
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
        _mensajeEstado = 'Sesión finalizada (13 min cumplidos)';
        _esError = true;
      });
    }
  }

  Future<void> _abrirCuentasVinculadas() async {
    final resultado = await Navigator.push<CuentaVinculadaModel?>(
      context,
      MaterialPageRoute(
        builder: (_) => CuentasVinculadasScreen(
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
      setState(() {
        _mensajeEstado = 'Vincula una cuenta guardada antes de iniciar';
        _esError = true;
      });
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
            _mensajeEstado = 'Ingresa el código Captcha para continuar';
            _esError = false;
          });
        } else {
          setState(() {
            _mensajeEstado = 'DNI ingresado, pero no se capturó el Captcha';
            _esError = true;
          });
        }
      } else {
        setState(() {
          _mensajeEstado = data['error'] ?? 'Error al iniciar sesión';
          _esError = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajeEstado = 'Conexión con el servidor perdida';
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
            ? (data['mensaje'] ?? 'Nuevo Captcha listo')
            : (data['error'] ?? 'No se pudo cambiar el Captcha');
        _esError = data['ok'] != true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mensajeEstado = 'Error al solicitar nuevo Captcha';
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
      setState(() {
        _mensajeEstado = 'Escribe el código de la imagen Captcha';
        _esError = true;
      });
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
          _mensajeEstado = data['mensaje'] ?? 'Sesión iniciada correctamente';
          _esError = false;
        });
        if (data['expiraEn'] != null) {
          _iniciarContadorVisual((data['expiraEn'] as num).toInt());
        }
      } else {
        setState(() {
          _mensajeEstado = data['error'] ?? 'Captcha incorrecto';
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
        _mensajeEstado = 'Error de conexión al validar Captcha';
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
        _mensajeEstado = res.statusCode == 200
            ? res.body
            : 'Navegador cerrado';
        _esError = false;
      });
    } catch (_) {
      _detenerContadorVisual();
      if (!mounted) return;
      setState(() {
        _sesionOnline = false;
        _captchaBase64 = null;
        _mensajeEstado = 'Conexión con el servidor perdida';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Dirección del Servidor',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: TextField(
          controller: tempCtrl,
          decoration: const InputDecoration(
            hintText: 'http://192.168.0.104:3000',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF68707A))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF28A745),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, tempCtrl.text.trim()),
            child: const Text('Guardar'),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: const Color(0xFFECEEF2),
            child: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Color(0xFF1A1D21), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TÍTULO PRINCIPAL
            Row(
              children: [
                const Text(
                  'Autocompletado',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14171A),
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEEF2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'BETA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF68707A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // MONITOR DE ESTADO
            const Text(
              'MONITOR DE ESTADO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF88909A),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF14171A),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _sesionOnline ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _sesionOnline
                            ? const Color(0xFF28A745)
                            : const Color(0xFF88909A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _sesionOnline
                            ? const Color(0xFF28A745)
                            : const Color(0xFF88909A),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // CAJA DE LOG / ESTADO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: _esError
                    ? const Color(0xFFFDECEC)
                    : const Color(0xFFECEEF2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _mensajeEstado,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _esError
                      ? const Color(0xFFC62828)
                      : const Color(0xFF3C4043),
                ),
              ),
            ),

            // CONTADOR DE 13 MINUTOS (CUANDO ESTÁ ONLINE)
            if (_sesionExpiraEnMs != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _menosDeUnMinuto
                        ? const Color(0xFFDC3545)
                        : const Color(0xFF28A745),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiempo restante de sesión',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A5058),
                      ),
                    ),
                    Text(
                      _tiempoRestanteTexto,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: _menosDeUnMinuto
                            ? const Color(0xFFDC3545)
                            : const Color(0xFF28A745),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // BOTONES INICIAR / DETENER
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _ocupado ? null : _iniciarFlujo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF28A745),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4A5058),
                        side: const BorderSide(color: Color(0xFFDADCE0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Detener',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // PASO 2: BLOQUE DE CAPTCHA (CUANDO EL SERVIDOR LO ENVÍA)
            if (_captchaBase64 != null) ...[
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF28A745), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Verificación Captcha',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF14171A),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _enviandoCaptcha ? null : _cambiarCaptcha,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Cambiar'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF4A5058),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (bytesCaptcha != null)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.memory(
                            bytesCaptcha,
                            height: 62,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _captchaController,
                      enabled: !_enviandoCaptcha,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Escribe el código aquí',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          letterSpacing: 0,
                          color: Color(0xFF9AA0A6),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
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
                        onPressed: _enviandoCaptcha ? null : _enviarCaptcha,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28A745),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _enviandoCaptcha
                              ? 'Validando...'
                              : 'Confirmar y Autocompletar Clave',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // SECCIÓN: CUENTAS VINCULADAS (ESTILO EO / **** 9532)
            const Text(
              'CUENTAS VINCULADAS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF88909A),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _abrirCuentasVinculadas,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE6E8EC)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEEF2),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _cuentaActiva?.iniciales ?? '+',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF3C4043),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _cuentaActiva?.alias ?? 'Vincular cuenta guardada',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF14171A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _cuentaActiva?.dniEnmascarado ??
                                'Toca para guardar DNI y Clave',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF88909A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF88909A)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // SECCIÓN: AJUSTES DE OPERACIÓN
            const Text(
              'AJUSTES DE OPERACIÓN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF88909A),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE6E8EC)),
              ),
              child: Column(
                children: [
                  // Fila Servidor
                  InkWell(
                    onTap: _editarUrlServidor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Servidor',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF14171A),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              _serverUrlController.text,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF88909A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFECEEF2)),
                  // Fila Velocidad
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Velocidad',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF14171A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECEEF2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _velocidad,
                              isDense: true,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF14171A),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'TURBO', child: Text('Turbo')),
                                DropdownMenuItem(
                                    value: 'NORMAL', child: Text('Normal')),
                                DropdownMenuItem(
                                    value: 'LENTO', child: Text('Lento')),
                              ],
                              onChanged: (val) async {
                                if (val == null) return;
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString(_keyVelocidad, val);
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
    );
  }
}