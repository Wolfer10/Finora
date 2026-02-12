# FINORA -- Pre-Coding Checklist

## 1. Product Scope (MVP Freeze)

### Core Features

-   [x] Accounts (manual management)
-   [x] Transactions (income / expense / transfer)
-   [x] Recurring transactions
-   [x] Monthly category analytics
-   [x] Budget predictions per category
-   [x] Goals with contributions
-   [x] Goal auto-completion logic
-   [x] Export / Import

### Explicitly NOT in V1

-   [x] Multi-currency
-   [x] Bank API integration
-   [x] Cloud sync
-   [x] Notifications
-   [x] Multi-user
-   [x] Advanced investment tracking

### MVP Scope Sign-off

-   [x] MVP features confirmed
-   [x] V1 exclusions confirmed
-   [x] Sign-off recorded: 2026-02-12 11:04 (local)

------------------------------------------------------------------------

## 2. Technical Foundation

### App Identity

-   [x] Final app name: Finora
-   [x] Organization ID confirmed: com.wolff.finora
-   [x] Package name finalized: com.wolff.finora.finora
-   [x] Android applicationId: com.wolff.finora.finora
-   [x] iOS bundle identifier: com.wolff.finora.finora
-   [x] Web app ID: finora

### Platforms

-   [x] Android
-   [x] iOS
-   [x] Web
-   [x] Android min SDK: 24 (Android 7.0)
-   [x] iOS minimum: 13.0
-   [x] Web targets: Evergreen (Chrome, Edge, Firefox, Safari)

### State Management

-   [x] Riverpod 2.x
-   [x] AsyncNotifier for DB state
-   [x] Derived providers for calculations
-   [x] Global selectedMonthProvider

### Database

-   [x] Drift
-   [x] Single database file
-   [x] Migration versioning strategy defined: sequential schemaVersion ints
-   [x] Soft delete using isDeleted

------------------------------------------------------------------------

## 3. Architecture Rules

-   [x] Domain layer contains no Flutter imports
-   [x] Domain layer contains no Drift imports
-   [x] Repositories abstract database
-   [x] Mappers convert DB ↔ Domain
-   [x] Business logic only in domain services
-   [x] UI contains zero calculation logic
-   [x] Verification command: `rg --glob "lib/features/**/domain/**" -n "package:flutter|package:drift"`

------------------------------------------------------------------------
## 4. Calculation Engine Plan

-   [x] MonthlySummaryCalculator
-   [x] CategoryAnalyticsCalculator
-   [x] BudgetVarianceCalculator
-   [x] GoalProgressCalculator
-   [x] NetWorthCalculator

------------------------------------------------------------------------
## 5. Goal Logic Rules

-   [ ] If saved ≥ target → mark completed
-   [ ] If target changes → re-evaluate completion
-   [ ] Completion stores completedAt
-   [ ] Required monthly contribution auto recalculated
-   [ ] Archived goals hidden from dashboard

------------------------------------------------------------------------

## 6. Export / Import Strategy

-   [x] JSON export of domain models
-   [ ] Encrypted JSON (optional)
-   [ ] SQLite file export (optional)

------------------------------------------------------------------------

## 7. UI System Decisions

-   [x] Material 3 enabled
-   [x] Dark mode default decided: System
-   [x] Chart library chosen: syncfusion_flutter_charts
-   [x] Currency formatting strategy: intl locale + app currency, negatives with minus sign
-   [x] Consistent month selector widget

------------------------------------------------------------------------
## 8. Error Handling Strategy

-   [x] AsyncValue error handling
-   [x] Repository-level error safety
-   [x] Global error handler enabled

------------------------------------------------------------------------
## 9. Testing Strategy

-   [x] Goal completion tests
-   [x] Monthly calculation tests
-   [x] Budget variance tests
-   [x] Repository unit tests

------------------------------------------------------------------------
## 10. Performance Guardrails

-   [x] Lazy loading transactions by month
-   [x] Index on date
-   [x] Index on accountId
-   [x] Index on categoryId
-   [x] Avoid loading all transactions at once

------------------------------------------------------------------------
## 11. UX Consistency Rules

-   [x] Centralized money formatting utility
-   [x] Income color standardized (green)
-   [x] Expense color standardized (red)
-   [x] Transfer neutral color (gray/blue)
-   [x] Always show active month at top

------------------------------------------------------------------------
## 12. Build Order Plan

1.  Database schema
2.  Domain entities
3.  Mappers
4.  Repositories
5.  Transactions feature
6.  Accounts
7.  Monthly summary calculations
8.  Goals
9.  Predictions
10. Insights screen
11. Dashboard
12. Export / Import
13. UI polish
