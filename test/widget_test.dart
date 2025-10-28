import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torotoro_app/auth/login_page.dart';

void main() {
  testWidgets('Login muestra texto de bienvenida y botón de entrar', (tester) async {
    // Probamos una pantalla pura que no necesita inicializar Firebase.
    await tester.pumpWidget(
      const MaterialApp(home: LoginPage()),
    );

    expect(find.text('Bienvenido a Toro Toro'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
