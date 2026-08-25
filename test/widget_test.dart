// Prueba de humo: verifica que la app arranca y muestra el selector de rol.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:chambapp/main.dart';
import 'package:chambapp/providers/app_provider.dart';

void main() {
  testWidgets('Chambapp arranca y muestra el selector de rol', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const ChambappApp(),
      ),
    );

    expect(find.text('Chambapp'), findsOneWidget);
    expect(find.text('¿Qué necesitas hoy?'), findsOneWidget);
  });
}
