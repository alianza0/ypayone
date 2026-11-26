import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_text.dart';
import '../../widgets/app_message.dart';

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
  static const _textDark = Color(0xFF1F1D2B);
  static const _sectionLabel = Color(0xFF757285);
  static const _muted = Color(0xFF8C899B);
  static const _divider = Color(0xFFF0EEF5);
  static const _purple = Color(0xFF6A1B7A);

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
      showAppMessage(context, 'Ingresa un DNI válido de 8 dígitos.', error: true);
      return;
    }
    if (clave.length != 6) {
      showAppMessage(
        context,
        'La clave de internet debe tener 6 dígitos.',
        error: true,
      );
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

    if (mounted) {
      showAppMessage(context, 'Cuenta guardada y vinculada.', error: false);
    }
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
    if (mounted) {
      showAppMessage(context, 'Cuenta eliminada.', error: false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  child: _cargando
                      ? const Center(
                          child: CircularProgressIndicator(color: _purple),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cuentas vinculadas',
                                style: appFont(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: _textDark,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Guarda tus datos localmente para no escribirlos cada vez.',
                                style: appFont(fontSize: 15, color: _muted),
                              ),
                              const SizedBox(height: 22),

                              Text(
                                'PERFILES GUARDADOS',
                                style: appFont(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _sectionLabel,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _cardContainer(
                                child: _cuentas.isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: Text(
                                          'Aún no tienes cuentas guardadas. Registra una abajo.',
                                          style: appFont(
                                            fontSize: 14.5,
                                            color: _muted,
                                          ),
                                        ),
                                      )
                                    : Column(
                                        children: List.generate(
                                          _cuentas.length,
                                          (index) {
                                            final cuenta = _cuentas[index];
                                            final esActiva =
                                                cuenta.id == _activaId;
                                            return Column(
                                              children: [
                                                InkWell(
                                                  onTap: () =>
                                                      _seleccionarCuenta(cuenta),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 18,
                                                      vertical: 13,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 40,
                                                          height: 40,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: esActiva
                                                                ? _purple
                                                                    .withValues(
                                                                        alpha:
                                                                            0.14)
                                                                : const Color(
                                                                    0xFFF4F2FA),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            cuenta.iniciales,
                                                            style: appFont(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color: esActiva
                                                                  ? _purple
                                                                  : _textDark,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 14),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    cuenta
                                                                        .alias,
                                                                    style: appFont(
                                                                      fontSize:
                                                                          15.5,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color:
                                                                          _textDark,
                                                                    ),
                                                                  ),
                                                                  if (esActiva) ...[
                                                                    const SizedBox(
                                                                        width:
                                                                            8),
                                                                    Container(
                                                                      padding:
                                                                          const EdgeInsets
                                                                              .symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            2,
                                                                      ),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: _purple
                                                                            .withValues(
                                                                                alpha: 0.12),
                                                                        borderRadius:
                                                                            BorderRadius.circular(12),
                                                                      ),
                                                                      child: Text(
                                                                        'Activa',
                                                                        style:
                                                                            appFont(
                                                                          fontSize: 11,
                                                                          fontWeight: FontWeight.w700,
                                                                          color: _purple,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                  height: 2),
                                                              Text(
                                                                cuenta
                                                                    .dniEnmascarado,
                                                                style: appFont(
                                                                  fontSize: 13,
                                                                  color: _muted,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons
                                                                .delete_outline_rounded,
                                                            color: _muted,
                                                            size: 20,
                                                          ),
                                                          onPressed: () =>
                                                              _eliminarCuenta(
                                                                  cuenta),
                                                        ),
                                                        const Icon(
                                                          Icons
                                                              .chevron_right_rounded,
                                                          color: _muted,
                                                          size: 22,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                if (index < _cuentas.length - 1)
                                                  _dividerLine(),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                              ),

                              const SizedBox(height: 22),

                              Text(
                                'NUEVO PERFIL',
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
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('Alias o nombre'),
                                      TextField(
                                        controller: _aliasController,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        style: appFont(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: _textDark,
                                        ),
                                        decoration: _inputDecoration(
                                          'Ej. Roger Principal',
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      _buildFieldLabel('DNI (8 dígitos)'),
                                      TextField(
                                        controller: _dniController,
                                        keyboardType: TextInputType.number,
                                        maxLength: 8,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        style: appFont(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: _textDark,
                                        ),
                                        decoration:
                                            _inputDecoration('75174446'),
                                      ),
                                      const SizedBox(height: 14),
                                      _buildFieldLabel(
                                        'Clave de internet (6 dígitos)',
                                      ),
                                      TextField(
                                        controller: _claveController,
                                        keyboardType: TextInputType.number,
                                        obscureText: _ocultarClave,
                                        maxLength: 6,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        style: appFont(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: _textDark,
                                        ),
                                        decoration:
                                            _inputDecoration('••••••').copyWith(
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _ocultarClave
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                              color: _muted,
                                              size: 20,
                                            ),
                                            onPressed: () => setState(
                                              () =>
                                                  _ocultarClave = !_ocultarClave,
                                            ),
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
                                            backgroundColor: _purple,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: Text(
                                            'Guardar perfil',
                                            style: appFont(
                                              fontSize: 15,
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
          onTap: () {
            final seleccionada =
                _cuentas.where((c) => c.id == _activaId).firstOrNull;
            Navigator.pop(context, seleccionada);
          },
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

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: appFont(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: _textDark,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      counterText: '',
      hintStyle: appFont(fontSize: 14, color: _muted),
      filled: true,
      fillColor: const Color(0xFFF4F2FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _purple, width: 1.5),
      ),
    );
  }
}