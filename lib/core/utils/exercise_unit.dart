bool isTimedExercise({required String exerciseName, String? exerciseId}) {
  final normalizedId = (exerciseId ?? '').trim().toLowerCase();
  const timedExerciseIds = <String>{
    'plank',
    'side_plank',
    'support_hold_parallel_bar',
    'chin_up_hold_top',
    'pull_up_hold_top',
    'l_sit_hold',
    'tuck_front_lever',
    'tuck_planche',
    'wall_sit',
    'hollow_body_hold',
  };

  if (timedExerciseIds.contains(normalizedId)) {
    return true;
  }

  final normalizedName = exerciseName
      .trim()
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  const timedKeywords = <String>[
    ' hold',
    'plank',
    'wall sit',
    'tuck front lever',
    'tuck planche',
  ];

  for (final keyword in timedKeywords) {
    if (normalizedName.contains(keyword)) {
      return true;
    }
  }

  return normalizedName.endsWith('hold');
}
