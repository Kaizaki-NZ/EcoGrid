import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecogrid_desa/main.dart';

/// Menjalankan aplikasi pada layar 360 x 800 dp.
Future<void> jalankanAplikasi(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const EcoGridApp());
  await tester.pumpAndSettle();
}

/// Mencari kartu pembangkit berdasarkan nama di dalamnya.
Finder kartuPembangkit(String nama) {
  return find.ancestor(of: find.text(nama), matching: find.byType(InkWell));
}

/// Menggulir halaman sampai kartu terlihat lalu menekannya.
Future<void> tekanKartu(
  WidgetTester tester,
  String nama, {
  bool tahanLama = false,
}) async {
  final finder = kartuPembangkit(nama);
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  if (tahanLama) {
    await tester.longPress(finder);
  } else {
    await tester.tap(finder);
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AC-01: aplikasi membuka dengan produksi 70 kW, beban 90 kW', (
    tester,
  ) async {
    await jalankanAplikasi(tester);
    expect(find.text('70 kW'), findsWidgets);
    expect(find.text('90 kW'), findsWidgets);
    expect(find.textContaining('Pasokan 78%'), findsOneWidget);
  });

  testWidgets('AC-02/AC-03: tap kartu PLTS menyalakan dan mematikan', (
    tester,
  ) async {
    await jalankanAplikasi(tester);

    // Awal: PLTS aktif dan menampilkan 20 kW (50% dari 40 kW).
    expect(find.text('20 kW'), findsWidgets);

    // Tap pertama: kartu nonaktif, badge OFF.
    await tekanKartu(tester, 'PLTS Atap Surya');
    expect(find.text('OFF'), findsOneWidget);
    expect(find.text('Pasokan 56%'), findsOneWidget);

    // Tap kedua: kartu aktif kembali, badge OFF hilang.
    await tekanKartu(tester, 'PLTS Atap Surya');
    expect(find.text('OFF'), findsNothing);
    expect(find.text('20 kW'), findsWidgets);
  });

  testWidgets('AC-04: long press membuka bottom sheet detail', (tester) async {
    await jalankanAplikasi(tester);

    await tekanKartu(tester, 'PLTS Atap Surya', tahanLama: true);

    expect(find.text('Kapasitas 40 kW · SDG 7.2'), findsOneWidget);
    expect(find.text('Ke zona ideal'), findsOneWidget);
    expect(find.textContaining('zona ideal'), findsWidgets);

    // Tutup sheet agar tidak ada timer tertinggal.
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
  });

  testWidgets('AC-08: tombol Ke zona ideal memindahkan node', (tester) async {
    await jalankanAplikasi(tester);

    await tekanKartu(tester, 'PLTS Atap Surya', tahanLama: true);
    await tester.tap(find.text('Ke zona ideal'));
    await tester.pumpAndSettle();

    // Setelah pindah ke Lahan Terbuka, keluaran PLTS menjadi 40 kW.
    expect(find.text('40 kW'), findsWidgets);
    // Produksi total ikut naik dari 70 ke 90 kW.
    expect(find.text('90 kW'), findsWidgets);
  });

  testWidgets('AC-11: tombol reset mengembalikan kondisi awal', (tester) async {
    await jalankanAplikasi(tester);

    await tekanKartu(tester, 'PLTS Atap Surya');
    expect(find.text('OFF'), findsOneWidget);

    await tester.tap(find.byTooltip('Reset simulasi'));
    await tester.pumpAndSettle();

    expect(find.text('OFF'), findsNothing);
    expect(find.text('20 kW'), findsWidgets);
    expect(find.text('90 kW'), findsWidgets);
    expect(find.textContaining('Pasokan 78%'), findsOneWidget);
  });

  testWidgets('AC-10: menggeser slider beban ke kanan menaikkan kebutuhan', (
    tester,
  ) async {
    await jalankanAplikasi(tester);

    final slider = find.byKey(const ValueKey<String>('slider-beban'));
    expect(slider, findsOneWidget);

    // Geser ke kanan penuh: beban naik ke batas atas 150 kW.
    await tester.drag(slider, const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.text('150 kW'), findsWidgets);
    expect(find.text('90 kW'), findsNothing);

    // Karena produksi 70 kW terhadap beban 150 kW, pasokan jatuh ke status merah.
    expect(find.textContaining('Pasokan 47%'), findsOneWidget);
  });

  testWidgets('Seret node PLTS ke Lahan Terbuka membuatnya 100% efisien', (
    tester,
  ) async {
    await jalankanAplikasi(tester);

    // Node PLTS awal di (0,86 ; 0,13) di zona Bukit; seret ke kiri-atas
    // ke Lahan Terbuka (x < 0,5) agar efisiensinya menjadi 100%.
    final node = find.byKey(const ValueKey<String>('node-solar'));
    await tester.ensureVisible(node);
    await tester.pumpAndSettle();

    // Seret bertahap agar gesture pan terakui oleh arena gesture.
    final kotak = tester.renderObject<RenderBox>(node);
    final pusat = kotak.localToGlobal(kotak.size.center(Offset.zero));
    final gesture = await tester.startGesture(pusat);
    await tester.pump(const Duration(milliseconds: 30));
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(-70, -4));
      await tester.pump(const Duration(milliseconds: 30));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Surya · 40 kW · 100%'), findsOneWidget);
  });
}
