import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'dados.dart';
import 'formatos.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.dados,
    required this.adicionar,
    required this.excluir,
  });

  final DadosDoApp dados;
  final VoidCallback adicionar;
  final VoidCallback excluir;

  @override
  Widget build(BuildContext context) {
    final veiculo = dados.veiculo!;
    final indicadores = dados.indicadores;
    final tema = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          color: tema.colorScheme.primaryContainer,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Meu veículo',
                        style: tema.textTheme.labelLarge,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Opções do veículo',
                      onSelected: (_) => excluir(),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'excluir',
                          child: Text('Excluir veículo'),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${veiculo.marca} ${veiculo.modelo}',
                    style: tema.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${veiculo.ano} • Motor ${decimal(veiculo.cilindrada)} L'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: adicionar,
          icon: const Icon(Icons.add),
          label: const Text('Novo abastecimento'),
        ),
        const SizedBox(height: 24),
        Text('Evolução', style: tema.textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (indicadores.length < 2)
          const Text('Os gráficos aparecem a partir do segundo abastecimento.')
        else ...[
          const Text(
            'O número no eixo horizontal indica a posição no histórico.',
          ),
          const SizedBox(height: 8),
          GraficoIndicador(
            titulo: 'Consumo (km/L)',
            cor: tema.colorScheme.primary,
            valores: [for (final item in indicadores.skip(1)) item.consumo!],
          ),
          const SizedBox(height: 8),
          GraficoIndicador(
            titulo: 'Custo por km (R\$/km)',
            cor: tema.colorScheme.tertiary,
            valores: [for (final item in indicadores.skip(1)) item.custoPorKm!],
          ),
        ],
        const SizedBox(height: 24),
        Text('Histórico', style: tema.textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (indicadores.isEmpty) const Text('Nenhum abastecimento registrado.'),
        for (var i = indicadores.length - 1; i >= 0; i--)
          _Registro(numeroRegistro: i + 1, indicador: indicadores[i]),
      ],
    );
  }
}

class _Registro extends StatelessWidget {
  const _Registro({required this.numeroRegistro, required this.indicador});

  final int numeroRegistro;
  final Indicador indicador;

  @override
  Widget build(BuildContext context) {
    final atual = indicador.atual;
    final tema = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Text(
                  '#$numeroRegistro · ${atual.combustivel.nome}',
                  style: tema.textTheme.titleMedium,
                ),
                Text(
                  moeda(atual.total),
                  style: tema.textTheme.titleMedium?.copyWith(
                    color: tema.colorScheme.primary,
                  ),
                ),
              ],
            ),
            Text(dataHora(atual.data)),
            const SizedBox(height: 4),
            Text(
              '${inteiro(atual.quilometragem)} km · ${decimal(atual.litros)} L · ${moeda(atual.precoPorLitro)}/L',
            ),
            const SizedBox(height: 8),
            if (indicador.distancia == null)
              const Text('Referência inicial para os próximos cálculos.')
            else
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text('${inteiro(indicador.distancia!)} km percorridos'),
                  Text('${numero(indicador.consumo!)} km/L'),
                  Text('${moeda(indicador.custoPorKm!)}/km'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class GraficoIndicador extends StatelessWidget {
  const GraficoIndicador({
    super.key,
    required this.titulo,
    required this.cor,
    required this.valores,
  });

  final String titulo;
  final Color cor;
  final List<double> valores;

  @override
  Widget build(BuildContext context) {
    final ultimo = valores.length + 1;
    final maior = valores.reduce((a, b) => a > b ? a : b);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 132,
              child: LineChart(
                LineChartData(
                  minX: 1.5,
                  maxX: ultimo + 0.5,
                  minY: 0,
                  maxY: maior * 1.2,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        minIncluded: false,
                        maxIncluded: false,
                        getTitlesWidget: (valor, meta) => Text(
                          decimal(valor),
                          style: const TextStyle(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: ((ultimo - 1) / 6).ceilToDouble(),
                        minIncluded: false,
                        maxIncluded: false,
                        getTitlesWidget: (valor, meta) => Text(
                          '#${valor.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (pontos) => [
                        for (final ponto in pontos)
                          LineTooltipItem(
                            '#${ponto.x.toInt()} · ${numero(ponto.y)}',
                            const TextStyle(color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < valores.length; i++)
                          FlSpot(i + 2.0, valores[i]),
                      ],
                      color: cor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
