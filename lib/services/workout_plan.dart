// Goals the user can pick during onboarding, and the workouts each goal maps
// to. Selecting multiple goals merges their workouts into one plan.

class Exercise {
  const Exercise(this.name, this.detail, this.points);
  final String name, detail;
  final int points;
}

const kAllGoals = [
  'Lose Weight',
  'Build Muscle',
  'Improve Endurance',
  'Increase Strength',
  'Boost Flexibility',
  'Stay Healthy',
];

const _loseWeight = [
  Exercise('Jump rope intervals', '5 rounds × 60s on / 30s rest', 45),
  Exercise('Mountain climbers', '4 sets × 40s (fast tempo)', 40),
  Exercise('Incline treadmill walk', '20 min at 8–12% incline', 35),
];

const _buildMuscle = [
  Exercise('Bulgarian split squat', '3–4 sets × 8–12 reps per leg (90–120s rest)', 50),
  Exercise('Dumbbell floor press', '3–4 sets × 10–15 reps (1–2 reps from failure)', 60),
  Exercise('Single-leg deadlift', '3–4 sets × 8–12 reps per leg (90s rest)', 55),
];

const _endurance = [
  Exercise('Zone 2 run', '30–40 min at a conversational pace', 50),
  Exercise('Cycling intervals', '6 × 3 min hard / 2 min easy', 55),
  Exercise('Rowing pyramid', '250m, 500m, 750m, 500m, 250m', 45),
];

const _strength = [
  Exercise('Barbell back squat', '5 sets × 5 reps (3 min rest)', 70),
  Exercise('Deadlift', '4 sets × 5 reps (progressive load)', 75),
  Exercise('Weighted pull-up', '4 sets × 5–8 reps', 65),
];

const _flexibility = [
  Exercise('World\'s greatest stretch', '3 rounds × 5 reps per side', 25),
  Exercise('Couch stretch', '2 min hold per leg', 20),
  Exercise('Cat-cow + thoracic rotations', '3 sets × 10 reps', 20),
];

const _stayHealthy = [
  Exercise('Brisk walk', '8,000–10,000 steps across the day', 30),
  Exercise('Full-body mobility flow', '10 min morning routine', 25),
  Exercise('Inverted row', '3–4 sets × 8–12 reps (90s rest)', 65),
];

const Map<String, List<Exercise>> kGoalWorkouts = {
  'Lose Weight': _loseWeight,
  'Build Muscle': _buildMuscle,
  'Improve Endurance': _endurance,
  'Increase Strength': _strength,
  'Boost Flexibility': _flexibility,
  'Stay Healthy': _stayHealthy,
};

/// The merged, de-duplicated workout list for the user's chosen goals. Falls
/// back to a balanced default when no goals are set.
List<Exercise> recommendedWorkouts(List<String> goals) {
  final chosen = goals.where(kGoalWorkouts.containsKey);
  if (chosen.isEmpty) return [..._stayHealthy, ..._buildMuscle.take(1)];
  final seen = <String>{};
  final out = <Exercise>[];
  for (final g in chosen) {
    for (final e in kGoalWorkouts[g]!) {
      if (seen.add(e.name)) out.add(e);
    }
  }
  return out;
}
