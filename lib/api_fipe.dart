import 'dart:convert';

import 'package:http/http.dart' as http;

class OpcaoFipe {
  const OpcaoFipe(this.codigo, this.nome);

  final String codigo;
  final String nome;
}

class ApiFipe {
  Future<List<OpcaoFipe>> buscarMarcas() => _buscar('brands');

  Future<List<OpcaoFipe>> buscarModelos(String codigoMarca) =>
      _buscar('brands/$codigoMarca/models');

  Future<List<OpcaoFipe>> _buscar(String caminho) async {
    final url = Uri.https('fipe.parallelum.com.br', '/api/v2/cars/$caminho');
    final resposta = await http.get(url).timeout(const Duration(seconds: 12));
    if (resposta.statusCode != 200) {
      throw StateError('A API respondeu com o código ${resposta.statusCode}.');
    }

    final lista = jsonDecode(utf8.decode(resposta.bodyBytes)) as List;
    return lista
        .map(
          (item) => OpcaoFipe(item['code'] as String, item['name'] as String),
        )
        .toList();
  }
}
