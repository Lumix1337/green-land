class EnergySavingsModel {
  final double dailyBaselineKwh;
  final double dailyOptimizedKwh;
  final double dailyBaselineCostTenge;
  final double dailyOptimizedCostTenge;
  final double dailySavedTenge;
  final double monthlySavedTenge;
  final double monthlySavedKwh;
  final double savingsPercentage;
  final double nightShiftRatio;
  final bool isNightTariffActive;

  const EnergySavingsModel({
    required this.dailyBaselineKwh,
    required this.dailyOptimizedKwh,
    required this.dailyBaselineCostTenge,
    required this.dailyOptimizedCostTenge,
    required this.dailySavedTenge,
    required this.monthlySavedTenge,
    required this.monthlySavedKwh,
    required this.savingsPercentage,
    required this.nightShiftRatio,
    required this.isNightTariffActive,
  });

  factory EnergySavingsModel.initial() {
    return const EnergySavingsModel(
      dailyBaselineKwh: 156.0,
      dailyOptimizedKwh: 134.9,
      dailyBaselineCostTenge: 3771.30,
      dailyOptimizedCostTenge: 2164.34,
      dailySavedTenge: 1606.96,
      monthlySavedTenge: 48200.0,
      monthlySavedKwh: 633.0,
      savingsPercentage: 42.6,
      nightShiftRatio: 0.72,
      isNightTariffActive: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_baseline_kwh': dailyBaselineKwh,
      'daily_optimized_kwh': dailyOptimizedKwh,
      'daily_baseline_cost_kzt': dailyBaselineCostTenge,
      'daily_optimized_cost_kzt': dailyOptimizedCostTenge,
      'daily_saved_kzt': dailySavedTenge,
      'monthly_saved_kzt': monthlySavedTenge,
      'monthly_saved_kwh': monthlySavedKwh,
      'savings_percentage': savingsPercentage,
      'night_shift_ratio': nightShiftRatio,
      'is_night_tariff_now': isNightTariffActive,
    };
  }

  factory EnergySavingsModel.fromJson(Map<String, dynamic> json) {
    return EnergySavingsModel(
      dailyBaselineKwh: (json['daily_baseline_kwh'] as num?)?.toDouble() ?? 156.0,
      dailyOptimizedKwh: (json['daily_optimized_kwh'] as num?)?.toDouble() ?? 134.9,
      dailyBaselineCostTenge: (json['daily_baseline_cost_kzt'] as num?)?.toDouble() ?? 3771.30,
      dailyOptimizedCostTenge: (json['daily_optimized_cost_kzt'] as num?)?.toDouble() ?? 2164.34,
      dailySavedTenge: (json['daily_saved_kzt'] as num?)?.toDouble() ?? 1606.96,
      monthlySavedTenge: (json['monthly_saved_kzt'] as num?)?.toDouble() ?? 48200.0,
      monthlySavedKwh: (json['monthly_saved_kwh'] as num?)?.toDouble() ?? 633.0,
      savingsPercentage: (json['savings_percentage'] as num?)?.toDouble() ?? 42.6,
      nightShiftRatio: (json['night_shift_ratio'] as num?)?.toDouble() ?? 0.72,
      isNightTariffActive: json['is_night_tariff_now'] as bool? ?? false,
    );
  }
}
