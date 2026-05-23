// Design tokens: spacing for Chargix (4dp baseline grid).
//
// Use named scale tokens or semantic aliases instead of raw numbers so
// density can be tuned app-wide.

/// Spacing and inset tokens derived from a **4 logical-pixel baseline grid**.
///
/// Scale names follow t-shirt sizing. Values that are not an integer
/// multiple of [grid] are documented inline (micro-rhythm gaps).
abstract final class AppSpacing {
  /// Baseline unit (Material default). All scale tokens are `grid × n`
  /// unless noted.
  static const double grid = 4;

  // --- Core scale (multiples of [grid] where possible) ---

  /// `1 × grid` — hairline / dense stacks.
  static const double xxxs = grid;

  /// `2 × grid`
  static const double xxs = grid * 2;

  /// **6dp** — micro gap (1.5 × grid) for icon–label pairs and helper text.
  static const double xs = 6;

  /// `3 × grid`
  static const double sm = grid * 3;

  /// `4 × grid`
  static const double md = grid * 4;

  /// `5 × grid`
  static const double mdL = grid * 5;

  /// `6 × grid`
  static const double lg = grid * 6;

  /// `8 × grid`
  static const double xl = grid * 8;

  /// `10 × grid`
  static const double xxl = grid * 10;

  /// `12 × grid` — large section breaks, hero spacing.
  static const double xxxl = grid * 12;

  // --- Semantic aliases (compose screens from these when possible) ---

  /// Standard horizontal inset for full-width scroll views.
  static const double screenGutter = lg;

  /// Standard vertical padding for screen headers / footers.
  static const double screenVertical = md;

  /// Space between titled sections on settings-like pages.
  static const double sectionTitleGap = sm;

  /// Default inner padding for grouped list “premium” cards.
  static const double cardGroupPadding = sm;

  /// Edge insets for `InputDecoration` content (matches theme).
  static const double inputContentInset = md;
}
