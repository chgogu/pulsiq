/// Sweetness adjuster (spec §5): beverages over 15 g sugar (or flagged
/// "too sweet") earn a dilution / flavor-hack suggestion.
library;

const sweetnessThresholdG = 15;

bool isTooSweet(double sugarG, {bool userFlagged = false}) =>
    userFlagged || sugarG > sweetnessThresholdG;

String? sweetnessHack(
  String beverageName,
  double sugarG, {
  bool userFlagged = false,
}) {
  if (!isTooSweet(sugarG, userFlagged: userFlagged)) return null;
  final name = beverageName.trim().isEmpty ? 'That drink' : beverageName;
  return '$name is running sweet (${sugarG.round()} g). Cut it half-and-half '
      'with soda water or unsweetened tea — same flavor hit, half the sugar '
      'spike, steadier energy.';
}
