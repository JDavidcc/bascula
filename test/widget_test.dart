import 'package:bascula/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza la pantalla principal de la bascula', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Bascula BLE'), findsOneWidget);
    expect(find.text('Paquete BLE (HEX)'), findsOneWidget);
    expect(find.text('Bytes individuales'), findsOneWidget);
  });
}
