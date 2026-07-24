# Product Requirements Document
## Catat-In: Financial Tracker

**Versi Dokumen:** 1.0
**Tanggal:** 22 Juli 2026
**Platform:** Mobile (Flutter — Android/iOS)
**Status:** Draft

---

## 1. Ringkasan Produk

### 1.1 Latar Belakang
Catat-In: Financial Tracker adalah aplikasi pencatatan dan pengelolaan keuangan pribadi berbasis mobile. Produk ini merupakan penerus spiritual dari **Rupiah Quest** (RPG pixel-art finance tracker), namun dengan pendekatan yang sepenuhnya profesional — seluruh elemen gamifikasi (level, XP, quest, boss battle, dsb.) dihilangkan dan digantikan dengan terminologi serta pengalaman pengguna yang lazim ditemukan pada aplikasi finansial modern.

Aplikasi ini menjadi bagian dari ekosistem **Catat-In**, melengkapi aplikasi Catat-In (time-tracking/productivity) yang sudah ada, dengan bahasa desain dan branding yang selaras.

### 1.2 Tujuan Produk
- Menyediakan alat pencatatan transaksi keuangan yang sederhana namun kredibel secara visual dan fungsional
- Membantu pengguna menyusun dan memantau anggaran (budgeting) bulanan
- Memberikan laporan dan analitik keuangan yang mudah dipahami
- Menjadi materi portofolio/submission kompetisi

### 1.3 Target Pengguna
Individu yang ingin mencatat pemasukan dan pengeluaran pribadi secara mandiri, tanpa ketergantungan pada akun/cloud, dengan kebutuhan privasi data yang tinggi (data tetap di perangkat).

### 1.4 Di Luar Cakupan (Out of Scope) — v1
- Sinkronisasi cloud / multi-device
- Sistem akun dan autentikasi
- Integrasi rekening bank / open banking
- Fitur sosial atau berbagi data antar pengguna
- Gamifikasi dalam bentuk apa pun

---

## 2. Prinsip Desain Produk

| Prinsip | Deskripsi |
|---|---|
| **Profesional** | Bahasa, ikonografi, dan copy menghindari istilah game (quest, XP, level, gold, dsb.) |
| **Privasi-first** | Seluruh data tersimpan lokal di perangkat; tidak ada login/akun |
| **Cepat & minim gesekan** | Mencatat transaksi harus bisa dilakukan dalam ≤3 tap dari home screen |
| **Konsisten dengan ekosistem Catat-In** | Style guide, tone, dan pola interaksi mengikuti aplikasi Catat-In yang sudah ada |

*(Style guide visual/UI disediakan terpisah oleh pemilik produk — tidak dibahas dalam dokumen ini.)*

---

## 3. Arsitektur & Tumpukan Teknologi

| Komponen | Pilihan |
|---|---|
| Framework | Flutter |
| Manajemen State | *(disarankan Riverpod, mengikuti Catat-In — konfirmasi sebelum implementasi)* |
| Penyimpanan Data | Lokal — SQLite atau Hive (on-device) |
| Autentikasi | Tidak ada |
| Backend/Cloud | Tidak ada (v1) |
| AI Insight (opsional) | Anthropic Claude API, untuk fitur ringkasan otomatis (lihat 4.6) |

---

## 4. Fitur & Requirement

### 4.1 Pencatatan Transaksi (Core)
**Deskripsi:** Pengguna dapat mencatat transaksi pemasukan dan pengeluaran.

**Requirement:**
- Input: jumlah, kategori, tanggal, catatan opsional, akun/dompet
- Dua tipe transaksi: Pemasukan (Income) dan Pengeluaran (Expense)
- Dukungan multi-akun/dompet (mis. Tunai, Rekening Bank, E-wallet)
- Edit dan hapus transaksi
- Pencarian dan filter transaksi (berdasarkan kategori, tanggal, akun, jumlah)
- Kategori dapat dikustomisasi pengguna (tambah/edit/hapus kategori)

**Kriteria Penerimaan:**
- Pengguna dapat mencatat transaksi baru dalam maksimal 3 tap dari home screen
- Data transaksi tersimpan secara persisten di penyimpanan lokal

---

### 4.2 Budgeting
**Deskripsi:** Pengguna dapat menyusun anggaran per kategori untuk periode bulanan.

**Requirement:**
- Alokasi budget per kategori per bulan
- Indikator visual progres penggunaan budget (mis. progress bar dengan status: aman/mendekati limit/melebihi)
- Notifikasi/alert saat pengeluaran kategori mendekati atau melebihi budget yang ditetapkan
- Budget dapat disalin/diulang otomatis ke bulan berikutnya (opsional, dapat dimatikan)
- Ringkasan sisa budget total per bulan

**Kriteria Penerimaan:**
- Sistem menghitung ulang progres budget secara real-time setiap kali transaksi baru dicatat pada kategori terkait

---

### 4.3 Laporan & Analitik
**Deskripsi:** Visualisasi data keuangan untuk membantu pengguna memahami pola keuangan mereka.

**Requirement:**
- Grafik tren pemasukan vs pengeluaran (mingguan/bulanan/tahunan)
- Breakdown pengeluaran per kategori (pie/donut chart)
- Perbandingan periode (mis. bulan ini vs bulan lalu)
- Ringkasan cashflow (total masuk, keluar, net) per periode
- Ekspor laporan (opsional — format CSV/PDF)

**Kriteria Penerimaan:**
- Semua grafik dapat difilter berdasarkan rentang tanggal dan akun

---

### 4.4 Target Menabung (Savings Goals)
**Deskripsi:** Pengguna dapat menetapkan target tabungan dan memantau progresnya — tanpa framing "quest" atau elemen game.

**Requirement:**
- Buat target: nama, jumlah target, tenggat waktu opsional, akun terkait
- Catat kontribusi/setoran menuju target
- Indikator progres (persentase dan nominal)
- Notifikasi saat target tercapai atau mendekati tenggat

**Kriteria Penerimaan:**
- Progres target diperbarui otomatis saat kontribusi dicatat

---

### 4.5 Transaksi Berulang (Recurring Transactions)
**Deskripsi:** Untuk tagihan atau pemasukan/pengeluaran rutin (langganan, gaji, cicilan).

**Requirement:**
- Buat transaksi berulang dengan frekuensi (harian/mingguan/bulanan/tahunan)
- Reminder sebelum transaksi berulang jatuh tempo
- Opsi pencatatan otomatis atau konfirmasi manual saat jatuh tempo

**Kriteria Penerimaan:**
- Transaksi berulang muncul di kalender/daftar transaksi mendatang sebelum benar-benar dicatat

---

### 4.6 Insight Otomatis (Opsional — v1.1+)
**Deskripsi:** Ringkasan naratif otomatis atas kondisi keuangan pengguna, menggunakan Claude API.

**Requirement:**
- Ringkasan bulanan otomatis dalam bahasa natural (mis. "Pengeluaran kategori Makanan naik 15% dibanding bulan lalu")
- Saran umum non-preskriptif terkait pola pengeluaran
- Diproses on-demand (bukan real-time) untuk efisiensi

**Catatan:** Fitur ini opsional dan dapat dipisahkan ke fase v1.1 agar v1 fokus pada fitur inti.

---

### 4.7 Dashboard / Home Screen
**Deskripsi:** Ringkasan cepat kondisi keuangan saat dibuka.

**Requirement:**
- Total saldo seluruh akun
- Ringkasan pengeluaran bulan berjalan vs budget
- Transaksi terbaru
- Akses cepat untuk tambah transaksi (tombol utama)

---

## 5. Model Data (High-Level)

| Entitas | Atribut Utama |
|---|---|
| **Transaction** | id, tipe (income/expense), jumlah, kategori_id, akun_id, tanggal, catatan |
| **Category** | id, nama, tipe, ikon, warna |
| **Account** | id, nama, saldo_awal, tipe |
| **Budget** | id, kategori_id, jumlah_limit, periode |
| **SavingsGoal** | id, nama, target_jumlah, jumlah_terkumpul, tenggat, akun_id |
| **RecurringTransaction** | id, transaction_template, frekuensi, tanggal_berikutnya |

---

## 6. Prioritas Fitur (MVP vs Iterasi Selanjutnya)

| Fitur | Prioritas |
|---|---|
| Pencatatan Transaksi | MVP (v1) |
| Budgeting | MVP (v1) |
| Laporan & Analitik | MVP (v1) |
| Dashboard | MVP (v1) |
| Target Menabung | v1.1 |
| Transaksi Berulang | v1.1 |
| Insight Otomatis (AI) | v1.1 / v1.2 |
| Ekspor Laporan | v1.2 |

---

## 7. Pertanyaan Terbuka (Open Questions)

- Manajemen state: konfirmasi apakah tetap Riverpod (konsisten dengan Catat-In) atau lainnya
- Apakah dashboard/statistik antara aplikasi Catat-In (time-tracking) dan Catat-In: Financial Tracker akan terhubung dalam satu aplikasi (multi-modul) atau tetap terpisah sebagai dua aplikasi berbeda?
- Kebutuhan backup/restore data lokal (mis. ekspor-impor file) mengingat tidak ada cloud sync

---

*Dokumen ini merupakan draft awal dan dapat direvisi seiring proses desain dan pengembangan.*
