import 'package:flutter/material.dart';

import 'dados.dart';
import 'formatos.dart';

class FormularioAbastecimento extends StatefulWidget {
  const FormularioAbastecimento({super.key, required this.salvar});

  final Future<void> Function(Abastecimento) salvar;

  @override
  State<FormularioAbastecimento> createState() =>
      _FormularioAbastecimentoState();
}

class _FormularioAbastecimentoState extends State<FormularioAbastecimento> {
  final _form = GlobalKey<FormState>();
  final _preco = TextEditingController();
  final _quilometragem = TextEditingController();
  final _litros = TextEditingController();
  Combustivel? _combustivel;
  DateTime _data = DateTime.now();
  bool _salvando = false;

  @override
  void dispose() {
    _preco.dispose();
    _quilometragem.dispose();
    _litros.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final dia = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (dia == null || !mounted) return;
    setState(
      () => _data = DateTime(
        dia.year,
        dia.month,
        dia.day,
        _data.hour,
        _data.minute,
      ),
    );
  }

  Future<void> _escolherHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_data),
    );
    if (hora == null || !mounted) return;
    setState(
      () => _data = DateTime(
        _data.year,
        _data.month,
        _data.day,
        hora.hour,
        hora.minute,
      ),
    );
  }

  double? get _total {
    final preco = lerDecimal(_preco.text);
    final litros = lerDecimal(_litros.text);
    if (preco == null || litros == null) return null;
    return preco * litros;
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    final data = DateUtils.dateOnly(
      _data,
    ).copyWith(hour: _data.hour, minute: _data.minute);
    if (data.isAfter(DateTime.now())) {
      _mensagem('Escolha uma data e hora que já passaram.');
      return;
    }
    if (!_total!.isFinite || _total! <= 0) {
      _mensagem('Confira o preço e a quantidade de litros.');
      return;
    }

    setState(() => _salvando = true);
    try {
      await widget.salvar(
        Abastecimento(
          combustivel: _combustivel!,
          precoPorLitro: lerDecimal(_preco.text)!,
          quilometragem: int.parse(_quilometragem.text.trim()),
          litros: lerDecimal(_litros.text)!,
          data: data,
        ),
      );
      if (mounted) Navigator.pop(context);
    } on FormatException catch (erro) {
      if (!mounted) return;
      _mensagem(erro.message);
      setState(() => _salvando = false);
    } catch (_) {
      if (!mounted) return;
      _mensagem('Não foi possível salvar o abastecimento.');
      setState(() => _salvando = false);
    }
  }

  Widget _campoDecimal(
    TextEditingController controller,
    String rotulo,
    String exemplo,
  ) {
    return TextFormField(
      controller: controller,
      enabled: !_salvando,
      decoration: InputDecoration(labelText: rotulo, hintText: exemplo),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (texto) => lerDecimal(texto!) == null
          ? 'Informe um valor maior que zero.'
          : null,
      onChanged: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    return PopScope(
      canPop: !_salvando,
      child: Scaffold(
        appBar: AppBar(title: const Text('Novo abastecimento')),
        body: SafeArea(
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Registre abastecimentos que completaram o tanque.'),
                const SizedBox(height: 20),
                DropdownButtonFormField<Combustivel>(
                  decoration: const InputDecoration(labelText: 'Combustível'),
                  items: [
                    for (final tipo in Combustivel.values)
                      DropdownMenuItem(value: tipo, child: Text(tipo.nome)),
                  ],
                  onChanged: _salvando ? null : (tipo) => _combustivel = tipo,
                  validator: (tipo) =>
                      tipo == null ? 'Selecione o combustível.' : null,
                ),
                const SizedBox(height: 16),
                _campoDecimal(_preco, 'Preço por litro (R\$)', '5,89'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quilometragem,
                  enabled: !_salvando,
                  decoration: const InputDecoration(
                    labelText: 'Quilometragem (km)',
                    hintText: '40000',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (texto) {
                    final km = int.tryParse(texto!.trim());
                    return km == null || km < 0
                        ? 'Informe a quilometragem em km inteiros.'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                _campoDecimal(_litros, 'Quantidade de litros', '40,5'),
                const SizedBox(height: 16),
                Text(
                  dataHora(_data),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: _salvando ? null : _escolherData,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: const Text('Alterar data'),
                    ),
                    TextButton.icon(
                      onPressed: _salvando ? null : _escolherHora,
                      icon: const Icon(Icons.schedule),
                      label: const Text('Alterar hora'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Valor total: ${total != null && total.isFinite ? moeda(total) : '—'}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _salvando ? null : _salvar,
                  child: Text(_salvando ? 'Salvando…' : 'Salvar abastecimento'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
