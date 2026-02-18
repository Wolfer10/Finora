# Recurring Transactions Strategy (S17.4)

## Rule Model

Recurring rules are persisted in `recurring_rules` with:
- transaction template fields: `type`, `account_id`, `category_id`, `to_account_id`, `amount`, `note`
- recurrence fields: `recurrence_unit` (`daily|weekly|monthly`), `recurrence_interval`, `start_date`, `next_run_at`, optional `end_date`
- lifecycle fields: `created_at`, `updated_at`, `is_deleted`

## Creation Flow

When user enables `Create recurring rule` in **Add Transaction**:
1. A recurring rule is created from the transaction template.
2. The initial transaction is created immediately.
3. Transaction(s) store `recurringRuleId` for linkage.
   - Transfer creates two linked transactions (source and destination), both linked to the same `recurringRuleId`.

## Execution Flow

Execution is manual via top-bar action: **More actions -> Run Recurring**.

The runner:
1. Loads rules with `next_run_at <= now`.
2. Generates one or more due transactions per rule.
3. Advances `next_run_at` by recurrence settings until it is in the future.
4. Stores generated transaction linkage through `recurringRuleId`.
5. Soft-deletes rules that passed `end_date`.

This flow is deterministic and idempotent across repeated manual runs because each rule advances its `next_run_at` after generation.
