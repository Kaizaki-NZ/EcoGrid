import 'package:flutter/material.dart';

import '../models/energy_source.dart';
import '../widgets/energy_source_card.dart';
import '../widgets/source_detail_sheet.dart';
import '../widgets/summary_panel.dart';
import '../widgets/village_map.dart';

/// Halaman utama: seluruh state simulasi berada di sini.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Daftar pembangkit beserta posisi ternormalisasi dan status ON/OFF.
  late List<EnergySource> _sources;

  /// Kebutuhan beban desa dalam kW.
  late double _demandKw;

  /// Id pembangkit yang sedang diseret, null bila tidak ada.
  String? _draggingId;

  @override
  void initState() {
    super.initState();
    _sources = initialEnergySources();
    _demandKw = kInitialDemandKw;
  }

  // ---------------------------------------------------------------- aksi ---

  /// Toggle ON/OFF pembangkit (gesture Tap pada kartu).
  void _toggleSource(String id) {
    setState(() {
      _sources = [
        for (final s in _sources)
          s.id == id ? s.copyWith(isActive: !s.isActive) : s,
      ];
    });
  }

  /// Memindahkan pembangkit ke tengah zona idealnya (tombol bantuan).
  void _moveToIdeal(String id) {
    setState(() {
      _sources = [
        for (final s in _sources)
          s.id == id ? s.copyWith(position: s.idealZone.center) : s,
      ];
    });
  }

  /// Reset seluruh simulasi ke kondisi awal.
  void _reset() {
    setState(() {
      _sources = initialEnergySources();
      _demandKw = kInitialDemandKw;
      _draggingId = null;
    });
  }

  // ------------------------------------------------------------- gesture ---

  void _onDragStart(String id) {
    setState(() => _draggingId = id);
  }

  void _onDragUpdate(String id, Offset delta) {
    final layar = _ukuranPeta;
    if (layar == null || layar.width == 0 || layar.height == 0) return;

    // Delta piksel diubah ke koordinat ternormalisasi.
    final Offset deltaNormal = Offset(
      delta.dx / layar.width,
      delta.dy / layar.height,
    );

    setState(() {
      _sources = [
        for (final s in _sources)
          s.id == id
              ? s.copyWith(position: _kunciPosisi(s.position + deltaNormal))
              : s,
      ];
    });
  }

  void _onDragEnd(String id) {
    if (_draggingId == id) setState(() => _draggingId = null);
  }

  void _onDragCancel(String id) {
    if (_draggingId == id) setState(() => _draggingId = null);
  }

  /// Mengunci posisi node agar tidak keluar dari batas peta.
  ///
  /// Ruang atas 27 dp setengah node, ruang bawah 57 dp (node + label).
  Offset _kunciPosisi(Offset posisi) {
    final layar = _ukuranPeta;
    if (layar == null || layar.width == 0 || layar.height == 0) {
      return Offset(posisi.dx.clamp(0.0, 1.0), posisi.dy.clamp(0.0, 1.0));
    }
    final lebar = layar.width;
    final tinggi = layar.height;
    return Offset(
      posisi.dx.clamp(27 / lebar, 1 - 27 / lebar),
      posisi.dy.clamp(27 / tinggi, 1 - 57 / tinggi),
    );
  }

  /// Ukuran peta dalam piksel, dipantau lewat GlobalKey.
  final GlobalKey _petaKey = GlobalKey();
  Size? get _ukuranPeta {
    final box = _petaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.size;
  }

  // --------------------------------------------------------------- build ---

  @override
  Widget build(BuildContext context) {
    final produksi = totalProduction(_sources);
    final co2 = co2AvoidedKg(produksi);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        title: Row(
          children: [
            const Icon(Icons.bolt, color: Color(0xFF2E7D32)),
            const SizedBox(width: 6),
            Text(
              'EcoGrid Desa',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reset simulasi',
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) => _draggingId != null,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SummaryPanel(
                      productionKw: produksi,
                      demandKw: _demandKw,
                      co2Kg: co2,
                      onDemandChanged: (nilai) =>
                          setState(() => _demandKw = nilai),
                    ),
                    const SizedBox(height: 14),
                    _JudulSeksi(
                      judul: 'Peta Desa',
                      panduan: 'Seret pembangkit ke zona yang cocok untuknya',
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: VillageMap(
                            // GlobalKey agar ukuran peta bisa dibaca untuk
                            // mengonversi delta drag piksel ke ternormalisasi.
                            key: _petaKey,
                            sources: _sources,
                            draggingId: _draggingId,
                            onDragStart: _onDragStart,
                            onDragUpdate: _onDragUpdate,
                            onDragEnd: _onDragEnd,
                            onDragCancel: _onDragCancel,
                          ),
                        ),
                      ),
                    ),
                    const MapLegend(),
                    const SizedBox(height: 14),
                    _JudulSeksi(
                      judul: 'Pembangkit',
                      panduan: 'Ketuk: ON/OFF  -  Tahan lama: detail',
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sources.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.55,
                          ),
                      itemBuilder: (context, index) {
                        final sumber = _sources[index];
                        return EnergySourceCard(
                          source: sumber,
                          onTap: () => _toggleSource(sumber.id),
                          onLongPress: () => showSourceDetailSheet(
                            context,
                            source: sumber,
                            onMoveToIdeal: () => _moveToIdeal(sumber.id),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Judul seksi dengan teks panduan singkat di bawahnya.
class _JudulSeksi extends StatelessWidget {
  const _JudulSeksi({required this.judul, required this.panduan});

  final String judul;
  final String panduan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          judul,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          panduan,
          style: TextStyle(fontSize: 12, color: Colors.black.withAlpha(140)),
        ),
      ],
    );
  }
}
