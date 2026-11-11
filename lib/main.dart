import 'dart:math' as math;
import 'package:flutter/material.dart';

const Color kNaranja = Color(0xFFFF9500);
const Color kNegro = Color(0xFF000000);
const Color kGrisOscuro = Color(0xFF2A2A2A);
const Color kGrisMuyOscuro = Color(0xFF151515);

void main() => runApp(const CalculadoraApp());

class CalculadoraApp extends StatelessWidget {
  const CalculadoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculadora Científica',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kNegro,
        colorScheme: const ColorScheme.dark(primary: kNaranja),
      ),
      home: const PantallaCalculadora(),
    );
  }
}

class PantallaCalculadora extends StatefulWidget {
  const PantallaCalculadora({super.key});

  @override
  State<PantallaCalculadora> createState() => _PantallaCalculadoraState();
}

class _PantallaCalculadoraState extends State<PantallaCalculadora> {
  String _expresion = '';
  String _resultado = '0';
  bool _grados = true;
  double _ans = 0;

  void _manejarTecla(String etiqueta) {
    setState(() {
      if (etiqueta == 'C') {
        _expresion = '';
        _resultado = '0';
      } else if (etiqueta == '⌫') {
        if (_expresion.isNotEmpty) {
          _expresion = _expresion.substring(0, _expresion.length - 1);
        }
      } else if (etiqueta == '=') {
        try {
          final parser = Parser(_expresion, grados: _grados, ans: _ans);
          final val = parser.evaluar();
          _ans = val;
          _resultado = formatear(val);
        } catch (e) {
          _resultado = e is CalcError ? e.mensaje : 'Error';
        }
      } else {
        _expresion += etiqueta;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 680),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Calculadora Científica'),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _grados = !_grados),
                  child: Text(
                    _grados ? 'DEG' : 'RAD',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.bottomRight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _expresion,
                          style: const TextStyle(fontSize: 22, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _resultado,
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  flex: 5,
                  child: _construirTeclado(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirTeclado() {
    final botones = [
      ['sin', 'cos', 'tan', 'C', '⌫'],
      ['asin', 'acos', 'atan', '(', ')'],
      ['sinh', 'cosh', 'tanh', '√', '^'],
      ['log', 'ln', '!', 'π', '÷'],
      ['7', '8', '9', 'Ans', '×'],
      ['4', '5', '6', '%', '-'],
      ['1', '2', '3', 'e', '+'],
      ['0', '.', '='],
    ];

    return Container(
      color: kGrisMuyOscuro,
      child: Column(
        children: botones.map((fila) {
          return Expanded(
            child: Row(
              children: fila.map((etiqueta) {
                return Expanded(
                  flex: etiqueta == '=' ? 2 : 1,
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _obtenerColorTecla(etiqueta),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => _manejarTecla(etiqueta),
                      child: Text(
                        etiqueta,
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _obtenerColorTecla(String etiqueta) {
    if (etiqueta == '=' || etiqueta == 'C') return kNaranja;
    if (['+', '-', '×', '÷', '^', '%'].contains(etiqueta)) return kGrisOscuro;
    return Colors.grey.shade900;
  }
}

class CalcError implements Exception {
  final String mensaje;
  CalcError(this.mensaje);
}

class Parser {
  final String s;
  final bool grados;
  final double ans;
  int p = 0;

  Parser(this.s, {required this.grados, required this.ans});

  double evaluar() {
    final v = _suma();
    _espacios();
    if (p < s.length) throw CalcError('Error de sintaxis');
    return v;
  }

  void _espacios() {
    while (p < s.length && s[p] == ' ') {
      p++;
    }
  }

  bool _come(String c) {
    _espacios();
    if (p < s.length && s[p] == c) {
      p++;
      return true;
    }
    return false;
  }

  bool _esDigito(String c) => c.compareTo('0') >= 0 && c.compareTo('9') <= 0;
  bool _esLetra(String c) => RegExp(r'[A-Za-z]').hasMatch(c);

  bool _empiezaOperando() {
    _espacios();
    if (p >= s.length) return false;
    final c = s[p];
    return _esDigito(c) || c == '.' || c == '(' || c == 'π' || c == '√' || _esLetra(c);
  }

  double _suma() {
    var v = _producto();
    while (true) {
      if (_come('+')) {
        v += _producto();
      } else if (_come('-')) {
        v -= _producto();
      } else {
        return v;
      }
    }
  }

  double _producto() {
    var v = _unario();
    while (true) {
      if (_come('×')) {
        v *= _unario();
      } else if (_come('÷')) {
        final d = _unario();
        if (d == 0) throw CalcError('No se puede dividir entre 0');
        v /= d;
      } else if (_empiezaOperando()) {
        v *= _unario();
      } else {
        return v;
      }
    }
  }

  double _unario() {
    if (_come('-')) return -_unario();
    if (_come('+')) return _unario();
    return _potencia();
  }

  double _potencia() {
    final base = _postfijo();
    if (_come('^')) {
      final exp = _unario();
      return math.pow(base, exp).toDouble();
    }
    return base;
  }

  double _postfijo() {
    var v = _primario();
    while (true) {
      if (_come('!')) {
        v = _factorial(v);
      } else if (_come('%')) {
        v /= 100;
      } else {
        return v;
      }
    }
  }

  double _primario() {
    _espacios();
    if (p >= s.length) throw CalcError('Expresión incompleta');

    if (_come('(')) {
      final v = _suma();
      _come(')');
      return v;
    }
    if (_come('π')) return math.pi;
    if (_come('√')) {
      final a = _primario();
      if (a < 0) throw CalcError('Raíz de número negativo');
      return math.sqrt(a);
    }

    final c = s[p];
    if (_esDigito(c) || c == '.') return _numero();
    if (_esLetra(c)) return _identificador();

    throw CalcError('Error de sintaxis');
  }

  double _numero() {
    final inicio = p;
    while (p < s.length && (_esDigito(s[p]) || s[p] == '.')) {
      p++;
    }
    if (p < s.length && s[p] == 'E') {
      var q = p + 1;
      if (q < s.length && (q < s.length && (s[q] == '+' || s[q] == '-'))) q++;
      if (q < s.length && _esDigito(s[q])) {
        while (q < s.length && _esDigito(s[q])) {
          q++;
        }
        p = q;
      }
    }
    final v = double.tryParse(s.substring(inicio, p));
    if (v == null) throw CalcError('Número inválido');
    return v;
  }

  double _identificador() {
    final inicio = p;
    while (p < s.length && _esLetra(s[p])) {
      p++;
    }
    final nombre = s.substring(inicio, p);

    if (nombre == 'e') return math.e;
    if (nombre == 'Ans') return ans;

    if (!_come('(')) throw CalcError('Error de sintaxis');
    final a = _suma();
    _come(')');
    return _funcion(nombre, a);
  }

  double _aRad(double x) => grados ? x * math.pi / 180 : x;
  double _deRad(double x) => grados ? x * 180 / math.pi : x;

  double _funcion(String nombre, double a) {
    switch (nombre) {
      case 'sin':
        return math.sin(_aRad(a));
      case 'cos':
        return math.cos(_aRad(a));
      case 'tan':
        final r = _aRad(a);
        if (math.cos(r).abs() < 1e-12) throw CalcError('tan no definida');
        return math.tan(r);
      case 'asin':
        if (a < -1 || a > 1) throw CalcError('Fuera del dominio');
        return _deRad(math.asin(a));
      case 'acos':
        if (a < -1 || a > 1) throw CalcError('Fuera del dominio');
        return _deRad(math.acos(a));
      case 'atan':
        return _deRad(math.atan(a));
      case 'sinh':
        return (math.exp(a) - math.exp(-a)) / 2;
      case 'cosh':
        return (math.exp(a) + math.exp(-a)) / 2;
      case 'tanh':
        final e1 = math.exp(a), e2 = math.exp(-a);
        return (e1 - e2) / (e1 + e2);
      case 'log':
        if (a <= 0) throw CalcError('log solo de números > 0');
        return math.log(a) / math.ln10;
      case 'ln':
        if (a <= 0) throw CalcError('ln solo de números > 0');
        return math.log(a);
      case 'abs':
        return a.abs();
      case 'cbrt':
        return a < 0 ? -math.pow(-a, 1 / 3).toDouble() : math.pow(a, 1 / 3).toDouble();
      default:
        throw CalcError('Función desconocida: $nombre');
    }
  }

  double _factorial(double n) {
    if (n < 0 || n != n.roundToDouble()) {
      throw CalcError('Factorial solo de enteros ≥ 0');
    }
    if (n > 170) throw CalcError('Número demasiado grande');
    double r = 1;
    for (int i = 2; i <= n.toInt(); i++) {
      r *= i;
    }
    return r;
  }
}

String formatear(double v) {
  if (v.isNaN || v.isInfinite) throw CalcError('Error matemático');
  if (v.abs() < 1e-12) v = 0;
  if (v == v.roundToDouble() && v.abs() < 1e15) return v.toInt().toString();

  var t = v.toStringAsPrecision(10);
  String quitaCeros(String x) {
    if (!x.contains('.')) return x;
    return x.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  if (t.contains('e')) {
    final partes = t.split('e');
    return '${quitaCeros(partes[0])}E${partes[1].replaceFirst('+', '')}';
  }
  return quitaCeros(t);
}

enum Tipo { numero, funcion, operador, borrar }

class Tecla {
  final String etiqueta;
  final VoidCallback alPresionar;
  final Tipo tipo;
  final bool activa;
  final IconData? icono;
  Tecla(this.etiqueta, this.alPresionar,
      {this.tipo = Tipo.funcion, this.activa = false, this.icono});
}