import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const AppDiario());

// ─────────────────────────────────────────────────────────────
// ENUM DE ATIVIDADES
// Cada tipo já carrega o texto exibido, o ícone e a cor.
// Assim, dropdown e lista usam a mesma fonte de informação.
// ─────────────────────────────────────────────────────────────
enum TipoAtividade {
  plantio('Plantio', Icons.grass, Color(0xFF2E7D32)),
  adubacao('Adubação', Icons.science, Color(0xFF8D6E63)),
  pulverizacao('Pulverização', Icons.water_drop, Color(0xFF1565C0)),
  colheita('Colheita', Icons.agriculture, Color(0xFFF9A825));

  const TipoAtividade(this.rotulo, this.icone, this.cor);

  final String rotulo;
  final IconData icone;
  final Color cor;
}

// ─────────────────────────────────────────────────────────────
// MODELO: um registro do diário
// ─────────────────────────────────────────────────────────────
class Atividade {
  final TipoAtividade tipo;
  final DateTime data;
  final String observacao;

  const Atividade({
    required this.tipo,
    required this.data,
    this.observacao = '',
  });
}

class AppDiario extends StatelessWidget {
  const AppDiario({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diário do Talhão',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E5631)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const TelaRegistroAtividade(),
    );
  }
}

class TelaRegistroAtividade extends StatefulWidget {
  const TelaRegistroAtividade({super.key});

  @override
  State<TelaRegistroAtividade> createState() => _TelaRegistroAtividadeState();
}

class _TelaRegistroAtividadeState extends State<TelaRegistroAtividade> {
  // Chave do formulário: permite validar e resetar todos os campos de uma vez
  final _formKey = GlobalKey<FormState>();

  // Atividade escolhida no dropdown (agora é o enum, não uma String)
  TipoAtividade? _atividadeSelecionada;

  // Capturam o texto digitado
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _obsController = TextEditingController();

  // Lista de atividades registradas (o "diário")
  final List<Atividade> _atividades = [];

  @override
  void dispose() {
    // Libera a memória dos controllers quando a tela sai
    _dataController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  // ───────────────── Funções auxiliares de data ─────────────────

  /// Converte "DD/MM/AAAA" em DateTime. Retorna null se for inválida.
  DateTime? _converterData(String texto) {
    final partes = texto.split('/');
    if (partes.length != 3 || partes[2].length != 4) return null;

    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);
    if (dia == null || mes == null || ano == null) return null;

    final data = DateTime(ano, mes, dia);

    // O DateTime "corrige" datas impossíveis (31/02 vira 03/03),
    // então conferimos se continua sendo o mesmo dia/mês/ano digitado.
    if (data.day != dia || data.month != mes || data.year != ano) return null;

    return data;
  }

  String _formatarData(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    return '$dia/$mes/${d.year}';
  }

  DateTime _hoje() {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, agora.day); // sem horas
  }

  // ───────────────── Validações ─────────────────

  String? _validarAtividade(TipoAtividade? valor) {
    if (valor == null) return 'Selecione o tipo de atividade';
    return null;
  }

  String? _validarData(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Informe a data';

    final data = _converterData(valor.trim());
    if (data == null) return 'Data inválida (use DD/MM/AAAA)';

    if (data.isAfter(_hoje())) return 'A data não pode ser futura';

    return null; // null = campo válido
  }

  // ───────────────── Ações ─────────────────

  Future<void> _abrirCalendario() async {
    final hoje = _hoje();
    final primeiraData = DateTime(2000);

    // A data inicial do calendário precisa estar dentro do intervalo permitido
    DateTime inicial = _converterData(_dataController.text.trim()) ?? hoje;
    if (inicial.isAfter(hoje) || inicial.isBefore(primeiraData)) inicial = hoje;

    final escolhida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primeiraData,
      lastDate: hoje, // bloqueia datas futuras no calendário
    );

    if (escolhida != null) {
      _dataController.text = _formatarData(escolhida);
    }
  }

  void _registrar() {
    // 1. Roda todos os validators. Se algum falhar, para aqui.
    if (!_formKey.currentState!.validate()) return;

    // 2. Monta o objeto com os dados já validados
    final nova = Atividade(
      tipo: _atividadeSelecionada!,
      data: _converterData(_dataController.text.trim())!,
      observacao: _obsController.text.trim(),
    );

    // 3. Atualiza o estado: adiciona, ordena e limpa o dropdown
    setState(() {
      _atividades.add(nova);
      _atividades.sort((a, b) => b.data.compareTo(a.data)); // mais recente primeiro
      _atividadeSelecionada = null;
    });

    // 4. Limpa o formulário para o próximo registro
    _formKey.currentState!.reset();
    _dataController.clear();
    _obsController.clear();
    FocusScope.of(context).unfocus(); // fecha o teclado

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${nova.tipo.rotulo} registrada com sucesso!'),
        backgroundColor: const Color(0xFF1E8449),
      ),
    );
  }

  // ───────────────── Interface ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7F1),
      appBar: AppBar(
        title: const Text('Diário de Atividades do Talhão'),
        backgroundColor: const Color(0xFF1E5631),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Preencha os dados da operação realizada no talhão:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E5631),
                ),
              ),
              const SizedBox(height: 24),

              // Dropdown gerado a partir do enum
              DropdownButtonFormField<TipoAtividade>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de Atividade',
                  prefixIcon: Icon(Icons.category),
                ),
                value: _atividadeSelecionada,
                items: TipoAtividade.values
                    .map(
                      (tipo) => DropdownMenuItem(
                        value: tipo,
                        child: Row(
                          children: [
                            Icon(tipo.icone, color: tipo.cor),
                            const SizedBox(width: 12),
                            Text(tipo.rotulo),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (TipoAtividade? novoValor) {
                  setState(() {
                    _atividadeSelecionada = novoValor;
                  });
                },
                validator: _validarAtividade,
              ),
              const SizedBox(height: 16),

              // Campo Data: pode digitar ou escolher no calendário
              TextFormField(
                controller: _dataController,
                decoration: InputDecoration(
                  labelText: 'Data',
                  hintText: 'DD/MM/AAAA',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit_calendar),
                    tooltip: 'Escolher no calendário',
                    onPressed: _abrirCalendario,
                  ),
                ),
                keyboardType: TextInputType.datetime,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: _validarData,
              ),
              const SizedBox(height: 16),

              // Campo Observação (opcional)
              TextFormField(
                controller: _obsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  hintText: 'Condições do clima, produtos usados, etc.',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40.0),
                    child: Icon(Icons.notes),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Botão de registro
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5631),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _registrar,
                child: const Text(
                  'Registrar Atividade',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),

              // ───────── Lista de atividades ─────────
              Text(
                'Atividades registradas (${_atividades.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E5631),
                ),
              ),
              const SizedBox(height: 8),

              if (_atividades.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Nenhuma atividade registrada ainda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              else
                ListView.builder(
                  // Necessário porque a lista está dentro de um SingleChildScrollView
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _atividades.length,
                  itemBuilder: (context, index) {
                    final atividade = _atividades[index];
                    final temObs = atividade.observacao.isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: atividade.tipo.cor.withAlpha(40),
                          child: Icon(
                            atividade.tipo.icone,
                            color: atividade.tipo.cor,
                          ),
                        ),
                        title: Text(
                          atividade.tipo.rotulo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          temObs
                              ? '${_formatarData(atividade.data)}\n${atividade.observacao}'
                              : _formatarData(atividade.data),
                        ),
                        isThreeLine: temObs,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
