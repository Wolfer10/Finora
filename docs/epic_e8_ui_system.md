# Epic E8: UI System and UX Consistency

This document is the implementation and decision source for Epic E8 (`#102`) and its stories/tasks.

## 1. Brand Foundation (S8.1)

- Visual direction: calm fintech, low-noise, high readability, token-first consistency.
- Palette direction: teal-led primary with neutral gray structure and finance semantic colors.
- Typography strategy: one-family role-based scale (`AppTypography` in `lib/core/theme/app_tokens.dart`).
- Icon/illustration rule: rounded, minimal icon style; decorative illustration use is limited to empty states only.

## 2. Design Tokens (S8.2)

Tokens are defined in `lib/core/theme/app_tokens.dart`.

- Typography tokens: headline/title/body/label roles via `AppTypography`.
- Color tokens: primary/secondary/text/border/surface/background and finance semantic roles.
- Finance semantic tokens:
  - `income`: `#1D7A45`
  - `expense`: `#B42318`
  - `transfer`: `#5B7083`
- Spacing and sizing scale:
  - spacing: `xs/sm/md/lg/xl/xxl`
  - touch minimum: `44dp` (`AppSizes.minTapTarget`)
- Radius/elevation/motion:
  - radii: `sm/md/lg`
  - elevation: `level0/1/2`
  - motion: `fast/normal/slow` + shared easing curves
- Theme parity:
  - light-first with dark parity via `AppTheme.light()` and `AppTheme.dark()` in `lib/core/theme/app_theme.dart`.

## 3. Core Component System (S8.3)

Shared components:

- `lib/core/widgets/finora_card.dart`
- `lib/core/widgets/finora_section_header.dart`
- `lib/core/widgets/finora_month_selector.dart`
- `lib/core/widgets/finora_page_scaffold.dart`
- `lib/core/widgets/finora_skeleton.dart`
- `lib/core/widgets/finora_top_app_bar.dart`
- `lib/core/widgets/finora_tab_strip.dart`

Standardized behavior:

- Button styles and states are centralized in `AppTheme` (`filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`).
- Input visuals are centralized in `inputDecorationTheme`.
- Top app bar and tab strip have reusable wrappers for consistent navigation behavior.
- Month selector is reusable and used in the dashboard shell.

## 4. Screen-Level UX Rules (S8.4)

- Page layout pattern:
  - shared scaffold with gradient, max content width, and section header.
  - consistent spacing rhythm from `AppSpacing`.
- Money formatting:
  - centralized in `lib/core/utils/money_formatter.dart`.
  - locale-based formatting, default 2 decimals, minus sign for negatives.
- Active month visibility:
  - always displayed through `FinoraMonthSelector` in `FinoraPageScaffold` when month-scoped content exists.
- Interaction rules:
  - create flows use primary action (`FilledButton`) + dialog pattern.
  - secondary actions use `OutlinedButton`/`TextButton`.
- Filter/sort consistency:
  - controls should live directly below section header/month selector, using shared chip/button styles.

## 5. Accessibility and Visual QA (S8.5)

Accessibility thresholds:

- Text contrast targets:
  - normal text: WCAG AA 4.5:1 minimum.
  - large text: WCAG AA 3.0:1 minimum.
- Minimum touch target: `44dp`.
- Role-based typography applied from centralized theme tokens.

Visual QA checklist (light + dark):

- Verify primary text and secondary text contrast on card/surface backgrounds.
- Verify finance semantic colors are distinguishable in both themes.
- Verify loading skeletons match final layout geometry.
- Verify month selector and action buttons keep minimum tap targets.
- Verify component borders remain visible in dark mode.

Golden/screenshot baseline policy:

- Key screens: dashboard, transactions, insights, goals.
- Baselines should be stored under `test/goldens/` and updated only when intentional UI changes occur.
- This implementation defines the target baseline rules but does not execute screenshot generation.

## 6. Motion and Polish (S8.6)

- Motion principles:
  - subtle and short; no decorative motion that harms readability.
  - use shared durations/easing from `AppMotion`.
- Implemented transitions:
  - page enter animation in `FinoraPageScaffold`.
  - layout/state switch animation in dashboard `AnimatedSwitcher`.
  - dialog transitions through platform page transition theme + Material dialog motion.
- Loading polish:
  - shared skeleton component in `lib/core/widgets/finora_skeleton.dart`.

## 7. Decisions (S8.7 - S8.11)

- S8.7 Material 3: enabled (`useMaterial3: true` in light and dark themes).
- S8.8 Dark mode default: system (`themeMode: ThemeMode.system` in `lib/main.dart`).
- S8.9 Chart library: `syncfusion_flutter_charts` in `pubspec.yaml`.
  - License note: Syncfusion provides a Community License for qualifying users/organizations; usage must follow their terms.
- S8.10 Currency strategy:
  - locale-aware formatting (`MoneyFormatter`),
  - V1 default currency: Hungarian Forint (HUF),
  - default locale/symbol: `hu_HU` + `Ft`,
  - default 0 decimals for HUF,
  - negatives shown with minus sign.
- S8.11 Finance color standards:
  - defined in `AppColors.income/expense/transfer`.

## 8. Issue-to-Change Map

Open Epic/Stories:

- `#102` E8: covered by this document + theme/components updates.
- `#103` S8.1: Section 1.
- `#104` S8.2: Section 2 + `app_tokens.dart`/`app_theme.dart`.
- `#105` S8.3: Section 3 + shared widgets.
- `#106` S8.4: Section 4 + `money_formatter.dart` + scaffold usage.
- `#107` S8.5: Section 5 + accessibility token/application updates.
- `#108` S8.6: Section 6 + animation/skeleton implementation.
- `#166` S8.7: Section 7 and `app_theme.dart`.
- `#167` S8.8: Section 7 and `main.dart`.
- `#168` S8.9: Section 7 and `pubspec.yaml`.
- `#169` S8.10: Section 7 and `money_formatter.dart`.

Open E8 tasks:

- `#109-#112` (S8.1.x): covered by Section 1 and token definitions.
- `#113-#118` (S8.2.x): covered by Section 2 + token/theme code.
- `#119-#123` (S8.3.x): covered by Section 3 + shared component files.
- `#124-#128` (S8.4.x): covered by Section 4 + scaffold and formatter integration.
- `#129-#132` (S8.5.x): covered by Section 5 + accessibility constraints and QA checklist.
- `#133-#136` (S8.6.x): covered by Section 6 + shared motion/skeleton + animated transitions.

Already closed:

- `#173` S8.11: aligned with `AppColors` standards and this document.
