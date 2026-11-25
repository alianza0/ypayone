import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CuentaVinculadaModel {
  final String id;
  final String alias;
  final String dni;
  final String clave;

  CuentaVinculadaModel({
    required this.id,
    required this.alias,
    required this.dni,
    required this.clave,
  });

  String get iniciales {
    final limpio = alias.trim();
    if (limpio.isEmpty) return 'CV';
    final partes = limpio.split(RegExp(r'\s+'));
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return limpio.length >= 2
        ? limpio.substring(0, 2).toUpperCase()
        : limpio[0].toUpperCase();
  }

  String get dniEnmascarado {
    if (dni.length < 4) return dni;
    return '**** ${dni.substring(dni.length - 4)}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'alias': alias,
        'dni': dni,
        'clave': clave,
      };

  factory CuentaVinculadaModel.fromJson(Map<String, dynamic> json) {
    return CuentaVinculadaModel(
      id: json['id'] ?? '',
      alias: json['alias'] ?? 'Cuenta Principal',
      dni: json['dni'] ?? '',
      clave: json['clave'] ?? '',
    );
  }
}

class CuentasVinculadasStorage {
  static const String _keyCuentas = 'ypayone_cuentas_vinculadas_v1';
  static const String _keyActivaId = 'ypayone_cuenta_activa_id_v1';

  static Future<List<CuentaVinculadaModel>> obtenerCuentas() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCuentas);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> lista = jsonDecode(raw);
    return lista
        .map((e) => CuentaVinculadaModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> guardarCuentas(List<CuentaVinculadaModel> cuentas) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(cuentas.map((c) => c.toJson()).toList());
    await prefs.setString(_keyCuentas, encoded);
  }

  static Future<String?> obtenerCuentaActivaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActivaId);
  }

  static Future<void> establecerCuentaActivaId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_keyActivaId);
    } else {
      await prefs.setString(_keyActivaId, id);
    }
  }
}

class CuentasVinculadasScreen extends StatefulWidget {
  final String? cuentaSeleccionadaId;

  const CuentasVinculadasScreen({
    super.key,
    this.cuentaSeleccionadaId,
  });

  @override
  State<CuentasVinculadasScreen> createState() =>
      _CuentasVinculadasScreenState();
}

class _CuentasVinculadasScreenState extends State<CuentasVinculadasScreen> {
  final _aliasController = TextEditingController();
  final _dniController = TextEditingController();
  final _claveController = TextEditingController();

  List<CuentaVinculadaModel> _cuentas = [];
  String? _activaId;
  bool _ocultarClave = true;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _dniController.dispose();
    _claveController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final cuentas = await CuentasVinculadasStorage.obtenerCuentas();
    final activa = widget.cuentaSeleccionadaId ??
        await CuentasVinculadasStorage.obtenerCuentaActivaId();
    if (!mounted) return;
    setState(() {
      _cuentas = cuentas;
      _activaId = activa;
      _cargando = false;
    });
  }

  Future<void> _agregarCuenta() async {
    final alias = _aliasController.text.trim().isEmpty
        ? 'Mi Cuenta'
        : _aliasController.text.trim();
    final dni = _dniController.text.trim();
    final clave = _claveController.text.trim();

    if (dni.length != 8) {
      _mostrarSnack('Ingresa un DNI válido de 8 dígitos.', esError: true);
      return;
    }
    if (clave.length != 6) {
      _mostrarSnack('La clave de internet debe tener 6 dígitos.', esError: true);
      return;
    }

    final nueva = CuentaVinculadaModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      alias: alias,
      dni: dni,
      clave: clave,
    );

    final actualizadas = [..._cuentas, nueva];
    await CuentasVinculadasStorage.guardarCuentas(actualizadas);
    await CuentasVinculadasStorage.establecerCuentaActivaId(nueva.id);

    _aliasController.clear();
    _dniController.clear();
    _claveController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _cuentas = actualizadas;
      _activaId = nueva.id;
    });

    _mostrarSnack('Cuenta guardada y vinculada correctamente.');
  }

  Future<void> _seleccionarCuenta(CuentaVinculadaModel cuenta) async {
    await CuentasVinculadasStorage.establecerCuentaActivaId(cuenta.id);
    if (!mounted) return;
    Navigator.pop(context, cuenta);
  }

  Future<void> _eliminarCuenta(CuentaVinculadaModel cuenta) async {
    final actualizadas = _cuentas.where((c) => c.id != cuenta.id).toList();
    await CuentasVinculadasStorage.guardarCuentas(actualizadas);

    String? nuevaActiva = _activaId;
    if (_activaId == cuenta.id) {
      nuevaActiva = actualizadas.isNotEmpty ? actualizadas.first.id : null;
      await CuentasVinculadasStorage.establecerCuentaActivaId(nuevaActiva);
    }

    setState(() {
      _cuentas = actualizadas;
      _activaId = nuevaActiva;
    });
    _mostrarSnack('Cuenta eliminada.');
  }

  void _mostrarSnack(String msg, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: esError ? const Color(0xFFDC3545) : const Color(0xFF28A745),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1D21), size: 20),
              onPressed: () {
                final seleccionada = _cuentas.where((c) => c.id == _activaId).firstOrNull;
                Navigator.pop(context, seleccionada);
              },
            ),
          ),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF28A745)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cuentas vinculadas',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF14171A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Guarda tus credenciales localmente para iniciar sesión con un toque.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF68707A),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SECCIÓN: CUENTAS GUARDADAS
                  const Text(
                    'PERFILES GUARDADOS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF88909A),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_cuentas.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE6E8EC)),
                      ),
                      child: const Text(
                        'Aún no tienes cuentas guardadas. Registra una abajo.',
                        style: TextStyle(color: Color(0xFF68707A), fontSize: 14),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE6E8EC)),
                      ),
                      child: Column(
                        children: List.generate(_cuentas.length, (index) {
                          final cuenta = _cuentas[index];
                          final esActiva = cuenta.id == _activaId;
                          return Column(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _seleccionarCuenta(cuenta),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: esActiva
                                              ? const Color(0xFFE7F7EC)
                                              : const Color(0xFFF0F2F5),
                                          borderRadius: BorderRadius.circular(11),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          cuenta.iniciales,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: esActiva
                                                ? const Color(0xFF1E8E3E)
                                                : const Color(0xFF3C4043),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  cuenta.alias,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF14171A),
                                                  ),
                                                ),
                                                if (esActiva) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          const Color(0xFFE7F7EC),
                                                      borderRadius:
                                                          BorderRadius.circular(20),
                                                    ),
                                                    child: const Text(
                                                      'Activa',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(0xFF1E8E3E),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              cuenta.dniEnmascarado,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF88909A),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Color(0xFF9AA0A6), size: 20),
                                        onPressed: () => _eliminarCuenta(cuenta),
                                      ),
                                      const Icon(Icons.chevron_right,
                                          color: Color(0xFF88909A)),
                                    ],
                                  ),
                                ),
                              ),
                              if (index < _cuentas.length - 1)
                                const Divider(
                                    height: 1,
                                    indent: 68,
                                    color: Color(0xFFECEEF2)),
                            ],
                          );
                        }),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // SECCIÓN: NUEVA CUENTA
                  const Text(
                    'AGREGAR NUEVO PERFIL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF88909A),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE6E8EC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Alias o nombre'),
                        TextField(
                          controller: _aliasController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration('Ej. Roger Principal'),
                        ),
                        const SizedBox(height: 14),
                        _buildLabel('DNI (8 dígitos)'),
                        TextField(
                          controller: _dniController,
                          keyboardType: TextInputType.number,
                          maxLength: 8,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: _inputDecoration('75174446'),
                        ),
                        const SizedBox(height: 14),
                        _buildLabel('Clave de Internet (6 dígitos)'),
                        TextField(
                          controller: _claveController,
                          keyboardType: TextInputType.number,
                          obscureText: _ocultarClave,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: _inputDecoration('••••••').copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _ocultarClave
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF68707A),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => _ocultarClave = !_ocultarClave);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _agregarCuenta,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF28A745),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Guardar cuenta',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4A5058),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      counterText: '',
      hintStyle: const TextStyle(color: Color(0xFFA0A7B0)),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF28A745), width: 1.5),
      ),
    );
  }
}