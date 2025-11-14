import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CalculatorHomePage(),
    );
  }
}

class CalculatorHomePage extends StatefulWidget {
  const CalculatorHomePage({super.key});

  @override
  State<CalculatorHomePage> createState() => _CalculatorHomePageState();
}

class _CalculatorHomePageState extends State<CalculatorHomePage> {
  String userInput = '';
  String result = '0';
  bool justCalculated = false;
  bool errorState = false;

  bool _isOperator(String s) => RegExp(r'[+\-×÷^*/]').hasMatch(s);

  String _getLastNumber(String expr) {
    if (expr.isEmpty) return '';
    int i = expr.length - 1;
    while (i >= 0 && RegExp(r'[0-9.]').hasMatch(expr[i])) {
      i--;
    }
    return expr.substring(i + 1);
  }

  void buttonPressed(String value) {
    setState(() {
      if (errorState) {
        if (value == 'C') {
          _clearAll();
        } else if (RegExp(r'[0-9.]').hasMatch(value)) {
          userInput = value;
          result = '0';
          justCalculated = false;
          errorState = false;
        }
        return;
      }

      if (value == 'C') {
        _clearAll();
        return;
      }

      if (value == '←') {
        if (userInput.isNotEmpty && !justCalculated) {
          userInput = userInput.substring(0, userInput.length - 1);
        }
        return;
      }

      if (value == '=') {
        if (userInput.isEmpty) return;
        if (userInput.endsWith('=')) return;

        if (_isOperator(userInput[userInput.length - 1])) {
          userInput = userInput.substring(0, userInput.length - 1);
          if (userInput.isEmpty) return;
        }

        // ❗ Проверяем, что выражение не состоит только из нулей
        if (RegExp(r'^0+(\.0+)?$').hasMatch(userInput)) {
          result = 'Error';
          errorState = true;
          justCalculated = true;
          return;
        }

        try {
          result = _calculateExpression(userInput);
          userInput += '=';
          justCalculated = true;
        } catch (_) {
          result = 'Error';
          errorState = true;
          justCalculated = true;
        }
        return;
      }

      if (value == '√') {
        String lastNumber = _getLastNumber(userInput);
        if (lastNumber.isEmpty && result != '0') {
          double? num = double.tryParse(result);
          if (num != null && num >= 0) {
            double root = sqrt(num);
            result = _formatNumber(root);
            userInput = '√(${_formatNumber(num)})=';
            justCalculated = true;
          } else {
            result = 'Error';
            errorState = true;
          }
          return;
        }
        if (lastNumber.isEmpty) return;
        double? num = double.tryParse(lastNumber);
        if (num != null && num >= 0) {
          double root = sqrt(num);
          userInput = userInput.replaceRange(
            userInput.length - lastNumber.length,
            userInput.length,
            _formatNumber(root),
          );
          result = _formatNumber(root);
          justCalculated = true;
        } else {
          result = 'Error';
          errorState = true;
        }
        return;
      }

      // после вычисления новое число
      if (justCalculated && RegExp(r'[0-9.]').hasMatch(value)) {
        userInput = value;
        result = '0';
        justCalculated = false;
        return;
      }

      // продолжаем выражение
      if (justCalculated && _isOperator(value)) {
        userInput = result + value;
        justCalculated = false;
        return;
      }

      // защита от двойных операторов
      if (userInput.isNotEmpty &&
          _isOperator(userInput[userInput.length - 1]) &&
          _isOperator(value)) {
        userInput = userInput.substring(0, userInput.length - 1) + value;
        return;
      }

      // при нажатии точки в начале числа
      if (value == '.' &&
          (userInput.isEmpty || _isOperator(userInput[userInput.length - 1]))) {
        userInput += '0.';
        return;
      }

      // одна точка на число
      if (value == '.') {
        int lastOp = -1;
        for (int i = userInput.length - 1; i >= 0; i--) {
          if (_isOperator(userInput[i])) {
            lastOp = i;
            break;
          }
        }
        String currentNumber = userInput.substring(lastOp + 1);
        if (currentNumber.contains('.')) return;
      }

      // 🚫 запрещаем вводить несколько нулей подряд в начале числа
      if (value == '0') {
        String last = _getLastNumber(userInput);
        if (last == '0' && !_isOperator(userInput[userInput.length - 1])) {
          return; // не добавляем второй ноль
        }
      }

      userInput += value;
    });
  }

  void _clearAll() {
    userInput = '';
    result = '0';
    justCalculated = false;
    errorState = false;
  }

  String _calculateExpression(String expr) {
    expr = expr.replaceAll('×', '*').replaceAll('÷', '/');

    while (expr.contains('^')) {
      int idx = expr.indexOf('^');
      int baseStart = idx - 1;
      while (baseStart >= 0 && RegExp(r'[0-9.]').hasMatch(expr[baseStart])) {
        baseStart--;
      }
      baseStart++;

      int expEnd = idx + 1;
      while (expEnd < expr.length &&
          RegExp(r'[0-9.\-]').hasMatch(expr[expEnd])) {
        expEnd++;
      }

      final baseStr = expr.substring(baseStart, idx);
      final expStr = expr.substring(idx + 1, expEnd);

      double baseVal = double.tryParse(baseStr) ?? 0;
      double expVal = double.tryParse(expStr) ?? 0;

      // если всё нули — ошибка
      if (baseVal == 0 && expVal > 0) {
        return '0';
      }
      if (baseVal == 0 && expVal == 0) {
        return 'Error';
      }

      double powRes = pow(baseVal, expVal).toDouble();
      expr = expr.replaceRange(baseStart, expEnd, powRes.toString());
    }

    double res = _basicEval(expr);
    return _formatNumber(res);
  }

  String _formatNumber(double value) {
    if (value.isNaN || value.isInfinite) return 'Error';
    if (value == 0) return '0';
    String str = value.toStringAsPrecision(12);
    str = str.replaceFirst(RegExp(r'\.?0+$'), '');
    if (str.startsWith('.')) str = '0$str';
    return str;
  }

  double _basicEval(String exp) {
    exp = exp.replaceAll(' ', '');
    if (exp.isEmpty) return 0;

    // * и /
    List<String> tokens = exp.split(RegExp(r'(?=[*/])|(?<=[*/])'));
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == '*' || tokens[i] == '/') {
        double left = double.tryParse(tokens[i - 1]) ?? 0;
        double right = double.tryParse(tokens[i + 1]) ?? 1;
        double res = tokens[i] == '*' ? left * right : left / right;
        tokens[i - 1] = res.toString();
        tokens.removeRange(i, i + 2);
        i = 0;
      }
    }

    // + и -
    String joined = tokens.join();
    List<String> addParts = joined.split(RegExp(r'(?=[+-])|(?<=[+-])'));
    double total = 0;
    String op = '+';
    for (var part in addParts) {
      if (part == '+' || part == '-') {
        op = part;
      } else if (part.isNotEmpty) {
        double val = double.tryParse(part) ?? 0;
        total = (op == '+') ? total + val : total - val;
      }
    }
    return total;
  }

  Widget buildButton(String text, Color bg, {Color fg = Colors.white}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(40),
          child: InkWell(
            borderRadius: BorderRadius.circular(40),
            splashColor: Colors.white24,
            highlightColor: Colors.white10,
            onTap: () => buttonPressed(text),
            child: Container(
              height: 85,
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                  color: fg,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4CBB2),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.black,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    userInput,
                    style: const TextStyle(color: Colors.white70, fontSize: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    result,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Container(
              color: Colors.black,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      buildButton('C', Colors.grey),
                      buildButton('←', Colors.grey),
                      buildButton('√', Colors.orange),
                      buildButton('^', Colors.orange),
                    ],
                  ),
                  Row(
                    children: [
                      buildButton('7', const Color(0xFF333333)),
                      buildButton('8', const Color(0xFF333333)),
                      buildButton('9', const Color(0xFF333333)),
                      buildButton('÷', Colors.orange),
                    ],
                  ),
                  Row(
                    children: [
                      buildButton('4', const Color(0xFF333333)),
                      buildButton('5', const Color(0xFF333333)),
                      buildButton('6', const Color(0xFF333333)),
                      buildButton('×', Colors.orange),
                    ],
                  ),
                  Row(
                    children: [
                      buildButton('1', const Color(0xFF333333)),
                      buildButton('2', const Color(0xFF333333)),
                      buildButton('3', const Color(0xFF333333)),
                      buildButton('-', Colors.orange),
                    ],
                  ),
                  Row(
                    children: [
                      buildButton('0', const Color(0xFF333333)),
                      buildButton('.', const Color(0xFF333333)),
                      buildButton('=', Colors.orange),
                      buildButton('+', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
