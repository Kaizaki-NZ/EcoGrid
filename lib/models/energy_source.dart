import 'package:flutter/material.dart';

/// Model data pembangkit, zona peta, data awal, dan aturan efisiensi.
///
/// Seluruh logika bisnis (zona, efisiensi, keluaran) berada di file ini
/// agar mudah diuji tanpa bergantung pada UI.

/// Zona pada peta desa. Koordinat disimpan ternormalisasi 0..1.
enum VillageZone {
  openLand(
    'Lahan Terbuka',
    Rect.fromLTWH(0, 0, 0.5, 0.5),
    Color(0xFF9A5B25),
    Icons.landscape_outlined,
  ),
  windyHill(
    'Bukit Berangin',
    Rect.fromLTWH(0.5, 0, 0.5, 0.5),
    Color(0xFF3949AB),
    Icons.air_outlined,
  ),
  river(
    'Sungai',
    Rect.fromLTWH(0, 0.5, 1, 0.5),
    Color(0xFF1565C0),
    Icons.water_outlined,
  );

  const VillageZone(this.label, this.rect, this.color, this.icon);

  /// Nama zona yang ditampilkan pada peta.
  final String label;

  /// Batas zona dalam koordinat ternormalisasi (left, top, right, bottom).
  final Rect rect;

  /// Warna dasar zona.
  final Color color;

  /// Ikon zona.
  final IconData icon;

  /// Apakah posisi ternormalisasi berada di dalam zona ini.
  ///
  /// Batas sisi dihitung inklusif agar node yang menempel tepat di garis
  /// batas tetap dianggap berada di dalam zona.
  bool contains(Offset position) {
    return position.dx >= rect.left &&
        position.dx <= rect.right &&
        position.dy >= rect.top &&
        position.dy <= rect.bottom;
  }

  /// Posisi tengah zona, dipakai oleh tombol "Ke zona ideal".
  Offset get center => rect.center;
}

/// Status pasokan listrik desa terhadap beban.
enum SupplyStatus {
  sufficient(
    'Beban terpenuhi 100% energi terbarukan',
    Color(0xFF2E7D32),
    Icons.check_circle_outline,
  ),
  near(
    'Hampir cukup, pindahkan pembangkit ke zona ideal',
    Color(0xFFEF6C00),
    Icons.warning_amber_outlined,
  ),
  deficit(
    'Defisit, aktifkan atau relokasi pembangkit',
    Color(0xFFC62828),
    Icons.error_outline,
  );

  const SupplyStatus(this.message, this.color, this.icon);

  /// Pesan singkat yang mendeskripsikan status.
  final String message;

  /// Warna status.
  final Color color;

  /// Ikon status agar tidak bergantung pada warna saja.
  final IconData icon;

  /// Menentukan status dari rasio pasokan (produksi / beban).
  static SupplyStatus fromRatio(double ratio) {
    if (ratio >= 1.0) return SupplyStatus.sufficient;
    if (ratio >= 0.7) return SupplyStatus.near;
    return SupplyStatus.deficit;
  }
}

/// Data satu pembangkit listrik.
class EnergySource {
  const EnergySource({
    required this.id,
    required this.name,
    required this.capacityKw,
    required this.idealZone,
    required this.position,
    required this.sdgTag,
    required this.description,
    required this.sdgNote,
    this.isActive = true,
  });

  /// Pengenal unik pembangkit.
  final String id;

  /// Nama pembangkit.
  final String name;

  /// Kapasitas puncak dalam kW.
  final double capacityKw;

  /// Zona tempat pembangkit bekerja penuh.
  final VillageZone idealZone;

  /// Posisi node pada peta, ternormalisasi 0..1.
  final Offset position;

  /// Target SDG yang relevan, misalnya "SDG 7.2".
  final String sdgTag;

  /// Penjelasan singkat cara kerja pembangkit.
  final String description;

  /// Catatan SDG yang tampil pada pop-up detail.
  final String sdgNote;

  /// Status aktif atau nonaktif.
  final bool isActive;

  /// Ikon pembangkit.
  IconData get icon {
    switch (id) {
      case 'solar':
        return Icons.solar_power_outlined;
      case 'wind':
        return Icons.wind_power_outlined;
      case 'hydro':
        return Icons.water_drop_outlined;
      case 'biogas':
        return Icons.bakery_dining_outlined;
      default:
        return Icons.bolt_outlined;
    }
  }

  /// Warna identitas pembangkit, dipakai untuk membedakan node di peta
  /// dan kartu pembangkit.
  Color get color {
    switch (id) {
      case 'solar':
        return const Color(0xFFF9A825); // kuning-emas surya
      case 'wind':
        return const Color(0xFF3949AB); // indigo angin
      case 'hydro':
        return const Color(0xFF0277BD); // biru air
      case 'biogas':
        return const Color(0xFF2E7D32); // hijau biogas
      default:
        return const Color(0xFF546E7A);
    }
  }

  /// Nama singkat untuk label node pada peta.
  String get shortName {
    switch (id) {
      case 'solar':
        return 'Surya';
      case 'wind':
        return 'Angin';
      case 'hydro':
        return 'Mikrohidro';
      case 'biogas':
        return 'Biogas';
      default:
        return name;
    }
  }

  /// Salinan dengan sebagian field diganti.
  EnergySource copyWith({Offset? position, bool? isActive}) {
    return EnergySource(
      id: id,
      name: name,
      capacityKw: capacityKw,
      idealZone: idealZone,
      position: position ?? this.position,
      sdgTag: sdgTag,
      description: description,
      sdgNote: sdgNote,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Apakah posisi saat ini berada di zona ideal.
  bool get isInIdealZone => idealZone.contains(position);

  /// Efisiensi: 100% di zona ideal, 50% di luar zona ideal.
  double get efficiency => isInIdealZone ? 1.0 : 0.5;

  /// Keluaran nyata dalam kW (0 bila nonaktif).
  double get outputKw => isActive ? capacityKw * efficiency : 0;
}

/// Kapasitas total bila semua pembangkit berada di zona ideal.
const double kMaxCapacityKw = 140;

/// Beban awal desa dalam kW.
const double kInitialDemandKw = 90;

/// Batas bawah dan atas slider beban dalam kW.
const double kMinDemandKw = 20;
const double kMaxDemandKw = 150;

/// Faktor emisi kasar untuk estimasi CO2 (kg CO2 per kWh).
const double kCo2EmissionFactor = 0.85;

/// Jarak aman minimum (dalam satuan ternormalisasi) dari garis batas zona
/// maupun dari pojok label zona, agar node awal tidak menempel di batas
/// dan tidak menutupi label.
const double kSafeMargin = 0.08;

/// Daftar pembangkit awal, sengaja diletakkan di luar zona ideal
/// agar pengguna perlu bertindak sebelum beban terpenuhi.
List<EnergySource> initialEnergySources() {
  return const [
    EnergySource(
      id: 'solar',
      name: 'PLTS Atap Surya',
      capacityKw: 40,
      idealZone: VillageZone.openLand,
      // Di zona Bukit (bukan ideal). Sengaja di sisi kanan-atas zona,
      // jauh dari label "Bukit Berangin" di kiri-atas.
      position: Offset(0.86, 0.13),
      sdgTag: 'SDG 7.2',
      description:
          'Panel surya di atap rumah mengubah cahaya matahari '
          'menjadi listrik siang hari.',
      sdgNote:
          'Mendukung SDG 7.2: meningkatkan porsi energi terbarukan '
          'dalam bauran energi desa.',
    ),
    EnergySource(
      id: 'wind',
      name: 'PLTB Mini Angin',
      capacityKw: 30,
      idealZone: VillageZone.windyHill,
      // Di zona Lahan Terbuka (bukan ideal). Jauh dari garis batas
      // horizontal di y = 0,5 dan dari label zona di kiri-atas.
      position: Offset(0.22, 0.34),
      sdgTag: 'SDG 13',
      description:
          'Turbin kecil memanfaatkan angin di punggung bukit '
          'untuk memutar generator.',
      sdgNote:
          'Mendukung SDG 13: energi angin menghindari emisi gas '
          'rumah kaca dari pembakaran bahan bakar fosil.',
    ),
    EnergySource(
      id: 'hydro',
      name: 'Mikrohidro',
      capacityKw: 50,
      idealZone: VillageZone.river,
      // Di zona Bukit (bukan ideal). Jauh dari garis batas vertikal
      // di x = 0,5 maupun horizontal di y = 0,5 agar zonanya tidak ambigu.
      position: Offset(0.78, 0.32),
      sdgTag: 'SDG 7.1',
      description:
          'Aliran sungai yang deras memutar turbin air '
          'untuk memproduksi listrik terus-menerus.',
      sdgNote:
          'Mendukung SDG 7.1: memperluas akses listrik yang andal '
          'bagi desa yang jauh dari jaringan utama.',
    ),
    EnergySource(
      id: 'biogas',
      name: 'Biogas Ternak',
      capacityKw: 20,
      idealZone: VillageZone.openLand,
      // Di zona Sungai (bukan ideal). Di sisi kanan, jauh dari label
      // "Sungai" di kiri-atas zona.
      position: Offset(0.84, 0.68),
      sdgTag: 'SDG 12',
      description:
          'Limbah ternak difermentasi menjadi gas yang '
          'menggerakkan genset biogas.',
      sdgNote:
          'Mendukung SDG 12: limbah organik diubah menjadi energi, '
          'contoh ekonomi sirkular di desa.',
    ),
  ];
}

/// Jumlah keluaran semua pembangkit dalam kW.
double totalProduction(List<EnergySource> sources) {
  return sources.fold(0.0, (sum, source) => sum + source.outputKw);
}

/// Rasio pasokan terhadap beban.
double supplyRatio(double productionKw, double demandKw) {
  if (demandKw <= 0) return 0;
  return productionKw / demandKw;
}

/// Estimasi CO2 yang dihindari dalam kg/jam.
double co2AvoidedKg(double productionKw) {
  return productionKw * kCo2EmissionFactor;
}

/// Format angka kW: tanpa desimal bila bilangan bulat.
String formatKw(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}
