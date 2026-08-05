/// A user's health goals / conditions, used to judge whether a food fits.
///
/// Distinct from [FuelGoal] (which only tunes calorie targets): these drive the
/// "can I eat this?" verdict on a snapped meal or scanned product. A user can
/// hold several at once — diabetic *and* pregnant, say.
library;

enum HealthGoal {
  weightLoss('Weight loss', 'Leaner meals, lighter on calories'),
  weightGain('Weight gain', 'Calorie-dense foods are on your side'),
  diabetes('Diabetes', 'Keep sugar and fast carbs in check'),
  pregnancy('Pregnancy', 'Avoid alcohol, limit caffeine, skip unsafe foods'),
  heartHealth('Heart health', 'Watch saturated fat and sodium'),
  lowSodium('Low sodium', 'Keep salt down');

  const HealthGoal(this.label, this.blurb);

  final String label;
  final String blurb;

  static HealthGoal? byNameOrNull(String s) {
    for (final g in values) {
      if (g.name == s) return g;
    }
    return null;
  }
}

/// The user's selected goals plus any free-text conditions they typed. Parsed
/// from and serialized to settings.
class HealthProfile {
  const HealthProfile({this.goals = const {}, this.conditionsNote = ''});

  final Set<HealthGoal> goals;

  /// Anything not covered by the preset goals (e.g. "gluten intolerance"),
  /// shown to the AI paths for a richer read.
  final String conditionsNote;

  bool get isEmpty => goals.isEmpty && conditionsNote.trim().isEmpty;

  static const goalsKey = 'health_goals';
  static const noteKey = 'health_conditions_note';

  factory HealthProfile.fromSettings(String? Function(String) get) {
    final raw = get(goalsKey) ?? '';
    final goals = <HealthGoal>{
      for (final part in raw.split(',')) ?HealthGoal.byNameOrNull(part.trim()),
    };
    return HealthProfile(
      goals: goals,
      conditionsNote: get(noteKey) ?? '',
    );
  }

  Map<String, String> toSettings() => {
        goalsKey: goals.map((g) => g.name).join(','),
        noteKey: conditionsNote.trim(),
      };
}
