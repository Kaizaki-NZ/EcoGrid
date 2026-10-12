import 'package:flutter_test/flutter_test.dart';

import 'package:ecogrid_desa/models/energy_source.dart';

void main() {
  group('Aturan efisiensi dan keluaran', () {
    test('efisiensi 100% ketika berada di zona ideal', () {
      final solar = initialEnergySources()
          .firstWhere((s) => s.id == 'solar')
          .copyWith(position: const Offset(0.25, 0.25));
      expect(solar.isInIdealZone, isTrue);
      expect(solar.efficiency, 1.0);
    });

    test('efisiensi 50% ketika di luar zona ideal', () {
      final solar = initialEnergySources().firstWhere((s) => s.id == 'solar');
      expect(solar.isInIdealZone, isFalse);
      expect(solar.efficiency, 0.5);
    });

    test('keluaran 0 kW ketika nonaktif', () {
      final solar = initialEnergySources()
          .firstWhere((s) => s.id == 'solar')
          .copyWith(position: const Offset(0.25, 0.25), isActive: false);
      expect(solar.outputKw, 0);
    });

    test('keluaran aktif = kapasitas x efisiensi', () {
      final hydro = initialEnergySources()
          .firstWhere((s) => s.id == 'hydro')
          .copyWith(position: const Offset(0.5, 0.75));
      expect(hydro.outputKw, 50);
    });
  });

  group('Kondisi awal simulasi', () {
    test('produksi awal bernilai 70 kW', () {
      expect(totalProduction(initialEnergySources()), 70);
    });

    test('rasio awal sekitar 78% (oranye)', () {
      final rasio = supplyRatio(70, kInitialDemandKw);
      expect((rasio * 100).round(), 78);
      expect(SupplyStatus.fromRatio(rasio), SupplyStatus.near);
    });

    test('kapasitas maksimum bila semua di zona ideal adalah 140 kW', () {
      final semuaIdeal = [
        for (final s in initialEnergySources())
          s.copyWith(position: s.idealZone.center),
      ];
      expect(totalProduction(semuaIdeal), kMaxCapacityKw);
    });
  });

  group('Status pasokan', () {
    test('rasio >= 100% berstatus hijau', () {
      expect(SupplyStatus.fromRatio(1.0), SupplyStatus.sufficient);
      expect(SupplyStatus.fromRatio(1.4), SupplyStatus.sufficient);
    });

    test('rasio 70% sampai < 100% berstatus oranye', () {
      expect(SupplyStatus.fromRatio(0.7), SupplyStatus.near);
      expect(SupplyStatus.fromRatio(0.99), SupplyStatus.near);
    });

    test('rasio < 70% berstatus merah', () {
      expect(SupplyStatus.fromRatio(0.69), SupplyStatus.deficit);
    });
  });

  group('Estimasi CO2', () {
    test('CO2 dihindari = produksi x 0,85', () {
      expect(co2AvoidedKg(70), closeTo(59.5, 0.0001));
    });
  });

  group('Batas slider beban', () {
    test('rentang beban 20 sampai 150 kW', () {
      expect(kMinDemandKw, 20);
      expect(kMaxDemandKw, 150);
    });
  });
}
