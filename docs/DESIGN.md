# TankVenn Design System

This document is the authoritative reference for TankVenn's visual design language. All UI contributions must follow these guidelines. Changes to the design system require approval from the main contributors.

---

## Design Language

TankVenn has two distinct visual modes:

**Dark mode** is the primary experience. It uses a cyberpunk-inspired navy/cyan palette — deep blue-black backgrounds, bright cyan accents, and cool-toned surfaces. The goal is a technical, high-contrast feel that is comfortable for night-time use.

**Light mode** is a standard Material 3 light theme. It uses neutral whites and grays with a blue primary. It is intentionally understated — no personality of its own, just clean and accessible.

---

## Colors

All colors are defined in `lib/config/app_colors.dart`. Never use raw hex values in widgets or screens — always reference a token from `AppColors`.

### Dark palette

| Token | Hex | Role |
|---|---|---|
| `darkBackground` | `#0B1326` | Scaffold background |
| `darkSurface` | `#171F33` | Cards, sheets |
| `darkSurfaceLowest` | `#060E20` | Deepest inset surfaces |
| `darkSurfaceLow` | `#131B2E` | Slightly recessed surfaces |
| `darkSurfaceHigh` | `#222A3D` | Elevated surfaces |
| `darkSurfaceHighest` | `#2D3449` | Most elevated surfaces |
| `darkOnSurface` | `#DAE2FD` | Primary text |
| `darkOnSurfaceVariant` | `#BBC9CF` | Secondary/muted text |
| `darkPrimary` | `#A4E6FF` | Interactive elements, links |
| `darkPrimaryContainer` | `#00D1FF` | Buttons, FABs |
| `darkSecondary` | `#B9C7E0` | Secondary actions |
| `darkOutlineVariant` | `#3C494E` | Borders, dividers |
| `darkError` | `#FFB4AB` | Error states |
| `accent` | `#00D1FF` | Bright cyan highlight — use sparingly |

### Light palette

| Token | Hex | Role |
|---|---|---|
| `lightBackground` | `#F8F9FA` | Scaffold background |
| `lightSurface` | `#FFFFFF` | Cards, sheets |
| `lightSurfaceLow` | `#F3F4F5` | Recessed surfaces, input fills |
| `lightSurfaceHigh` | `#E8EAED` | Elevated surfaces |
| `lightOnSurface` | `#191C1D` | Primary text |
| `lightPrimary` | `#003F87` | Interactive elements, links |
| `lightPrimaryContainer` | `#0056B3` | Buttons, FABs |
| `lightSecondary` | `#006E25` | Secondary actions |

### Context-aware helpers

For widgets that need to support both themes, use the static helper methods on `AppColors` instead of accessing palette tokens directly:

```dart
// Correct
color: AppColors.primary(context)
color: AppColors.textMuted(context)

// Wrong — breaks theme switching
color: AppColors.darkPrimary
color: const Color(0xFF003F87)
```

Available helpers: `background`, `surface`, `surfaceElevated`, `surfaceLow`, `border`, `textPrimary`, `textMuted`, `pillNavBackground`, `primary`, `primaryContainer`.

---

## Typography

Styles are defined in `lib/config/app_text_styles.dart`. All text in the app must use a style from `AppTextStyles`. Do not construct `TextStyle` objects inline in widgets.

### Fonts

Both fonts are loaded at runtime via the `google_fonts` package — no local font assets are bundled.

| Font | Role |
|---|---|
| **Space Grotesk** | Headings, titles, prices, section headers |
| **Inter** | Body text, labels, navigation, chips |

Inter is applied to the entire Material `textTheme` as the base. Space Grotesk is applied selectively where its geometric, technical character reinforces the design — headings, numeric data, and section labels.

### Named styles

All styles are static methods on `AppTextStyles` that accept `BuildContext` to pull the current `colorScheme`.

| Method | Font | Size token | Weight | Letter spacing | Color |
|---|---|---|---|---|---|
| `heading()` | Space Grotesk | `font2xl` (24px) | 600 | −0.5 | `onSurface` |
| `title()` | Space Grotesk | `fontXl` (20px) | 600 | −0.5 | `onSurface` |
| `priceLarge()` | Space Grotesk | `fontXl` (20px) | 700 | — | `onSurface` + tabular figures |
| `priceMedium()` | Space Grotesk | `fontLg` (16px) | 700 | — | `onSurface` + tabular figures |
| `priceSmall()` | Space Grotesk | `fontMd` (14px) | 700 | — | `onSurface` + tabular figures |
| `sectionHeader()` | Space Grotesk | `fontSm` (12px) | 600 | 1.5 | `onSurface` @ 60% opacity |
| `body()` | Inter | `fontMd` (14px) | 400 | — | `onSurface` |
| `bodyMedium()` | Inter | `fontMd` (14px) | 500 | — | `onSurface` |
| `stationName()` | Inter | `fontMd` (14px) | 500 | — | `onSurface` |
| `label()` | Inter | `fontSm` (12px) | 400 | — | `onSurface` @ 60% opacity |
| `labelBold()` | Inter | `fontSm` (12px) | 500 | — | `onSurface` |
| `meta()` | Inter | `fontSm` (12px) | 400 | — | `onSurface` @ 60% opacity |
| `chipLabel()` | Inter | `fontSm` (12px) | 500 | — | `onSurface` |
| `navLabel()` | Inter | `fontXs` (10px) | 400 | — | `onSurface` @ 60% opacity |
| `navLabelActive()` | Inter | `fontXs` (10px) | 400 | — | `accent` (`#00D1FF`) |

`priceLarge`, `priceMedium`, and `priceSmall` use `FontFeature.tabularFigures()` so digits are fixed-width and prices align correctly in columns. Always use these styles for price values — do not use a generic style and add tabular figures manually.

`navLabelActive` is the only style with a hardcoded color. This is a known issue — it will be moved to `AppColors.accent` during the next refactor.

### Known inline violations

Several locations in the codebase still use raw `TextStyle()` calls that bypass this scale. These are pending cleanup:

| Size | Locations |
|---|---|
| `fontXs` (10px) | Nav animation, chart axis |
| `fontSm` (12px) | Map marker |
| `fontMd` (14px) | Manual crop screen |
| `fontLg` (16px) | Map screen |
| `fontXl` (20px) | Auth screen |

### Guidelines

- Always use `AppTextStyles` methods — never create raw `TextStyle()` instances in feature code
- Space Grotesk is for display/headlines and all numeric/price data
- Inter is for everything else: body, labels, metadata, UI chrome
- Muted text (`label`, `meta`, `navLabel`) uses `onSurface` at 60% opacity — this is baked into the named styles, do not set opacity manually on top of them
- To add a new style: add it to `AppTextStyles` first, never inline a one-off style in a widget

---

## Sizes & Spacing

All spacing, border radius, and font size values are defined in `lib/config/app_sizes.dart`. Never use hardcoded numeric values for layout — always reference a token from `AppSizes`.

The system uses a **4px base unit**. All spacing values are multiples of 4. There is no `space7` — the scale jumps from `space6` to `space8` because 28px had no consistent usage pattern in the codebase.

### Spacing

| Token | Value | Typical use |
|---|---|---|
| `space1` | 4px | Tight gaps between closely related elements |
| `space2` | 8px | Gaps within a component (icon + label, etc.) |
| `space3` | 12px | Padding inside compact components, button padding |
| `space4` | 16px | Standard card padding, screen horizontal margin |
| `space5` | 20px | Vertical section spacing |
| `space6` | 24px | Larger section gaps |
| `space8` | 32px | Major layout divisions |

`screenPadding` is a named alias for `space4` (16px). Use `screenPadding` specifically for the horizontal margin on screen-level layouts, and `space4` elsewhere. This makes intent clear at the call site.

### Border radius

| Token | Value | Typical use |
|---|---|---|
| `radiusXs` | 4px | Subtle rounding on small inline elements |
| `radiusSm` | 8px | Filter chips, small cards |
| `radiusMd` | 12px | Default — buttons, inputs, dialogs (theme default) |
| `radiusLg` | 16px | Price cards, larger surface containers |
| `radiusXl` | 20px | Bottom sheet top corners |
| `radiusFull` | 100px | Pill shapes (nav bar, fully rounded buttons) |

### Font sizes

| Token | Value |
|---|---|
| `fontXs` | 10px |
| `fontSm` | 12px |
| `fontMd` | 14px |
| `fontLg` | 16px |
| `fontXl` | 20px |
| `font2xl` | 24px |
| `font3xl` | 32px |

---

## Component conventions

### Cards

- Background: `AppColors.surface(context)`
- Border radius: `AppSizes.radiusLg` (16px)
- Elevation: 0 (flat, no shadow)
- Padding: `AppSizes.space4` (16px) on all sides

### Buttons

Buttons use the theme defaults defined in `AppTheme`. Do not override button styles inline.

- `FilledButton` — primary actions
- `OutlinedButton` — secondary actions
- Border radius: `AppSizes.radiusMd` (12px)
- Padding: `EdgeInsets.symmetric(horizontal: AppSizes.space6, vertical: AppSizes.space3)`

### Bottom sheets

- Top corner radius: `AppSizes.radiusXl` (20px) via `BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl))`
- Drag handle uses `AppSizes.radiusXs`

### Dividers

- Color: `AppColors.border(context)`
- Thickness: 0.5px

---

## Proposing design changes

The design system is open to evolution, but changes must be deliberate and consistent.

To propose a change:

1. Open a GitHub issue describing the change and the reason for it
2. Include before/after visuals if the change is visual
3. Tag the main contributors for review
4. Changes to `AppColors`, `AppTextStyles`, or `AppSizes` require approval before implementation
5. Once approved, update the tokens and this document in the same PR as the implementation

Do not introduce new colors, fonts, or size values directly in widget code. If the existing tokens don't cover your use case, raise it as a design question first.
