import 'package:flutter/material.dart';

import '../models/energy_source.dart';

/// Peta desa: satu kesatuan peta berisi tiga zona dan node pembangkit
/// yang dapat diseret bebas (gesture Pan).
///
/// Tata letak memakai [AspectRatio] 4:3 sehingga rasio peta tetap konstan
/// di segala lebar layar. Zona digambar saling menempel tanpa celah dan
/// dipisah garis tipis, dengan sudut luar membulat.
class VillageMap extends StatelessWidget {
  const VillageMap({
    super.key,
    required this.sources,
    required this.draggingId,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  /// Daftar pembangkit beserta posisi ternormalisasi.
  final List<EnergySource> sources;

  /// Id pembangkit yang sedang diseret, null bila tidak ada.
  final String? draggingId;

  /// Dipanggil saat pengguna mulai menekan node.
  final ValueChanged<String> onDragStart;

  /// Dipanggil saat node bergeser, delta dalam piksel layar peta.
  final void Function(String id, Offset delta) onDragUpdate;

  /// Dipanggil saat gesture pan selesai.
  final ValueChanged<String> onDragEnd;

  /// Dipanggil saat gesture pan dibatalkan.
  final ValueChanged<String> onDragCancel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, kotak) {
        final ukuran = Size(kotak.maxWidth, kotak.maxHeight);

        // Zona ideal milik node yang sedang diseret ikut menyala.
        final String? idZonaMenyala = draggingId;
        final VillageZone? zonaIdealMenyala = _sumberDenganId(idZonaMenyala)
            ?.idealZone;

        // Node yang sedang diseret digambar paling atas.
        final terurut = [...sources];
        if (draggingId != null) {
          final indeks = terurut.indexWhere((s) => s.id == draggingId);
          if (indeks != -1) {
            terurut.add(terurut.removeAt(indeks));
          }
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: ukuran.width,
            height: ukuran.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Latar dasar putih menutup celah antar zona.
                Positioned.fill(
                  child: Container(color: const Color(0xFFFFFFFF)),
                ),
                for (final zona in VillageZone.values)
                  _ZonaPeta(
                    zona: zona,
                    ukuranPeta: ukuran,
                    menyala: zonaIdealMenyala == zona,
                  ),
                for (final sumber in terurut)
                  _NodePembangkit(
                    // ValueKey agar elemen tidak dibuat ulang saat urutan
                    // berubah ketika node diseret ke atas.
                    key: ValueKey<String>('node-${sumber.id}'),
                    sumber: sumber,
                    sedangDiseret: sumber.id == draggingId,
                    ukuranPeta: ukuran,
                    onDragStart: onDragStart,
                    onDragUpdate: onDragUpdate,
                    onDragEnd: onDragEnd,
                    onDragCancel: onDragCancel,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  EnergySource? _sumberDenganId(String? id) {
    if (id == null) return null;
    for (final s in sources) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// Satu zona peta: gradien lembut sesuai warna zona, watermark ikon besar
/// transparan, label di pojok kiri-atas, dan garis tipis pemisah.
///
/// Menyala (lebih pekat + border lebih tebal) saat menjadi zona ideal
/// pembangkit yang sedang diseret.
class _ZonaPeta extends StatelessWidget {
  const _ZonaPeta({
    required this.zona,
    required this.ukuranPeta,
    required this.menyala,
  });

  final VillageZone zona;
  final Size ukuranPeta;
  final bool menyala;

  /// Ikon watermark besar sesuai jenis zona.
  IconData get _ikonWatermark {
    switch (zona) {
      case VillageZone.openLand:
        return Icons.wb_sunny_outlined; // matahari / rumput terbuka
      case VillageZone.windyHill:
        return Icons.terrain_outlined; // perbukitan
      case VillageZone.river:
        return Icons.waves_outlined; // air sungai
    }
  }

  @override
  Widget build(BuildContext context) {
    // Koordinat ternormalisasi dikonversi ke piksel peta.
    final rect = Rect.fromLTWH(
      zona.rect.left * ukuranPeta.width,
      zona.rect.top * ukuranPeta.height,
      zona.rect.width * ukuranPeta.width,
      zona.rect.height * ukuranPeta.height,
    );

    return Positioned.fromRect(
      rect: rect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              zona.color.withAlpha(menyala ? 110 : 55),
              zona.color.withAlpha(menyala ? 78 : 34),
            ],
          ),
          // Garis tipis pemisah antar zona.
          border: Border.all(
            color: zona.color.withAlpha(menyala ? 220 : 130),
            width: menyala ? 2.4 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Watermark ikon besar transparan di tengah zona.
            Positioned.fill(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, 6),
                  child: Icon(
                    _ikonWatermark,
                    size: 92,
                    color: zona.color.withAlpha(menyala ? 60 : 34),
                  ),
                ),
              ),
            ),
            // Label zona di pojok kiri-atas, dibatasi agar tidak meluap
            // pada layar sempit.
            Positioned(
              left: 8,
              top: 8,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (ukuranPeta.width / 2) - 16,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(menyala ? 235 : 205),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: zona.color.withAlpha(120),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(zona.icon, size: 14, color: zona.color),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          zona.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: zona.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Node pembangkit pada peta, dapat diseret bebas dengan gesture Pan.
///
/// Warna isi node = warna identitas pembangkit. Status zona ideal hanya
/// ditandai cincin luar tipis (hijau/merah) plus ikon centang/peringatan
/// di pojok, bukan dengan mewarnai seluruh node.
class _NodePembangkit extends StatelessWidget {
  const _NodePembangkit({
    super.key,
    required this.sumber,
    required this.sedangDiseret,
    required this.ukuranPeta,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  static const double _sentuh = 54;
  static const double _ruangLabel = 20;

  final EnergySource sumber;
  final bool sedangDiseret;
  final Size ukuranPeta;
  final ValueChanged<String> onDragStart;
  final void Function(String id, Offset delta) onDragUpdate;
  final ValueChanged<String> onDragEnd;
  final ValueChanged<String> onDragCancel;

  /// Mengunci posisi node agar tidak keluar dari batas peta,
  /// memperhitungkan ukuran sentuh dan ruang label.
  Offset kunciPosisi(Offset posisi) {
    final minX = _sentuh / 2;
    final maxX = ukuranPeta.width - _sentuh / 2;
    final minY = _sentuh / 2;
    final maxY = ukuranPeta.height - _sentuh / 2 - _ruangLabel;
    return Offset(posisi.dx.clamp(minX, maxX), posisi.dy.clamp(minY, maxY));
  }

  @override
  Widget build(BuildContext context) {
    final pusat = Offset(
      sumber.position.dx * ukuranPeta.width,
      sumber.position.dy * ukuranPeta.height,
    );
    final diZonaIdeal = sumber.isInIdealZone;
    final warnaCincin = diZonaIdeal
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    final warnaIsi = sumber.isActive ? sumber.color : const Color(0xFF9E9E9E);

    return Positioned(
      left: pusat.dx - _sentuh / 2,
      top: pusat.dy - _sentuh / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (_) => onDragStart(sumber.id),
        onPanUpdate: (details) => onDragUpdate(sumber.id, details.delta),
        onPanEnd: (_) => onDragEnd(sumber.id),
        onPanCancel: () => onDragCancel(sumber.id),
        child: Semantics(
          label:
              '${sumber.name}, '
              '${formatKw(sumber.outputKw)} kilowatt, '
              '${diZonaIdeal ? 'zona ideal' : 'bukan zona ideal'}',
          child: AnimatedScale(
            scale: sedangDiseret ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: SizedBox(
              width: _sentuh,
              height: _sentuh + _ruangLabel,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lingkaran isi warna identitas + cincin status tipis.
                      Container(
                        width: _sentuh - 12,
                        height: _sentuh - 12,
                        decoration: BoxDecoration(
                          color: warnaIsi,
                          shape: BoxShape.circle,
                          border: Border.all(color: warnaCincin, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(
                                sedangDiseret ? 95 : 45,
                              ),
                              blurRadius: sedangDiseret ? 12 : 6,
                              offset: Offset(0, sedangDiseret ? 5 : 2),
                            ),
                          ],
                        ),
                        child: Icon(sumber.icon, size: 20, color: Colors.white),
                      ),
                    ],
                  ),
                  // Ikon status cincin: centang / peringatan, pojok kanan-atas.
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: warnaCincin,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(
                        diZonaIdeal ? Icons.check : Icons.priority_high_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Label pill: nama singkat + keluaran.
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${sumber.shortName} · '
                          '${formatKw(sumber.outputKw)} kW · '
                          '${(sumber.efficiency * 100).round()}%',
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Legenda kecil di bawah peta: makna cincin hijau dan merah.
class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  Widget _item(Color warna, String teks) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: warna, width: 2.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          teks,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: TextStyle(
            fontSize: 10.5,
            color: Colors.black.withAlpha(160),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 4,
        children: [
          _item(const Color(0xFF2E7D32), 'Cincin hijau: efisiensi 100%'),
          _item(const Color(0xFFC62828), 'Cincin merah: efisiensi 50%'),
        ],
      ),
    );
  }
}
