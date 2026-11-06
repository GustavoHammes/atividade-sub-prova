import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'dados.dart';
import 'dashboard.dart';
import 'formulario_abastecimento.dart';
import 'formulario_veiculo.dart';

void main() => runApp(const AppCombustivel());

class AppCombustivel extends StatelessWidget {
  const AppCombustivel({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de combustível',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006B60)),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const TelaInicial(),
    );
  }
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  final _armazenamento = ArmazenamentoLocal();
  DadosDoApp? _dados;
  bool _erroAoCarregar = false;
  bool _excluindo = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final dados = await _armazenamento.carregar();
      if (mounted) setState(() => _dados = dados);
    } catch (_) {
      if (mounted) setState(() => _erroAoCarregar = true);
    }
  }

  Future<void> _salvar(DadosDoApp novosDados) async {
    await _armazenamento.salvar(novosDados);
    if (mounted) setState(() => _dados = novosDados);
  }

  void _cadastrarVeiculo() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioVeiculo(
          salvar: (veiculo) => _salvar(DadosDoApp(veiculo: veiculo)),
        ),
      ),
    );
  }

  void _registrarAbastecimento() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioAbastecimento(
          salvar: (registro) async {
            await _salvar(_dados!.adicionarAbastecimento(registro));
          },
        ),
      ),
    );
  }

  Future<void> _excluirVeiculo() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir veículo?'),
        content: const Text(
          'O veículo e todos os seus abastecimentos serão excluídos deste aparelho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    setState(() => _excluindo = true);
    try {
      await _salvar(const DadosDoApp());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir o veículo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _excluindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controle de combustível')),
      body: SafeArea(child: _conteudo()),
    );
  }

  Widget _conteudo() {
    final dados = _dados;
    if (_erroAoCarregar) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Não foi possível abrir os dados salvos.'),
              TextButton(
                onPressed: () {
                  setState(() => _erroAoCarregar = false);
                  _carregar();
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (dados == null || _excluindo) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dados.veiculo != null) {
      return Dashboard(
        dados: dados,
        adicionar: _registrarAbastecimento,
        excluir: _excluirVeiculo,
      );
    }

    final tema = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: tema.colorScheme.primaryContainer,
              child: Icon(
                Icons.local_gas_station_outlined,
                size: 34,
                color: tema.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Seu primeiro veículo',
              style: tema.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cadastre um veículo para acompanhar seus abastecimentos e o consumo ao longo do tempo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _cadastrarVeiculo,
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar veículo'),
            ),
          ],
        ),
      ),
    );
  }
}
