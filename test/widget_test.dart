import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diario_talhao/main.dart';

String _formatar(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

Future<void> _escolherAtividade(WidgetTester tester, String rotulo) async {
  await tester.tap(find.byType(DropdownButtonFormField<TipoAtividade>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(rotulo).last);
  await tester.pumpAndSettle();
}

Future<void> _registrar(WidgetTester tester) async {
  final botao = find.text('Registrar Atividade');
  await tester.ensureVisible(botao);
  await tester.tap(botao);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Recusa registro sem atividade e sem data', (tester) async {
    await tester.pumpWidget(const AppDiario());

    await _registrar(tester);

    expect(find.text('Selecione o tipo de atividade'), findsOneWidget);
    expect(find.text('Informe a data'), findsOneWidget);
    expect(find.text('Nenhuma atividade registrada ainda.'), findsOneWidget);
  });

  testWidgets('Recusa data futura', (tester) async {
    await tester.pumpWidget(const AppDiario());

    await _escolherAtividade(tester, 'Plantio');
    final amanha = DateTime.now().add(const Duration(days: 1));
    await tester.enterText(find.widgetWithText(TextFormField, 'Data'), _formatar(amanha));
    await _registrar(tester);

    expect(find.text('A data não pode ser futura'), findsOneWidget);
    expect(find.text('Atividades registradas (0)'), findsOneWidget);
  });

  testWidgets('Registra atividade válida e mostra na lista com ícone', (tester) async {
    await tester.pumpWidget(const AppDiario());

    await _escolherAtividade(tester, 'Colheita');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Data'), _formatar(DateTime.now()));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Observações'), 'Soja talhão 3');
    await _registrar(tester);

    expect(find.text('Atividades registradas (1)'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
    expect(
      find.descendant(of: find.byType(ListTile), matching: find.byIcon(Icons.agriculture)),
      findsOneWidget,
    );
  });
}
