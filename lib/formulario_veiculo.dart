import 'package:flutter/material.dart';

import 'api_fipe.dart';
import 'dados.dart';
import 'formatos.dart';

class FormularioVeiculo extends StatefulWidget {
  const FormularioVeiculo({super.key, required this.salvar});

  final Future<void> Function(Veiculo) salvar;

  @override
  State<FormularioVeiculo> createState() => _FormularioVeiculoState();
}

class _FormularioVeiculoState extends State<FormularioVeiculo> {
  final _form = GlobalKey<FormState>();
  final _api = ApiFipe();
  final _ano = TextEditingController();
  final _cilindrada = TextEditingController();
  late Future<List<OpcaoFipe>> _marcas;
  Future<List<OpcaoFipe>>? _modelos;
  OpcaoFipe? _marca;
  OpcaoFipe? _modelo;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _marcas = _api.buscarMarcas();
  }

  @override
  void dispose() {
    _ano.dispose();
    _cilindrada.dispose();
    super.dispose();
  }

  void _selecionarMarca(OpcaoFipe? marca) {
    if (marca == null || marca == _marca) return;
    setState(() {
      _marca = marca;
      _modelo = null;
      _modelos = _api.buscarModelos(marca.codigo);
    });
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate() || _marca == null || _modelo == null) {
      return;
    }

    setState(() => _salvando = true);
    try {
      await widget.salvar(
        Veiculo(
          _marca!.nome,
          _modelo!.nome,
          int.parse(_ano.text.trim()),
          lerDecimal(_cilindrada.text)!,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o veículo.')),
      );
      setState(() => _salvando = false);
    }
  }

  Widget _seletor({
    required String rotulo,
    required String item,
    required Future<List<OpcaoFipe>> busca,
    required OpcaoFipe? selecionado,
    required ValueChanged<OpcaoFipe?> selecionar,
    required VoidCallback tentarNovamente,
  }) {
    return FutureBuilder<List<OpcaoFipe>>(
      future: busca,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('Consultando ${rotulo.toLowerCase()}s na FIPE…'),
          );
        }
        if (snapshot.hasError) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Falha ao consultar ${rotulo.toLowerCase()}s.'),
            subtitle: const Text('Verifique sua conexão e tente novamente.'),
            trailing: IconButton(
              tooltip: 'Tentar novamente',
              onPressed: tentarNovamente,
              icon: const Icon(Icons.refresh),
            ),
          );
        }

        final opcoes = snapshot.data!;
        if (opcoes.isEmpty) return Text('Nenhum resultado para $item.');

        return DropdownButtonFormField<OpcaoFipe>(
          key: ObjectKey(busca),
          initialValue: selecionado,
          decoration: InputDecoration(labelText: rotulo),
          isExpanded: true,
          menuMaxHeight: 360,
          items: [
            for (final opcao in opcoes)
              DropdownMenuItem(
                value: opcao,
                child: Text(opcao.nome, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: _salvando ? null : selecionar,
          validator: (valor) => valor == null ? 'Selecione $item.' : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_salvando,
      child: Scaffold(
        appBar: AppBar(title: const Text('Cadastrar veículo')),
        body: SafeArea(
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Escolha a marca e o modelo no catálogo da FIPE.'),
                const SizedBox(height: 20),
                _seletor(
                  rotulo: 'Marca',
                  item: 'uma marca',
                  busca: _marcas,
                  selecionado: _marca,
                  selecionar: _selecionarMarca,
                  tentarNovamente: () =>
                      setState(() => _marcas = _api.buscarMarcas()),
                ),
                const SizedBox(height: 16),
                if (_modelos == null)
                  const TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Modelo',
                      hintText: 'Escolha a marca primeiro',
                    ),
                  )
                else
                  _seletor(
                    rotulo: 'Modelo',
                    item: 'um modelo',
                    busca: _modelos!,
                    selecionado: _modelo,
                    selecionar: (modelo) => setState(() => _modelo = modelo),
                    tentarNovamente: _recarregarModelos,
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ano,
                  enabled: !_salvando,
                  decoration: const InputDecoration(
                    labelText: 'Ano',
                    hintText: '2020',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (texto) {
                    final ano = int.tryParse(texto!.trim());
                    return ano == null ||
                            ano < 1886 ||
                            ano > DateTime.now().year + 1
                        ? 'Informe um ano válido.'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cilindrada,
                  enabled: !_salvando,
                  decoration: const InputDecoration(
                    labelText: 'Cilindrada do motor (L)',
                    hintText: '1,0',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (texto) => lerDecimal(texto!) == null
                      ? 'Informe a cilindrada em litros.'
                      : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _salvando || _modelo == null ? null : _salvar,
                  child: Text(_salvando ? 'Salvando…' : 'Salvar veículo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _recarregarModelos() {
    setState(() => _modelos = _api.buscarModelos(_marca!.codigo));
  }
}
