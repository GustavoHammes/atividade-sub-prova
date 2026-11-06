import 'package:intl/intl.dart';

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _numero = NumberFormat('#,##0.00', 'pt_BR');
final _decimal = NumberFormat('#,##0.###', 'pt_BR');
final _inteiro = NumberFormat.decimalPattern('pt_BR');
final _dataHora = DateFormat('dd/MM/yyyy • HH:mm', 'pt_BR');

String moeda(double valor) => _moeda.format(valor);
String numero(double valor) => _numero.format(valor);
String decimal(double valor) => _decimal.format(valor);
String inteiro(int valor) => _inteiro.format(valor);
String dataHora(DateTime valor) => _dataHora.format(valor);

double? lerDecimal(String texto) {
  final valor = double.tryParse(texto.trim().replaceAll(',', '.'));
  return valor != null && valor.isFinite && valor > 0 ? valor : null;
}
