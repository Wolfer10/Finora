# FINORA -- Pre-Coding Checklist

## 1. Product Scope (MVP Freeze)

### Core Features

-   [ ] Accounts (manual management)
-   [ ] Transactions (income / expense / transfer)
-   [ ] Recurring transactions
-   [ ] Monthly category analytics
-   [ ] Budget predictions per category
-   [ ] Goals with contributions
-   [ ] Goal auto-completion logic
-   [ ] Export / Import

### Explicitly NOT in V1

-   [ ] Multi-currency
-   [ ] Bank API integration
-   [ ] Cloud sync
-   [ ] Notifications
-   [ ] Multi-user
-   [ ] Advanced investment tracking

------------------------------------------------------------------------

## 2. Technical Foundation

### App Identity

-   [ ] Final app name: Finora
-   [ ] Organization ID confirmed
-   [ ] Package name finalized

### Platforms

-   [ ] Android
-   [ ] iOS
-   [ ] Web

### State Management

-   [ ] Riverpod 2.x
-   [ ] AsyncNotifier for DB state
-   [ ] Derived providers for calculations
-   [ ] Global selectedMonthProvider

### Database

-   [ ] Drift
-   [ ] Single database file
-   [ ] Migration versioning strategy defined
-   [ ] Soft delete using isDeleted

------------------------------------------------------------------------

## 3. Architecture Rules

-   [ ] Domain layer contains no Flutter imports
-   [ ] Domain layer contains no Drift imports
-   [ ] Repositories abstract database
-   [ ] Mappers convert DB ↔ Domain
-   [ ] Business logic only in domain services
-   [ ] UI contains zero calculation logic

------------------------------------------------------------------------

## 4. Calculation Engine Plan

-   [ ] MonthlySummaryCalculator
-   [ ] CategoryAnalyticsCalculator
-   [ ] BudgetVarianceCalculator
-   [ ] GoalProgressCalculator
-   [ ] NetWorthCalculator

------------------------------------------------------------------------

## 5. Goal Logic Rules

-   [ ] If saved ≥ target → mark completed
-   [ ] If target changes → re-evaluate completion
-   [ ] Completion stores completedAt
-   [ ] Required monthly contribution auto recalculated
-   [ ] Archived goals hidden from dashboard

------------------------------------------------------------------------

## 6. Export / Import Strategy

-   [ ] JSON export of domain models
-   [ ] Encrypted JSON (optional)
-   [ ] SQLite file export (optional)

------------------------------------------------------------------------

## 7. UI System Decisions

-   [ ] Material 3 enabled
-   [ ] Dark mode default decided
-   [ ] Chart library chosen
-   [ ] Currency formatting strategy
-   [ ] Consistent month selector widget

------------------------------------------------------------------------

## 8. Error Handling Strategy

-   [ ] AsyncValue error handling
-   [ ] Repository-level error safety
-   [ ] Global error handler (optional)

------------------------------------------------------------------------

## 9. Testing Strategy

-   [ ] Goal completion tests
-   [ ] Monthly calculation tests
-   [ ] Budget variance tests
-   [ ] Repository unit tests

------------------------------------------------------------------------

## 10. Performance Guardrails

-   [ ] Lazy loading transactions by month
-   [ ] Index on date
-   [ ] Index on accountId
-   [ ] Index on categoryId
-   [ ] Avoid loading all transactions at once

------------------------------------------------------------------------

## 11. UX Consistency Rules

-   [ ] Centralized money formatting utility
-   [ ] Income color standardized
-   [ ] Expense color standardized
-   [ ] Transfer neutral color
-   [ ] Always show active month at top

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
