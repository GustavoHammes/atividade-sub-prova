import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Veiculo {
  const Veiculo(this.marca, this.modelo, this.ano, this.cilindrada);

  final String marca;
  final String modelo;
  final int ano;
  final double cilindrada;

  factory Veiculo.deJson(Map<String, dynamic> json) => Veiculo(
    json['marca'] as String,
    json['modelo'] as String,
    json['ano'] as int,
    (json['cilindrada'] as num).toDouble(),
  );

  Map<String, dynamic> paraJson() => {
    'marca': marca,
    'modelo': modelo,
    'ano': ano,
    'cilindrada': cilindrada,
  };
}

enum Combustivel {
  etanol('Etanol'),
  gasolina('Gasolina'),
  diesel('Diesel');

  const Combustivel(this.nome);
  final String nome;
}

class Abastecimento {
  const Abastecimento({
    required this.combustivel,
    required this.precoPorLitro,
    required this.quilometragem,
    required this.litros,
    required this.data,
  });

  final Combustivel combustivel;
  final double precoPorLitro;
  final int quilometragem;
  final double litros;
  final DateTime data;

  double get total => precoPorLitro * litros;

  factory Abastecimento.deJson(Map<String, dynamic> json) => Abastecimento(
    combustivel: Combustivel.values.byName(json['combustivel'] as String),
    precoPorLitro: (json['precoPorLitro'] as num).toDouble(),
    quilometragem: json['quilometragem'] as int,
    litros: (json['litros'] as num).toDouble(),
    data: DateTime.parse(json['data'] as String).toLocal(),
  );

  Map<String, dynamic> paraJson() => {
    'combustivel': combustivel.name,
    'precoPorLitro': precoPorLitro,
    'quilometragem': quilometragem,
    'litros': litros,
    'data': data.toUtc().toIso8601String(),
  };
}

// A lista recebida está em ordem cronológica, do mais antigo ao mais recente.
class Indicador {
  Indicador(this.atual, Abastecimento? anterior)
    : distancia = anterior == null
          ? null
          : atual.quilometragem - anterior.quilometragem;

  final Abastecimento atual;
  final int? distancia;

  double? get consumo => distancia == null ? null : distancia! / atual.litros;
  double? get custoPorKm => distancia == null ? null : atual.total / distancia!;
}

class DadosDoApp {
  const DadosDoApp({this.veiculo, this.abastecimentos = const []});

  final Veiculo? veiculo;
  final List<Abastecimento> abastecimentos;

  List<Indicador> get indicadores => [
    for (var i = 0; i < abastecimentos.length; i++)
      Indicador(abastecimentos[i], i == 0 ? null : abastecimentos[i - 1]),
  ];

  DadosDoApp adicionarAbastecimento(Abastecimento novo) {
    final registros = [...abastecimentos, novo]
      ..sort((a, b) => a.data.compareTo(b.data));

    for (var i = 1; i < registros.length; i++) {
      final anterior = registros[i - 1];
      final atual = registros[i];
      if (atual.data.isAtSameMomentAs(anterior.data)) {
        throw const FormatException('Já existe um registro nessa data e hora.');
      }
      if (atual.quilometragem <= anterior.quilometragem) {
        throw const FormatException(
          'A quilometragem deve aumentar na ordem das datas do histórico.',
        );
      }
    }

    return DadosDoApp(veiculo: veiculo, abastecimentos: registros);
  }
}

class ArmazenamentoLocal {
  static const _chave = 'controle_combustivel';
  final _preferencias = SharedPreferencesAsync();

  Future<DadosDoApp> carregar() async {
    final texto = await _preferencias.getString(_chave);
    if (texto == null) return const DadosDoApp();

    final json = jsonDecode(texto) as Map<String, dynamic>;
    final veiculo = Veiculo.deJson(json['veiculo'] as Map<String, dynamic>);
    final registros = (json['abastecimentos'] as List)
        .map((item) => Abastecimento.deJson(item as Map<String, dynamic>))
        .toList();
    return DadosDoApp(veiculo: veiculo, abastecimentos: registros);
  }

  Future<void> salvar(DadosDoApp dados) async {
    final veiculo = dados.veiculo;
    if (veiculo == null) {
      // Veículo e histórico ficam na mesma chave, então são excluídos juntos.
      await _preferencias.remove(_chave);
      return;
    }

    await _preferencias.setString(
      _chave,
      jsonEncode({
        'veiculo': veiculo.paraJson(),
        'abastecimentos': [
          for (final registro in dados.abastecimentos) registro.paraJson(),
        ],
      }),
    );
  }
}
