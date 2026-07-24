# Catat-In Style Guide

> Sistem desain komprehensif untuk aplikasi Catat-In
> Design Language: **Neo-Brutalism**

---

## 1. Design Philosophy

Catat-In menggunakan **Neo-Brutalism** — gaya desain yang menonjolkan kejujuran visual melalui:

- **Tepi tajam** — hampir semua elemen memiliki `borderRadius: 0`
- **Border tebal** — 3px hitam sebagai standar
- **Hard shadow** — drop shadow tanpa blur (`blurRadius: 0`)
- **Kontras tinggi** — warna bold di atas kanvas krem/putih
- **Tipografi berani** — weight w700-w900 mendominasi
- **Label uppercase** — section headers, chips, badges

**Pengecualian border radius** (digunakan di konteks tertentu):
| Konteks | Radius | Alasan |
|---|---|---|
| Dialog (edit, tracking, gap) | 20 | Modal context, softer feel |
| Template cards | 16 | Card grid aesthetic |
| Category filter chips | 20 | Friendly interaction element |
| Emoji picker items | 10 | Grid uniformity |
| SnackBar | 12 | Floating element |

---

## 2. Color System

### 2.1 Light Theme Tokens (`NeoBrutalColors`)

```
bg:        #FFF8E7   (Warm cream — scaffold background)
ink:       #1A1A1A   (Softer black — text, borders, shadows)
primary:   #FF6B35   (Burnt orange — CTA, focused states)
secondary: #4361EE   (Electric blue — secondary elements)
success:   #06D6A0   (Neon green — running states, success)
danger:    #EF476F   (Bright red — delete, stop, errors)
surface:   #FFFFFF   (White — card/panel backgrounds)
muted:     #E5E5E5   (Grey — disabled, dividers)
```

### 2.2 Dark Theme Tokens

```
bgDark:    #121212   (True dark — scaffold background)
surfaceDark: #1E1E1E (Slightly lighter — card surfaces)
darkLine:  #E0E0E0   (Soft white — borders in dark mode)
inkDark:   #F5F5F5   (Soft white — text in dark mode)
```

### 2.3 Accent/Tag Colors

```
cyan:      #00D9FF   (Nav indicator, Sosial category)
yellow:    #FFD60A   (FAB, selected chips, highlights)
green:     #06D6A0   (Same as success)
purple:    #B5179E   (Hiburan category)
orange:    #FF9F1C   (Ibadah category)
```

### 2.4 Category Color Map

| Kategori | Warna | Hex |
|---|---|---|
| 🏢 Kerja | Burnt Orange | `#FF6B35` |
| 📚 Belajar | Electric Blue | `#4361EE` |
| 🏃 Olahraga | Neon Green | `#06D6A0` |
| 🎮 Hiburan | Purple | `#B5179E` |
| 🍚 Keseharian | Yellow | `#FFD60A` |
| 👥 Sosial | Cyan | `#00D9FF` |
| 🕌 Ibadah | Orange | `#FF9F1C` |
| 📦 Lainnya | Muted Grey | `#E5E5E5` |

> **Catatan**: Chart di halaman Report menggunakan palet Material-like yang berbeda (`CategoryMeta.colors`). Ini disengaja untuk kontras visual yang lebih baik di chart.

### 2.5 TimeValue Color Map

| Time Value | Warna | Skor |
|---|---|---|
| 🎯 Investasi | Amber | 5 |
| ⚡ Produktif | Green | 4 |
| 🍚 Kebutuhan | Blue | 3 |
| 😌 Santai | Teal | 2 |
| 🫠 Terbuang | Red | 1 |

### 2.6 Grade Colors

| Grade | Threshold | Warna |
|---|---|---|
| A | score ≥ 4.5 | Amber |
| B | score ≥ 3.5 | Green |
| C | score ≥ 2.5 | Blue |
| D | score ≥ 1.5 | Orange |
| E | score < 1.5 | Red |

### 2.7 Calendar Day Score Colors

| Score | Warna |
|---|---|
| 0 (no data) | Grey.shade300 |
| ≥ 4.0 | Green |
| ≥ 3.0 | Blue |
| ≥ 2.0 | Orange |
| < 2.0 | Red |

### 2.8 Hardcoded Colors (Dark Mode Specifics)

| Konteks | Hex |
|---|---|
| TimelineItem header (dark) | `#2C2C2C` |
| Disabled chip bg (dark) | `#333333` |
| Switch inactive bg (dark) | `#3A3A3A` |
| Notes bg (light) | `#F0F0F0` |
| Notes bg (dark) | `#2A2A2A` |
| Outline variant (dark) | `#363636` |
| ID card footer (dark) | `#1A1A1A` |
| ID card footer (light) | `#F5F5F5` |
| Chart tooltip bg (dark) | `#2A2A2A` |
| Chart grid (dark) | `#2A2A2A` |

---

## 3. Typography

### 3.1 Font Family

- **Primary**: `Space Grotesk` (via `google_fonts`)
- **Monospace**: System monospace — hanya untuk `labelSmall` dan elemen tracking

### 3.2 Type Scale

| Style | Weight | Size | Height | Letter Spacing | Penggunaan |
|---|---|---|---|---|---|
| `displayLarge` | w900 | 48px | 1.0 | 0 | Hero numbers, grade display |
| `displayMedium` | w800 | 36px | 1.05 | 0 | Section hero numbers |
| `displaySmall` | w700 | 28px | 1.1 | 0 | Card hero numbers |
| `headlineMedium` | w700 | 24px | — | 0 | Section headings |
| `headlineSmall` | w700 | 20px | — | 0 | Card headings |
| `titleLarge` | w700 | 18px | — | 0 | Card titles |
| `bodyLarge` | w500 | 16px | 1.5 | — | Primary body text |
| `bodyMedium` | w400 | 14px | 1.5 | — | Secondary body text |
| `labelLarge` | w700 | 14px | — | 0.5 | Buttons, labels |
| `labelMedium` | w600 | 12px | — | 0.8 | Small labels, chips |
| `labelSmall` | w600 | 11px | — | 1.2 | Monospace, tracking info |

### 3.3 Inline Text Patterns

| Pola | Spesifikasi |
|---|---|
| Section title | 12-13px, w900, letterSpacing 1.0-1.5, uppercase |
| Hero number | 36-48px, w900, height 1.0 |
| Card heading | 18px, w700-w900 |
| Body text | 14-16px, w500-w600 |
| Label/chip | 11-12px, w700-w900, letterSpacing 0.5-1.2 |
| Timer display | 34px, w800, `FontFeature.tabularFigures()` |
| AppBar title | 20px, w700 |
| AppBar subtitle | w900, letterSpacing -0.5 |
| SnackBar content | w700, color: white |

### 3.4 Special Formatting

- **FontFeature.tabularFigures()** — digunakan di semua display waktu agar angka tidak "bergerak"
- **Durasi singkat**: `2j 30m` (Indonesian shorthand)
- **Durasi panjang**: `2 jam 30 mnt`
- **Coverage labels**: `Sangat Lengkap` (≥80%), `Cukup Lengkap` (≥50%), `Banyak Waktu Belum Tercatat` (<50%)

---

## 4. Spacing System

### 4.1 Theme-Level Spacing

| Konteks | Padding/Margin |
|---|---|
| Card margin | horizontal: 16, vertical: 8 |
| Input content padding | horizontal: 16, vertical: 16 |
| Chip padding | horizontal: 10, vertical: 8 |
| Button padding | horizontal: 24, vertical: 16 |
| Text button padding | horizontal: 16, vertical: 12 |
| Button min height | 48 |
| NavigationBar height | 60 |

### 4.2 Widget-Level Spacing

| Pola | Nilai |
|---|---|
| NeoCard default padding | all(16) |
| NeoButton padding | symmetric(horizontal: 24, vertical: 12) |
| Screen body padding | all(16) |
| Section vertical gap | 16-24 |
| Between form fields | 12 |
| Label → content gap | 8-10 |
| Between chips | 6-10 |
| Between list items | 8-16 |
| Timeline item bottom | 16 |
| Timeline header padding | symmetric(horizontal: 16, vertical: 12) |
| Notes box padding | all(12) |
| Report review card | symmetric(horizontal: 24, vertical: 16) |
| Settings tile | symmetric(horizontal: 14, vertical: 14) |
| Bottom sheet | all(24) atau fromLTRB(24, 24, 24, 32/48) |
| Dialog inset | symmetric(horizontal: 16, vertical: 24) |
| Dialog inner | all(24) |

---

## 5. Shadow System

### 5.1 Shadow Presets

| Preset | Offset | Blur | Color (Light) | Color (Dark) |
|---|---|---|---|---|
| `hardShadow` | (6, 6) | 0 | `ink` (#1A1A1A) | `Colors.black` |
| `hardShadowSmall` | (4, 4) | 0 | same | same |
| `hardShadowLarge` | (8, 8) | 0 | same | same |

### 5.2 Shadow Usage Map

| Elemen | Shadow Offset |
|---|---|
| NeoCard default | (6, 6) |
| NeoButton default | (4, 4) |
| NeoSegmentedControl | (4, 4) |
| TimelineItem | (6, 6) |
| NowMarker | (4, 4) |
| GapIndicator | (4, 4) |
| RunningBanner | (6, 6) |
| CategoryDistributionChart | (5, 5) |
| CategoryFilterChip (selected) | (3, 3) |
| Template card | (3, 3) |
| Report cards (standard) | (5, 5) |
| Report cards (detail) | (3, 3) |
| CategorySpotlightCard | (4, 4) |
| Calendar today/selected | (2, 2) |
| Settings tiles | (4, 4) atau (3, 3) |

> **Prinsip**: Semakin penting/interaktif elemen, semakin besar shadow. Elemen kecil (chip, legend) menggunakan shadow lebih kecil.

---

## 6. Border System

### 6.1 Border Width Hierarchy

| Level | Width | Penggunaan |
|---|---|---|
| Primary | 3px | Cards, buttons, inputs, FAB, dialogs, bottom sheets |
| Secondary | 2px | Chips, dividers, snackbar, calendar cells, settings tiles |
| Tertiary | 1-1.5px | Legend squares, comparison bars, accents |

### 6.2 Border Color

| Theme | Warna |
|---|---|
| Light | `ink` (#1A1A1A) |
| Dark | `darkLine` (#E0E0E0) |

---

## 7. Component Library

### 7.1 Core Primitives

#### NeoCard
Container utama dengan border 3px + hard shadow + borderRadius 0.
- Props: `color`, `borderWidth` (default 3), `shadowOffset` (default 6,6), `padding` (default all 16)
- Auto text color berdasarkan luminance background
- Wraps child dalam `DefaultTextStyle` + `IconTheme`

#### NeoButton
Tombol dengan animasi tekan.
- On press: shadow hilang, translate offset/2 ke bawah-kanan
- Animation: 100ms ease-out via `AnimatedContainer`
- Props: `color`, `borderWidth` (default 3), `shadowOffset` (default 4,4)

#### NeoSegmentedControl<T>
Tab selector generik.
- Row of `Expanded` segments, 3px border divider
- Selected: `yellow` (#FFD60A) background, w900 weight
- Labels selalu uppercase

#### NeoTextField
Thin wrapper atas Material `TextField`.
- Styling sepenuhnya dari `InputDecorationTheme`
- Filled white, 3px border, borderRadius 0
- Focused: primary orange border

### 7.2 Feature Widgets

#### CatatInAppBar
- Logo icon dengan elastic scale-in animation (1200ms, `Curves.elasticOut`)
- Double-stacked title: "Catat-In" (primary) + page title (muted)
- Tap logo → motivational SnackBar

#### TimelineItem
- NeoCard dengan black header bar (time range + duration badge)
- Content: category emoji + name, notes section, edit/delete buttons
- Category chip inline (Container + border, uppercase label)

#### RunningBanner
- Green NeoCard (#06D6A0)
- Timer icon box + activity name + elapsed HH:MM:SS
- Stop/detail NeoButton
- Template hint strip (jika dari template)

#### GapIndicator
- Yellow NeoCard (#FFD60A)
- "KOSONG Xm — KETUK UNTUK ISI"
- Tap → dialog dengan template quick-fill

#### CategoryDistributionChart
- Stacked horizontal bar dari category colors
- Legend row: tappable colored squares dengan emoji
- Stats: activity count + coverage %

#### FinishActivitySheet
- Modal bottom sheet: name field, notes field, TimeValue ChoiceChips, category dropdown
- Green "SIMPAN AKTIVITAS" NeoButton

#### Report Cards
- `ReviewCard`: Full-screen wrapper, 24px horizontal padding
- `ReviewTitle`: 13px, w700, letterSpacing 1.2, uppercase
- `HeroNumber`: 48px, w900
- `StatChip`: 20px value + 11px label
- `OpeningCard`: Grade square + total time + animated progress bar
- `ComparisonCard`: Delta rows dengan arrow indicators (green up, red down)
- `TimeQualityCard`: Stacked bar + detail rows
- `StreakCard`: Split — best day (trophy) + streak counter (fire)
- `InsightCard`: Quote icon + auto-generated text
- `TopActivitiesCard`: Podium layout — 2nd/1st/3rd bars
- `CategorySpotlightCard`: Hero block + comparison bar

#### Settings Widgets
- `SettingsSection`: 8px-wide primary color bar + bold title
- `SettingsTile`: NeoCard + IconBox (42x42) + title/subtitle + chevron
- `SettingsSwitchTile`: Same + animated toggle (44x24, 18x18 thumb, green on)
- `SettingsDangerTile`: Red-tinted variant
- `SettingsAboutTile`: Info variant, no chevron
- `ExportOptionTile`: Colored icon box + title/subtitle + chevron

#### IconBox Pattern (Settings)
- 42×42 container
- Icon size: 20
- Background: category color at 15% opacity (light) / 28% (dark)
- Border: 2px

### 7.3 Template Quick Start
- 2-column grid, max 4 cards
- Left accent strip: 5px, TimeValue color
- Category badge top-right
- Name + TimeValue label
- "BUAT TEMPLATE" action chip
- Empty state: bolt icon + CTA

---

## 8. Animation System

| Animasi | Durasi | Curve | Konteks |
|---|---|---|---|
| Button press/release | 100ms | linear | NeoButton, FAB, nav items |
| Logo scale-in | 1200ms | elasticOut | CatatInAppBar |
| Progress bar fill | 1200ms | easeOutExpo | OpeningCard, score bars |
| Toggle switch | 200ms | linear | SettingsSwitchTile |
| Mode pill toggle | 150ms | linear | Settings theme toggle |
| Segmented control | 150ms | linear | NeoSegmentedControl |
| Running ticker | 1000ms | — | Periodic timer update |
| Page transitions | — | — | Cupertino slide (semua platform) |

**Teknik**:
- `AnimatedContainer` untuk color/size/offset changes
- `TweenAnimationBuilder<double>` untuk progress values
- `AnimatedAlign` untuk position changes
- Haptic feedback: `HapticFeedback.mediumImpact()` pada delete dan save

---

## 9. Icon System

### 9.1 Library
Material Icons (Rounded variants diprioritaskan)

### 9.2 Icon Map

| Aksi | Icon | Size |
|---|---|---|
| Waktu | `Icons.schedule_rounded` | 16-20 |
| Edit | `Icons.edit_rounded` | 16-20 |
| Hapus | `Icons.delete_outline_rounded` | 16-20 |
| Catatan | `Icons.notes_rounded` | 13-18 |
| Mulai | `Icons.play_arrow_rounded` | 20 |
| Stop | `Icons.stop_rounded` | 20 |
| Timer | `Icons.timer_rounded` | 20-28 |
| Tutup | `Icons.close_rounded` | 18-20 |
| Peringatan | `Icons.warning_amber_rounded` | 24 |
| Template | `Icons.bolt_rounded` | 16-64 |
| Cek | `Icons.check_circle_outline_rounded` | 20 |
| Chart pie | `Icons.pie_chart_outline_rounded` | 20 |
| Chart bar | `Icons.bar_chart_rounded` | 16 |
| Chevron kanan | `Icons.chevron_right_rounded` | 18-22 |
| Info | `Icons.info_outline_rounded` | — |
| Download | `Icons.download_outlined` | — |
| Import | `Icons.file_download_outlined` | — |
| Kalender | `Icons.calendar_month_rounded` | — |
| CSV | `Icons.table_chart_rounded` | — |
| JSON | `Icons.code_rounded` | — |
| Alarm | `Icons.alarm_rounded` | — |
| Mode terang | `Icons.light_mode_rounded` | 13-20 |
| Mode gelap | `Icons.dark_mode_rounded` | 13-20 |
| Mode sistem | `Icons.phone_android_rounded` | 13-20 |

---

## 10. UI Patterns

### 10.1 Page Structure
```
Scaffold
  └── CatatInAppBar (animated logo + stacked title)
  └── Body: SingleChildScrollView / ListView
       └── padding: all(16)
       └── Sections separated by SizedBox(height: 16)
```

### 10.2 Bottom Navigation
- 4 tab + center-docked FAB
- `_NeoBottomNavigation` (custom, bukan Material NavigationBar)
- Animated color fill on selection
- Tab warna: Today (primary), Calendar (cyan), Report (green), Settings (purple)
- FAB: yellow (#FFD60A), label "CATAT"

### 10.3 Bottom Sheets
- Background: cream (light) / dark surface (dark)
- Border: 3px top
- Drag handle
- Padding: all(24) atau fromLTRB(24, 24, 24, 32/48)

### 10.4 Dialogs
- Border radius: 20
- Border: 3px
- Surface: white (light) / dark (dark)
- Max height: 85% viewport

### 10.5 Chips & Badges
- Border: 2px
- Selected state: yellow bg (light) / primary bg (dark)
- Labels: uppercase, w700

### 10.6 Empty States
- Centered icon card
- Bold message text
- Yellow CTA chip/button

### 10.7 Feedback
- **SnackBar with Undo**: delete → SnackBar 6 detik, amber "Undo" text
- **Haptic**: `mediumImpact()` pada delete dan save
- **Validation SnackBars**: pesan error singkat

### 10.8 Charts
- **Stacked bar** (Today): Manual colored containers
- **Stacked bar** (Report): `fl_chart` BarChart dengan stacked rods
- **Donut/Pie** (Report): `fl_chart` PieChart dengan emoji labels
- **Timer ring**: CustomPaint arc progress
- **Progress bar**: LinearProgressIndicator + TweenAnimationBuilder

---

## 11. Responsive & Accessibility

### 11.1 Kontras
- NeoCard auto text color berdasarkan luminance background
- Dark mode: soft white (#F5F5F5) di atas dark surface (#1E1E1E)
- Light mode: softer black (#1A1A1A) di atas white/cream

### 11.2 Dark Mode
- Toggle: Light / Dark / System (tersimpan di Hive settings)
- Semua komponen mendukung dual theme
- Border color berubah: ink → darkLine
- Shadow tetap hitam

### 11.3 Platform
- Android: primary target, home widget support
- Web: supported
- Windows: supported
- Page transitions: Cupertino di semua platform

---

## 12. Durasi Format Reference

| Format | Contoh | Penggunaan |
|---|---|---|
| Short | `2j 30m` | Timeline items, chips |
| Long | `2 jam 30 mnt` | Report details |
| HMS | `02:30:45` | Running timer (tabular figures) |
| Clock | `14:30` | Time pickers, schedule |

---

## 13. Changelog

| Tanggal | Perubahan |
|---|---|
| 2026-07-22 | Initial style guide created from codebase analysis |
