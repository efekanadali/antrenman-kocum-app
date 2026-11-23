// lib/domain/enums/exercise_type.dart

/// MLI hesaplamasında kullanılacak formül ailesi.
enum ExerciseType {
  /// Vücut ağırlığı (kalistenik):
  /// `MLI = Hacim × Lf × RIR_faktörü × (1 + Ek_Ağırlık / Vücut_Ağırlığı)`
  calisthenics,

  /// Serbest ağırlık / makine (vücut geliştirme):
  /// `MLI = Hacim × (Kaldırılan_Ağırlık / Vücut_Ağırlığı) × Lf_bb × RIR_faktörü`
  bodybuilding,
}
