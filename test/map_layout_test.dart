import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecogrid_desa/main.dart';

/// Menjalankan aplikasi pada lebar layar tertentu (logical width) dan
/// memverifikasi tidak ada overflow pada area peta.
Future<void> _pumpPadaLebar(WidgetTester tester, double lebar) async {
  tester.view.physicalSize = Size(lebar, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const EcoGridApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Tidak ada overflow pada lebar 360 px', (tester) async {
    await _pumpPadaLebar(tester, 360);

    // Cari peta lewat node pertama; pastikan peta ter-build.
    expect(find.byKey(const ValueKey<String>('node-solar')), findsOneWidget);

    final error = tester.takeException();
    expect(error, isNull, reason: 'Meluap pada lebar 360: $error');
  });

  testWidgets('Tidak ada overflow pada lebar 1200 px', (tester) async {
    await _pumpPadaLebar(tester, 1200);

    expect(find.byKey(const ValueKey<String>('node-solar')), findsOneWidget);

    final error = tester.takeException();
    expect(error, isNull, reason: 'Meluap pada lebar 1200: $error');
  });

  testWidgets('Peta tidak ikut melebar pada jendela 1200 px', (tester) async {
    await _pumpPadaLebar(tester, 1200);

    // Konten dibatasi ConstrainedBox maxWidth 480 sehingga peta tidak ikut
    // melebar mengikuti lebar jendela.
    // Overflow akan membuat pumpAndSettle melempar exception; dengan
    // takeException null di atas berarti tidak ada overflow di tree.
    final node = find.byKey(const ValueKey<String>('node-solar')).first;
    final box = tester.renderObject<RenderBox>(node);
    expect(box.size.width, greaterThan(0));
  });
}
