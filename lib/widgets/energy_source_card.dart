import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/energy_source.dart';

/// Kartu pembangkit pada grid 2 kolom.
///
/// Gesture: Tap untuk ON/OFF dan Long Press untuk membuka detail.
class EnergySourceCard extends StatelessWidget {
  const EnergySourceCard({
    super.key,
    required this.source,
    required this.onTap,
    required this.onLongPress,
  });

  /// Data pembangkit yang ditampilkan.
  final EnergySource source;

  /// Dipanggil saat kartu di-tap (toggle ON/OFF).
  final VoidCallback onTap;

  /// Dipanggil saat kartu ditahan lama (buka detail).
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final aktif = source.isActive;
    final warnaUtama = const Color(0xFF2E7D32);

    return Material(
      color: aktif ? Colors.white : const Color(0xFFF2F2F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: aktif ? warnaUtama : Colors.black.withAlpha(40),
          width: aktif ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        onLongPress: () {
          HapticFeedback.lightImpact();
          onLongPress();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (aktif ? warnaUtama : const Color(0xFF9E9E9E))
                      .withAlpha(aktif ? 35 : 30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  source.icon,
                  size: 22,
                  color: aktif ? warnaUtama : const Color(0xFF757575),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      source.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Angka kW beranimasi scale saat nilai berubah.
                    TweenAnimationBuilder<double>(
                      key: ValueKey<double>(source.outputKw),
                      tween: Tween<double>(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      builder: (context, skala, _) {
                        return Transform.scale(
                          alignment: Alignment.centerLeft,
                          scale: skala,
                          child: Text(
                            '${formatKw(source.outputKw)} kW',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: aktif
                                  ? warnaUtama
                                  : const Color(0xFF757575),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Efisiensi ${(source.efficiency * 100).toStringAsFixed(0)}%'
                      ' · ${source.idealZone.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withAlpha(130),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: aktif
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF9E9E9E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      aktif ? 'ON' : 'OFF',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.radio_button_unchecked,
                    size: 14,
                    color: source.isInIdealZone
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
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
