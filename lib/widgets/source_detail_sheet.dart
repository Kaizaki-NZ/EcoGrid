import 'package:flutter/material.dart';

import '../models/energy_source.dart';

/// Menampilkan bottom sheet detail pembangkit.
Future<void> showSourceDetailSheet(
  BuildContext context, {
  required EnergySource source,
  required VoidCallback onMoveToIdeal,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) =>
        SourceDetailSheet(source: source, onMoveToIdeal: onMoveToIdeal),
  );
}

/// Isi bottom sheet: deskripsi, catatan SDG, status zona, dan dua tombol.
class SourceDetailSheet extends StatelessWidget {
  const SourceDetailSheet({
    super.key,
    required this.source,
    required this.onMoveToIdeal,
  });

  final EnergySource source;
  final VoidCallback onMoveToIdeal;

  @override
  Widget build(BuildContext context) {
    final diZonaIdeal = source.isInIdealZone;
    final warnaZona = diZonaIdeal
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);

    return SafeArea(
      child: ConstrainedBox(
        // Konten dapat digulir agar tidak meluap pada layar kecil.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(40),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withAlpha(35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(source.icon, color: const Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          source.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Kapasitas ${formatKw(source.capacityKw)} kW · '
                          '${source.sdgTag}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                source.description,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.public,
                      size: 18,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        source.sdgNote,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warnaZona.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: warnaZona.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    Icon(
                      diZonaIdeal
                          ? Icons.check_circle_outline
                          : Icons.location_off_outlined,
                      size: 18,
                      color: warnaZona,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        diZonaIdeal
                            ? 'Berada di zona ideal ${source.idealZone.label}, '
                                  'efisiensi 100%.'
                            : 'Di luar zona ideal. Seharusnya berada di '
                                  '${source.idealZone.label} agar efisiensi 100%.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: warnaZona,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onMoveToIdeal();
                      },
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('Ke zona ideal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.black.withAlpha(60)),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Tutup'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
