// Подключаем необходимые пакеты
import 'package:flutter/material.dart';
import 'dart:math'; // используется для pow и sqrt

void main() {
  runApp(const CalculatorApp()); // запуск приложения
}

// Основной класс приложения
class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // убираем надпись Debug
      home: CalculatorHomePage(), // основной экран
    );
  }
}

// Экран калькулятора со состоянием
class CalculatorHomePage extends StatefulWidget {
  const CalculatorHomePage({super.key});

  @override
  State<CalculatorHomePage> createState() => _CalculatorHomePageState();
}

class _CalculatorHomePageState extends State<CalculatorHomePage> {
  String userInput = ''; // строка ввода выражения
  String result = '0'; // результат вычислений
  bool justCalculated = false; // только что было вычисление
  bool errorState = false; // состояние ошибки

  // Проверяем, является ли символ оператором (√ включать не нужно как бинарный оператор)
  bool _isOperator(String s) => RegExp(r'[+\-×÷^]').hasMatch(s);

  // Вспомогательная функция — получить последнее число (цифры и точка) в выражении
  String _getLastNumber(String expr) {
    if (expr.isEmpty) return '';
    int i = expr.length - 1;
    while (i >= 0 && RegExp(r'[0-9.]').hasMatch(expr[i])) {
      i--;
    }
    return expr.substring(i + 1);
  }

  // --- Обработка нажатий кнопок ---
  void buttonPressed(String value) {
    setState(() {
      // если сейчас ошибка — разрешаем только C или цифры (начало нового ввода)
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

      // Очистка
      if (value == 'C') {
        _clearAll();
        return;
      }

      // Backspace
      if (value == '←') {
        if (userInput.isNotEmpty && !justCalculated) {
          userInput = userInput.substring(0, userInput.length - 1);
        }
        return;
      }

      // = вычисление
      if (value == '=') {
        if (userInput.isEmpty) return;

        if (userInput.endsWith('=')) return; // уже вычислено

        if (_isOperator(userInput[userInput.length - 1])) {
          // нельзя завершать выражение оператором — удаляем последний оператор
          userInput = userInput.substring(0, userInput.length - 1);
          if (userInput.isEmpty) return;
        }

        // простая проверка деления на ноль
        if (userInput.contains('/0') || userInput.endsWith('÷0')) {
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

      // --- квадратный корень (√) ---
      if (value == '√') {
        // если только что было вычисление (например, 10+15=25)
        if (justCalculated || userInput.endsWith('=')) {
          double? num = double.tryParse(result);
          if (num != null && num >= 0) {
            double root = sqrt(num);
            result = _formatNumber(root); // показываем результат сразу
            userInput = '√(${_formatNumber(num)})='; // на верхней строке
            justCalculated = true;
          } else {
            result = 'Error';
            errorState = true;
            justCalculated = true;
          }
          return;
        }

        // если нет выражения, но есть число
        if (userInput.isEmpty && result != '0') {
          double? num = double.tryParse(result);
          if (num != null && num >= 0) {
            double root = sqrt(num);
            result = _formatNumber(root);
            userInput = '√(${_formatNumber(num)})=';
            justCalculated = true;
          } else {
            result = 'Error';
            errorState = true;
            justCalculated = true;
          }
          return;
        }

        // применяем к последнему числу в userInput
        String lastNumber = _getLastNumber(userInput);
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
          justCalculated = true;
        }
        return;
      }

      // Если только что нажали "=", и нажата цифра — начинаем новый ввод
      if (justCalculated && RegExp(r'[0-9.]').hasMatch(value)) {
        userInput = value;
        result = '0';
        justCalculated = false;
        return;
      }

      // Если только что было вычисление, и нажали оператор — продолжаем от результата
      if (justCalculated && _isOperator(value)) {
        userInput = result + value;
        justCalculated = false;
        return;
      }

      // Заменяем два оператора подряд (не даём "++" или "×÷" и т.п.)
      if (userInput.isNotEmpty &&
          _isOperator(userInput[userInput.length - 1]) &&
          _isOperator(value)) {
        userInput = userInput.substring(0, userInput.length - 1) + value;
        return;
      }

      // Точка — только одна в текущем числе
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

      // Добавляем символ в выражение
      userInput += value;
    });
  }

  // Очистка всех данных
  void _clearAll() {
    userInput = '';
    result = '0';
    justCalculated = false;
    errorState = false;
  }

  // --- Вычисление выражения ---
  String _calculateExpression(String expr) {
    expr = expr.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('^', '^');
    try {
      // поддержка ^ (простая: только один ^)
      if (expr.contains('^')) {
        final parts = expr.split('^');
        if (parts.length == 2) {
          double base = double.tryParse(parts[0]) ?? 0;
          double power = double.tryParse(parts[1]) ?? 0;
          return _formatNumber(pow(base, power).toDouble());
        }
      }

      double res = _basicEval(expr);
      return _formatNumber(res);
    } catch (_) {
      return 'Error';
    }
  }

  // Формат числа (до 9 знаков после точки, убрать .0)
  String _formatNumber(double value) {
    if (value.isNaN || value.isInfinite) return 'Error';
    if (value % 1 == 0) return value.toInt().toString(); // целое — без .0
    return value.toStringAsFixed(9).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  // Простой парсер выражений (без скобок)
  double _basicEval(String exp) {
    exp = exp.replaceAll(' ', '');
    if (exp.contains('+')) {
      final parts = exp.split('+');
      return _basicEval(parts[0]) + _basicEval(parts.sublist(1).join('+'));
    } else if (exp.contains('-')) {
      final parts = exp.split('-');
      if (parts.length > 1) {
        return _basicEval(parts[0]) - _basicEval(parts.sublist(1).join('-'));
      }
    } else if (exp.contains('*')) {
      final parts = exp.split('*');
      return _basicEval(parts[0]) * _basicEval(parts[1]);
    } else if (exp.contains('/')) {
      final parts = exp.split('/');
      return _basicEval(parts[0]) / _basicEval(parts[1]);
    }
    return double.tryParse(exp) ?? 0.0;
  }

  // --- Создание кнопок с эффектом нажатия ---
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

  // --- Интерфейс приложения ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4CBB2),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox.expand(
            child: Column(
              children: [
                // экран
                Expanded(
                  flex: 4,
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          userInput,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 28,
                          ),
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

                // кнопки
                Expanded(
                  flex: 7,
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            buildButton('C', Colors.grey),
                            buildButton('←', Colors.grey),
                            buildButton(
                              '√',
                              Colors.orange,
                            ), // добавлена кнопка √
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
        },
      ),
    );
  }
}
