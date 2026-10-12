import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/energy_source.dart';

/// Panel ringkasan: header gradien, statistik, bar pasokan vs beban,
/// dan slider kebutuhan beban.
class SummaryPanel extends StatelessWidget {
  const SummaryPanel({
    super.key,
    required this.productionKw,
    required this.demandKw,
    required this.co2Kg,
    required this.onDemandChanged,
  });

  /// Total produksi saat ini dalam kW.
  final double productionKw;

  /// Kebutuhan beban desa dalam kW.
  final double demandKw;

  /// Estimasi CO2 yang dihindari dalam kg/jam.
  final double co2Kg;

  /// Dipanggil saat pengguna menggeser slider beban.
  final ValueChanged<double> onDemandChanged;

  @override
  Widget build(BuildContext context) {
    final ratio = supplyRatio(productionKw, demandKw);

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HeaderGradien(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: Row(
              children: [
                Expanded(
                  child: _StatistikAngka(
                    label: 'Produksi',
                    nilai: productionKw,
                    satuan: 'kW',
                    warna: const Color(0xFF2E7D32),
                  ),
                ),
                Expanded(
                  child: _StatistikAngka(
                    label: 'Kebutuhan',
                    nilai: demandKw,
                    satuan: 'kW',
                    warna: const Color(0xFF1565C0),
                  ),
                ),
                Expanded(
                  child: _StatistikAngka(
                    label: 'CO₂ dihindari',
                    nilai: co2Kg,
                    satuan: 'kg/jam',
                    warna: const Color(0xFF6D4C41),
                    desimal: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _BarPasokanBeban(ratio: ratio),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: _DemandSlider(value: demandKw, onChanged: onDemandChanged),
          ),
        ],
      ),
    );
  }
}

/// Header panel bergradien hijau dengan badge SDG 7.
class _HeaderGradien extends StatelessWidget {
  const _HeaderGradien();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: Stack(
        children: [
          Container(
            height: 64,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.energy_savings_leaf_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Keseimbangan Energi Desa',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCC30B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'SDG 7',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF4E342E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu angka statistik dengan transisi nilai selama 400 ms.
class _StatistikAngka extends StatelessWidget {
  const _StatistikAngka({
    required this.label,
    required this.nilai,
    required this.satuan,
    required this.warna,
    this.desimal = false,
  });

  final String label;
  final double nilai;
  final String satuan;
  final Color warna;
  final bool desimal;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: nilai, end: nilai),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, nilaiAnim, _) {
        final teks = desimal
            ? nilaiAnim.toStringAsFixed(1)
            : formatKw(nilaiAnim);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Colors.black.withAlpha(140)),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$teks $satuan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: warna,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Bar perbandingan pasokan dan beban beserta persentase dan pesan status.
class _BarPasokanBeban extends StatelessWidget {
  const _BarPasokanBeban({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final status = SupplyStatus.fromRatio(ratio);
    final persen = (ratio * 100).clamp(0, 999).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(status.icon, size: 16, color: status.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Pasokan $persen%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: status.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: ratio.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (context, nilai, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: nilai.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: status.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status.message,
            style: TextStyle(fontSize: 12, color: Colors.black.withAlpha(150)),
          ),
        ],
      ),
    );
  }
}

/// Slider kebutuhan beban kustom berbasis gesture tap dan drag horizontal.
class _DemandSlider extends StatelessWidget {
  const _DemandSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  static const double _lebarThumb = 30;
  static const double _tinggiArea = 44;

  double _nilaiDariDx(double dx, double lebar) {
    final lintasan = lebar - _lebarThumb;
    if (lintasan <= 0) return value;
    final t = ((dx - _lebarThumb / 2) / lintasan).clamp(0.0, 1.0);
    final hasil = kMinDemandKw + t * (kMaxDemandKw - kMinDemandKw);
    return hasil.roundToDouble().clamp(kMinDemandKw, kMaxDemandKw);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, kotak) {
        final lebar = kotak.maxWidth;
        final lintasan = lebar - _lebarThumb;
        final t = (value - kMinDemandKw) / (kMaxDemandKw - kMinDemandKw);
        final thumbX = t * lintasan;

        void perbarui(double dx) {
          final baru = _nilaiDariDx(dx, lebar);
          if (baru != value) {
            HapticFeedback.selectionClick();
            onChanged(baru);
          }
        }

        return Semantics(
          slider: true,
          label: 'Kebutuhan beban desa',
          value: '${value.toStringAsFixed(0)} kW',
          child: GestureDetector(
            key: const ValueKey<String>('slider-beban'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => perbarui(details.localPosition.dx),
            onPanStart: (details) => perbarui(details.localPosition.dx),
            onPanUpdate: (details) => perbarui(details.localPosition.dx),
            child: SizedBox(
              height: _tinggiArea,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: _lebarThumb / 2,
                    right: _lebarThumb / 2,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: _lebarThumb / 2,
                    width: thumbX.clamp(0.0, lintasan),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: thumbX,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: _lebarThumb,
                      height: _lebarThumb,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(40),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
