# Catat-In: Future Development & Improvement Roadmap

**Versi:** 1.0
**Tanggal:** 25 Juli 2026
**Status:** Pre-publish audit

---

## Ringkasan

Dokumen ini mencatat celah, teknikal debt, dan peluang pengembangan Catat-In sebelum dan sesudah publish. Berdasarkan review terhadap PRD, kode, dan arsitektur saat ini.

---

## 🔴 Pre-Publish: Harus Diperbaiki

Hal-hal yang bisa bikin user frustrasi atau hilang trust begitu install.

### 1. Backup & Restore

**Status:** Placeholder belum diimplementasi.

**Masalah:** User hapus app, factory reset, atau ganti HP = data keuangan hilang permanen. Untuk app keuangan, ini deal-breaker.

**Solusi:**
- Export full database ke file `.db` atau `.json` via share dialog
- Import dari file backup yang sudah di-export
- Tidak perlu cloud — lokal saja sudah cukup untuk v1
- Letakkan di Settings > Data Management

**Effort:** Sedang (1-2 hari)

---

### 2. API Key Persistence

**Status:** API key hilang setiap restart app.

**Masalah:** User harus input ulang API key setiap buka app. Friction yang tidak perlu untuk fitur yang opsional.

**Solusi:**
- Simpan di Hive (sudah dipakai untuk theme) — tambah satu key-value pair
- Atau gunakan `flutter_secure_storage` untuk keamanan lebih baik
- Tambah opsi "Hapus API Key" di Settings

**Effort:** Kecil (beberapa jam)

---

### 3. Error Handling & Edge Cases

**Yang perlu dicek:**
- [ ] Transaksi dengan amount 0 atau negatif
- [ ] Kategori dihapus tapi masih dipakai transaksi → orphan data?
- [ ] Account dihapus tapi punya transaksi → saldo berantakan?
- [ ] Budget untuk kategori yang sudah dihapus
- [ ] Recurring transaction yang next_date sudah lewat (app closed berhari-hari)
- [ ] Database corrupt / migration gagal dari v2 ke v3
- [ ] Export CSV saat tidak ada data

**Effort:** Sedang (audit + fix)

---

### 4. Input Validation

**Yang perlu dicek:**
- [ ] Amount field: tidak boleh kosong, tidak boleh 0, format angka valid
- [ ] Category name: tidak boleh kosong, tidak boleh duplikat
- [ ] Account name: tidak boleh kosong
- [ ] Budget limit: tidak boleh negatif
- [ ] Savings target: tidak boleh 0
- [ ] Note field: batasan panjang (prevent abusers / DB bloat)

**Effort:** Kecil (tambah validator)

---

## 🟡 Short-Term: Bulan 1-2 Setelah Publish

Hal yang bikin app terasa "dewasa" dan layak dipakai jangka panjang.

### 5. Recurring Auto-Record Logic

**Status:** UI ada, automation belum jalan.

**Masalah:** User set recurring transaction tapi harus manual record. Ini defeat the purpose.

**Solusi:**
- Saat app dibuka, cek `recurring_transactions` yang `next_date <= today` dan `active = true`
- Auto-create transaction entries
- Update `next_date` ke frekuensi berikutnya
- Tampilkan notifikasi/snackbar "3 transaksi berulang telah dicatat"

**Effort:** Sedang

---

### 6. Onboarding Flow

**Target user:** Mahasiswa yang baru mulai catat pengeluaran.

**Masalah:** App langsung drop user ke dashboard kosong. Tidak ada guidance.

**Solusi:**
- First-launch wizard (3-4 halaman):
  1. "Catat pengeluaran pertamamu" — guided add transaction
  2. "Atur budget bulanan" — quick-budget setup
  3. "Tambah akun" — customize wallet names
- Skip option untuk user yang sudah tahu
- Simpan flag `onboarding_completed` di Hive

**Effort:** Sedang-Besar

---

### 7. Empty States yang Lebih Baik

**Masalah:** Layar kosong (belum ada transaksi, belum ada budget, dll) terasa intimidating.

**Solusi per layar:**
- Dashboard: "Mulai catat pengeluaran pertamamu" + CTA button
- Transactions: Illustration + "Belum ada transaksi" + tombol tambah
- Budget: "Atur budget untuk kontrol pengeluaran" + quick setup
- Reports: "Tambah transaksi dulu untuk lihat laporan"
- Savings: "Mulai target tabungan pertamamu"
- Recurring: "Atur transaksi berulang agar tidak lupa"

**Effort:** Kecil (widget + conditional rendering)

---

### 8. Data Integrity: Cascading Rules

**Masalah:** Tidak jelas apa yang terjadi saat user hapus kategori/akun yang masih dipakai.

**Solusi yang direkomendasikan:**
- **Kategori:** Tidak boleh dihapus kalau masih ada transaksi. Tampilkan dialog "Kategori ini dipakai di X transaksi. Pindahkan ke kategori lain dulu."
- **Account:** Tidak boleh dihapus kalau saldo ≠ 0 atau masih ada transaksi. Dialog serupa.
- **Budget:** Auto-delete kalau kategori dihapus (atau orphan protection)

**Effort:** Kecil-Sedang

---

### 9. Performance: Dashboard Startup

**Masalah:** `IndexedStack` render semua tab sekaligus. Kalau Reports tab punya chart berat, startup lambat.

**Solusi:**
- Lazy init: render tab hanya saat pertama kali dikunjungi
- Atau: load data async per tab, bukan semua sekaligus
- Cache computed values (total balance, budget progress) agar tidak recompute setiap build

**Effort:** Kecil-Sedang

---

### 10. Riverpod Pattern Update

**Status:** Menggunakan `StateNotifierProvider` (legacy pattern).

**Masalah:** Riverpod 2.x recommended `AsyncNotifierProvider` / `NotifierProvider`. `StateNotifier` deprecated path.

**Solusi:**
- Migrasi bertahap, satu provider per waktu
- Prioritas: `TransactionListNotifier` → `BudgetListNotifier` → sisanya
- Bisa dilakukan sambil refactor fitur lain

**Effort:** Besar (tapi tidak urgent)

---

## 🟢 Medium-Term: Bulan 3-6

Fitur yang bikin user tetap pakai app dan tidak pindah ke kompetitor.

### 11. Budget Rollover

**Status:** Out of scope v1, tapi user pasti minta.

**Masalah:** Budget bulan ini sisa Rp 500rb, bulan depan reset ke 0. User kehilangan context.

**Solusi:**
- Opsi per kategori: "Carry over sisa ke bulan depan"
- Visual: "Sisa dari bulan lalu: +Rp 500rb" di atas progress bar
- Toggle di settings atau per-budget

**Effort:** Sedang

---

### 12. Transaction Templates / Quick Entry

**Masalah:** User mahasiswa punya transaksi rutin yang sama (kopi, kos, transport). Input ulang tiap hari = friction.

**Solusi:**
- "Favorit" atau "Template" — simpan transaksi yang sering dipakai
- Dashboard: tampilkan 3-5 template sebagai shortcut
- Tap → auto-fill amount, category, account → konfirmasi → selesai (2 tap)

**Effort:** Kecil-Sedang

---

### 13. Spending Alerts / Notifications

**Masalah:** User tidak sadar sudah over-budget sampai cek app.

**Solusi:**
- Local notification saat:
  - Budget mencapai 80%
  - Budget terlewati
  - Recurring transaction jatuh tempo besok
- Tidak perlu server — `flutter_local_notifications` + scheduling

**Effort:** Sedang

---

### 14. Data Visualization yang Lebih Kaya

**Saat ini:** Line chart (trend) + Pie chart (breakdown).

**Tambah:**
- **Bar chart:** Perbandingan bulan per bulan
- **Heatmap:** Spending per hari dalam sebulan (seperti GitHub contribution graph)
- **Top 5 categories:** List, bukan hanya pie
- **Daily average:** "Rata-rata pengeluaran harian: Rp XX.XXX"

**Effort:** Kecil-Sedang per chart

---

### 15. Multi-Currency (Basic)

**Status:** Out of scope v1.

**Kasus:** Mahasiswa yang travel, atau catat transaksi online dalam USD.

**Solusi basic:**
- Tambah field `currency` di transaction (default: IDR)
- Manual exchange rate input (tidak perlu API)
- Display: "USD 10.00 (@ Rp 16.000 = Rp 160.000)"

**Effort:** Sedang

---

## 🔵 Long-Term: Bulan 6+

Fitur visioner yang bikin app punya moat.

### 16. Cloud Backup (Optional)

**Solusi yang direkomendasikan:**
- Firebase atau Supabase (gratis tier cukup untuk personal use)
- Login opsional — user yang mau sync, bikin akun. Yang tidak, tetap lokal
- Auto-backup harian kalau login
- End-to-end encryption sebelum upload

**Effort:** Besar

---

### 17. Shared / Split Bills

**Kasus:** Mahasiswa sering patungan makan, kos, dll.

**Solusi:**
- Tambah "Split" mode di transaksi
- Input: total amount + jumlah orang + siapa saja
- Track: siapa yang sudah bayar, siapa yang belum
- Tidak perlu multi-user — cukup catatan lokal

**Effort:** Besar

---

### 18. AI Insight yang Lebih Berguna

**Saat ini:** Monthly summary generik.

**Enhancement:**
- **Predictive:** "Berdasarkan pola 3 bulan terakhir, pengeluaranmu bulan depan sekitar Rp X"
- **Anomaly detection:** "Pengeluaran makan minggu ini 40% lebih tinggi dari biasanya"
- **Goal forecasting:** "Dengan tabungan saat ini, target HP baru tercapai Oktober"
- **Saran spesifik:** Bukan "kurangi pengeluaran" tapi "Kopi Starbuck bulan ini Rp 450rb — coba bawa tumbler 2x seminggu?"

**Effort:** Besar (prompt engineering + data aggregation)

---

### 19. Widget Home Screen

**Solusi:**
- Flutter home screen widget
- Tampilkan: saldo total, atau tombol "Catat Pengeluaran"
- Quick-add tanpa buka app full

**Effort:** Besar (platform-specific)

---

### 20. Data Encryption at Rest

**Masalah:** SQLite file bisa diakses di rooted device.

**Solusi:**
- `sqflite_sqlcipher` — drop-in replacement sqflite dengan AES-256 encryption
- PIN/biometric lock untuk buka app
- Tambah di Settings > Keamanan

**Effort:** Kecil-Sedang

---

## 📊 Prioritas Matrix

| # | Fitur | Impact | Effort | Prioritas |
|---|-------|--------|--------|-----------|
| 1 | Backup/Restore | 🔴 Kritis | Sedang | **Pre-publish** |
| 2 | API Key Persistence | 🟡 Penting | Kecil | **Pre-publish** |
| 3 | Error Handling Audit | 🔴 Kritis | Sedang | **Pre-publish** |
| 4 | Input Validation | 🔴 Kritis | Kecil | **Pre-publish** |
| 5 | Recurring Auto-Record | 🟡 Penting | Sedang | Month 1 |
| 6 | Onboarding Flow | 🟡 Penting | Besar | Month 1 |
| 7 | Empty States | 🟡 Penting | Kecil | Month 1 |
| 8 | Cascading Rules | 🟡 Penting | Kecil | Month 1 |
| 9 | Dashboard Performance | 🟢 Nice | Kecil | Month 1-2 |
| 10 | Riverpod Migration | 🟢 Nice | Besar | Month 2+ |
| 11 | Budget Rollover | 🟡 Penting | Sedang | Month 3 |
| 12 | Transaction Templates | 🟡 Penting | Kecil | Month 3 |
| 13 | Spending Alerts | 🟡 Penting | Sedang | Month 3-4 |
| 14 | Better Charts | 🟢 Nice | Sedang | Month 4 |
| 15 | Multi-Currency Basic | 🟢 Nice | Sedang | Month 5 |
| 16 | Cloud Backup | 🟡 Penting | Besar | Month 6+ |
| 17 | Split Bills | 🟢 Nice | Besar | Month 6+ |
| 18 | AI Insight Enhanced | 🟢 Nice | Besar | Month 6+ |
| 19 | Home Widget | 🟢 Nice | Besar | Month 6+ |
| 20 | Data Encryption | 🟡 Penting | Sedang | Month 6+ |

---

## Checklist Pre-Publish

- [x] Backup/Restore minimal berfungsi (export + import JSON file)
- [x] API key di-persist di Hive
- [x] Error handling: cascading delete guards (category & account)
- [x] Input validation: duplicate names, name length, note length, amount > 0
- [ ] Empty states di semua layar
- [ ] Test di device low-end (startup time, scroll performance)
- [ ] Test di Android versi minimum yang didukung
- [ ] Screenshot / screen recording untuk store listing

---

*Last updated: 25 Juli 2026*
