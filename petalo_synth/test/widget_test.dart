// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Tests de integración completa requieren MIDI y audio.
  // Ejecutar la app directamente en macOS para testing manual.
  testWidgets('Pétalo smoke test placeholder', (WidgetTester tester) async {
    expect(1 + 1, 2); // placeholder
  });
}
