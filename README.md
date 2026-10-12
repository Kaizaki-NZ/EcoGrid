# EcoGrid Desa

Aplikasi mobile simulasi microgrid energi terbarukan untuk desa, dibangun dengan **Flutter** sebagai respons terhadap **SDG 7: Energi Bersih dan Terjangkau**.

Pengguna berperan sebagai perencana energi: menyalakan atau mematikan pembangkit, menempatkannya di zona yang tepat pada peta desa, lalu menyeimbangkan pasokan listrik dengan kebutuhan beban.

## Fitur

- **Dashboard ringkasan** — Produksi (kW), Kebutuhan (kW), dan estimasi CO₂ dihindari (kg/jam) dengan angka beranimasi.
- **Bar Pasokan vs Beban** — persentase dan tiga status warna (hijau ≥ 100%, oranye 70–99%, merah < 70%).
- **Peta desa interaktif** — tiga zona (Lahan Terbuka, Bukit Berangin, Sungai) dengan node pembangkit yang dapat diseret.
- **Empat pembangkit** — PLTS Atap Surya, PLTB Mini Angin, Mikrohidro, dan Biogas Ternak.
- **Detail pembangkit** — pop-up berisi deskripsi, catatan SDG, status zona, dan tombol "Ke zona ideal".
- **Slider beban kustom** — rentang 20–150 kW, dapat di-tap dan di-drag.

## Gesture

| Gesture | Widget | Area | Aksi |
| --- | --- | --- | --- |
| Tap | InkWell | Kartu pembangkit | Toggle ON/OFF |
| Long Press | InkWell | Kartu pembangkit | Buka bottom sheet detail |
| Pan (drag bebas) | GestureDetector | Node pembangkit di peta | Pindahkan posisi |
| Drag horizontal | GestureDetector | Slider beban | Ubah kebutuhan beban |

Seluruh gesture disertai umpan balik visual langsung, dan tap/long press memberi haptic feedback.

## Menjalankan aplikasi

```bash
flutter pub get
flutter run
```

## Menjalankan pengujian

```bash
flutter analyze   # 0 error, 0 warning
flutter test      # unit test model + widget test
```

## Struktur proyek

```
lib/
├── main.dart                          # entry point dan tema
├── models/energy_source.dart          # model, zona, data awal, aturan efisiensi
├── pages/home_page.dart               # state utama dan penyusunan halaman
└── widgets/
    ├── summary_panel.dart             # dashboard, bar status, DemandSlider
    ├── village_map.dart               # peta (Stack) dan node draggable
    ├── energy_source_card.dart        # kartu pembangkit (Tap, Long Press)
    └── source_detail_sheet.dart       # pop-up detail
```

## Aturan bisnis

- Efisiensi pembangkit = **100%** di zona ideal, **50%** di luar zona ideal.
- Keluaran pembangkit = kapasitas × efisiensi jika aktif, 0 jika nonaktif.
- Rasio pasokan = produksi total ÷ kebutuhan beban.
- CO₂ dihindari = produksi total × **0,85** kg/kWh (**estimasi kasar**, bukan data resmi).

Kondisi awal sengaja ditempatkan di luar zona ideal: produksi 70 kW terhadap beban 90 kW (status oranye, ± 78%). Kapasitas maksimum bila semua pembangkit berada di zona ideal adalah **140 kW**, sehingga beban 150 kW tidak dapat terpenuhi sepenuhnya — ini disengaja sebagai tantangan.

## Relevansi SDGs

- **SDG 7** — inti aplikasi: simulasi bauran energi terbarukan untuk desa (target 7.1 dan 7.2).
- **SDG 13** — indikator CO₂ dihindari mengaitkan pilihan pembangkit dengan pengurangan emisi.
- **SDG 12** — biogas dari limbah ternak mencontohkan ekonomi sirkular.

## Teknologi

Flutter (Dart) · Material 3 · tanpa package eksternal · state management `setState` pada ` StatefulWidget`.
