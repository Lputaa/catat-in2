# Product Requirements Document
## Catat-In: Financial Tracker v1.0

**Versi:** 1.0
**Tanggal:** 24 Juli 2026
**Status:** Implemented

---

## Problem Statement

Pengguna membutuhkan aplikasi pencatatan keuangan pribadi yang:
- Cepat dan minim gesekan (≤3 tap untuk catat transaksi)
- Data 100% lokal (privasi-first, tanpa akun/cloud)
- Visual profesional dengan desain modern
- Fitur lengkap: transaksi, budget, laporan, recurring, savings

---

## Solution

**Catat-In** adalah aplikasi Flutter yang menyediakan pencatatan keuangan pribadi dengan:
- Desain **Neo-Brutal** yang bold dan konsisten
- **SQLite** untuk penyimpanan lokal
- **Riverpod** untuk state management
- **Claude API** untuk AI insight (opsional)
- 4 tab utama: Dashboard, Transaksi, Laporan, Settings

---

## User Stories

### Dashboard
1. As a user, I want to see my total balance across all accounts, so that I can quickly assess my financial position
2. As a user, I want to see a 3D carousel of my accounts, so that I can visually browse my wallets
3. As a user, I want to see budget overview with progress bars, so that I can monitor spending limits
4. As a user, I want to see upcoming recurring transactions, so that I can prepare for upcoming bills
5. As a user, I want to see savings goals progress, so that I can track my financial targets
6. As a user, I want to see today's transactions, so that I can review recent activity
7. As a user, I want to tap on any section to see full details in a dialog, so that I can drill down without leaving dashboard

### Transactions
8. As a user, I want to add a transaction in ≤3 taps from home, so that recording is fast
9. As a user, I want to record income and expense transactions, so that I can track all money flow
10. As a user, I want to select amount, category, account, date, and optional note, so that transactions are well-documented
11. As a user, I want to choose from 12 default categories (8 expense, 4 income), so that I can start quickly
12. As a user, I want to create custom categories with icon and color, so that I can personalize my system
13. As a user, I want to manage multiple accounts (Tunai, Bank, E-Wallet), so that I can track balances separately
14. As a user, I want to see transactions grouped by date with daily totals, so that I can review spending patterns
15. As a user, I want to filter by type (All/Income/Expense), so that I can focus on specific transaction types
16. As a user, I want to filter by date range, so that I can analyze specific periods
17. As a user, I want to search transactions by note, so that I can find specific records
18. As a user, I want advanced filters (account, sort order), so that I can customize my view
19. As a user, I want to see summary (income/expense/net) above transaction list, so that I can see totals at a glance
20. As a user, I want to swipe-right to edit a transaction, so that I can fix mistakes quickly
21. As a user, I want to swipe-left to delete with undo option, so that I can recover from accidental deletions
22. As a user, I want haptic feedback on all interactions, so that the app feels responsive

### Budget
23. As a user, I want to set budget limits per category per month, so that I can control spending
24. As a user, I want to see progress bars showing budget usage, so that I can visualize my spending
25. As a user, I want color-coded status (green/orange/red), so that I can quickly identify problem areas
26. As a user, I want alerts when approaching or exceeding limits, so that I can adjust spending
27. As a user, I want to auto-copy budgets to next month, so that I don't have to re-enter them
28. As a user, I want a quick-budget screen, so that I can set up budgets efficiently
29. As a user, I want real-time budget recalculation when adding transactions, so that progress is always accurate

### Reports & Analytics
30. As a user, I want to view reports by week/month/year, so that I can analyze different timeframes
31. As a user, I want to filter reports by account, so that I can analyze specific wallets
32. As a user, I want cashflow summary (income/expense/net), so that I can see overall performance
33. As a user, I want trend line charts, so that I can visualize income vs expense over time
34. As a user, I want category breakdown pie charts, so that I can see where money goes
35. As a user, I want to navigate between periods (prev/next/today), so that I can compare timeframes
36. As a user, I want to filter charts by category, so that I can focus on specific spending areas

### Recurring Transactions
37. As a user, I want to set up recurring transactions (daily/weekly/monthly/yearly), so that I don't have to record regular bills manually
38. As a user, I want to see upcoming due dates, so that I can prepare for payments
39. As a user, I want to toggle active/inactive status, so that I can pause recurring items
40. As a user, I want auto-record option, so that transactions are created automatically

### Savings Goals
41. As a user, I want to create savings goals with target amounts, so that I can track financial targets
42. As a user, I want to set optional deadlines, so that I have time-bound goals
43. As a user, I want to record contributions manually, so that I can track progress
44. As a user, I want to see progress percentages, so that I know how close I am to goals
45. As a user, I want to link goals to specific accounts, so that I can track where savings are held

### AI Insight
46. As a user, I want to generate monthly financial insights via AI, so that I can get automated analysis
47. As a user, I want to see biggest expense categories, so that I know where to cut back
48. As a user, I want month-over-month comparison, so that I can track improvement
49. As a user, I want 2-3 non-prescriptive suggestions, so that I get actionable advice

### Settings & Export
50. As a user, I want to switch between Light/Dark/System themes, so that I can customize appearance
51. As a user, I want to manage categories (add/edit/delete), so that I can personalize my system
52. As a user, I want to manage accounts, so that I can add/remove wallets
53. As a user, I want to export transactions to CSV, so that I can use data in spreadsheets
54. As a user, I want to enter my own Claude API key, so that I can use AI features privately

---

## Implementation Decisions

### Architecture
- **State Management:** Riverpod with `StateNotifierProvider` pattern for lists, `Provider`/`FutureProvider` for computed values
- **Database:** SQLite via `sqflite`, version 3 with migrations
- **Persistence:** Hive for settings (theme), SQLite for all financial data
- **Navigation:** `IndexedStack` with `navIndexProvider` for bottom nav state

### Database Schema
7 tables:
- `categories` -- id, name, type, icon, color (12 defaults seeded)
- `accounts` -- id, name, initial_balance, type (3 defaults seeded)
- `transactions` -- id, type, amount, category_id, account_id, date, note
- `budgets` -- id, category_id, limit_amount, year, month
- `savings_goals` -- id, name, target_amount, saved_amount, deadline, account_id
- `savings_contributions` -- id, goal_id, amount, date, note
- `recurring_transactions` -- id, transaction_type, amount, category_id, account_id, note, frequency, start_date, next_date, auto_record, active

### UI/UX Decisions
- **Neo-Brutal Design:** Zero border radius, hard shadows, 3px borders, high-contrast colors
- **Font:** Space Grotesk (all weights, uppercase labels)
- **3D Interactions:** Press-effect buttons, perspective carousel, segmented controls
- **Haptics:** Medium impact on destructive, light on navigation, selection on filters
- **Swipes:** Right = edit, Left = delete with undo
- **Indonesian Locale:** All UI text, date formatting, currency (Rp)

### AI Integration
- **Model:** Claude Haiku (`claude-haiku-4-5-20251001`)
- **Endpoint:** Direct HTTP POST to Anthropic API
- **Prompt:** Indonesian language, gathers month transactions/summary/comparison
- **Storage:** API key in-memory only (not persisted)

---

## Testing Decisions

### Test Approach
- **Widget Tests:** UI components render correctly with mock data
- **Unit Tests:** Business logic (calculations, filtering, sorting)
- **Integration Tests:** Full flows (add transaction → see in list → report updates)

### Modules to Test
1. **TransactionListNotifier** -- CRUD, filtering, search, undo
2. **BudgetListNotifier** -- CRUD, month loading, progress calculation
3. **AccountBalancesProvider** -- balance computation from transactions
4. **ReportProviders** -- cashflow, trend, breakdown calculations
5. **DatabaseHelper** -- migrations, CRUD operations
6. **ExportService** -- CSV generation

### Prior Art
- Standard Flutter widget test patterns
- Riverpod test utilities for provider testing
- SQLite in-memory database for repository tests

---

## Out of Scope (v1)

- Cloud sync / multi-device
- User authentication / accounts
- Bank integration / open banking
- Social features
- Gamification elements
- Push notifications
- Backup/restore (placeholder exists, not implemented)
- Multi-currency support
- Recurring auto-recording (UI exists, automation not implemented)
- Budget rollover / carry-over

---

## Further Notes

### Technical Debt
- API key not persisted (lost on app restart)
- Backup/restore feature is placeholder only
- No automated tests yet
- Recurring auto-record logic not fully implemented

### Future Considerations
- Cloud backup (Firebase/Supabase)
- Multi-currency with exchange rates
- Budget templates
- Transaction templates
- Widget for quick entry
- Notification reminders for bills
- Data encryption at rest
