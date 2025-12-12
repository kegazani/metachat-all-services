class ProfileProgress {
  final int tokensAnalyzed;
  final int tokensRequiredForFirst;
  final int tokensRequiredForRecalc;
  final int daysSinceLastCalc;
  final int daysUntilRecalc;
  final bool isFirstCalculation;
  final double progressPercentage;

  ProfileProgress({
    required this.tokensAnalyzed,
    required this.tokensRequiredForFirst,
    required this.tokensRequiredForRecalc,
    required this.daysSinceLastCalc,
    required this.daysUntilRecalc,
    required this.isFirstCalculation,
    required this.progressPercentage,
  });

  factory ProfileProgress.fromJson(Map<String, dynamic> json) {
    return ProfileProgress(
      tokensAnalyzed: json['tokens_analyzed'] as int? ?? 0,
      tokensRequiredForFirst: json['tokens_required_for_first'] as int? ?? 50,
      tokensRequiredForRecalc: json['tokens_required_for_recalc'] as int? ?? 100,
      daysSinceLastCalc: json['days_since_last_calc'] as int? ?? 0,
      daysUntilRecalc: json['days_until_recalc'] as int? ?? 0,
      isFirstCalculation: json['is_first_calculation'] as bool? ?? true,
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tokens_analyzed': tokensAnalyzed,
      'tokens_required_for_first': tokensRequiredForFirst,
      'tokens_required_for_recalc': tokensRequiredForRecalc,
      'days_since_last_calc': daysSinceLastCalc,
      'days_until_recalc': daysUntilRecalc,
      'is_first_calculation': isFirstCalculation,
      'progress_percentage': progressPercentage,
    };
  }
}

