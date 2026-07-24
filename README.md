# Catat-In: Financial Tracker

Aplasi keuangan pribadi berbasis Flutter dengan desain Neo-Brutal yang clean dan profesional.

## 📱 Tentang

**Catat-In** adalah aplikasi pencatatan dan pengelolaan keuangan pribadi yang dirancang untuk pengguna Indonesia. Data tersimpan lokal di perangkat — tanpa akun, tanpa cloud, tanpa ribet.

Bagian dari ekosistem **Catat-In**, melengkapi aplikasi time-tracking/productivity yang sudah ada.

## ✨ Fitur

### Pencatatan Transaksi
- Catat pemasukan & pengeluaran dalam ≤3 tap
- Multi-akun (Tunai, Bank, E-wallet)
- Kategori custom
- Filter & pencarian

### Budgeting
- Budget per kategori per bulan
- Progress bar real-time
- Alert saat mendekati/melebihi limit
- Auto-copy budget ke bulan berikutnya

### Laporan & Analitik
- Tren pemasukan vs pengeluaran
- Breakdown per kategori
- Grafik interaktif (fl_chart)

### Recurring Transactions
- Transaksi berulang otomatis
- Frekuensi: harian, mingguan, bulanan, tahunan

### Savings Goals
- Target tabungan
- Progress tracking
- Kontribusi manual

### AI Insight
- Ringkasan keuangan otomatis via Claude API

## 🛠 Tech Stack

| Komponen | Teknologi |
|----------|-----------|
| Framework | Flutter |
| State Management | Riverpod |
| Database | SQLite (sqflite) |
| Charts | fl_chart |
| Fonts | Google Fonts (Space Grotesk) |
| AI | Anthropic Claude API |

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥3.10.7
- Dart SDK

### Installation

```bash
# Clone repository
git clone https://github.com/Lputaa/catat-in2.git
cd catat-in2

# Install dependencies
flutter pub get

# Run app
flutter run
```

## 📁 Struktur Project

```
lib/
├── app.dart                    # App entry point
├── main.dart                   # Main bootstrap
├── core/
│   ├── constants/              # App constants
│   └── theme/                  # Colors & theme
├── data/
│   ├── models/                 # Data models
│   ├── notifiers/              # Riverpod providers
│   ├── repositories/           # Database repositories
│   └── services/               # AI, export, settings
├── features/
│   ├── budget/                 # Budget screens
│   ├── dashboard/              # Dashboard
│   ├── recurring/              # Recurring transactions
│   ├── reports/                # Reports & analytics
│   ├── savings/                # Savings goals
│   ├── settings/               # Settings & management
│   └── transactions/           # Transaction screens
└── shared/
    └── widgets/                # Reusable widgets
```

## 🎨 Desain

Menggunakan **Neo-Brutal Design** dengan:
- Warna bold & kontras tinggi
- Border tebal
- Shadow tegas
- Typography Space Grotesk

Style guide lengkap: `catat-in-style-guide.md`

## 📄 License

Private project - tidak untuk didistribusikan.

## 🔗 Links

- [GitHub Repository](https://github.com/Lputaa/catat-in2)

---

Made with ❤️ using Flutter
