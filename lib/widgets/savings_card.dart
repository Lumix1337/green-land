import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class SavingsCard extends StatelessWidget {
  final double monthlySavedTenge;
  final double dayTariff;
  final double nightTariff;
  final String title;
  final String dayTariffLabel;
  final String nightTariffLabel;

  const SavingsCard({
    super.key,
    required this.monthlySavedTenge,
    required this.dayTariff,
    required this.nightTariff,
    required this.title,
    required this.dayTariffLabel,
    required this.nightTariffLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset('assets/figma/energy.png',
                  width: 160, height: 144),
            ),
            Container(
              constraints: const BoxConstraints(
                  minHeight: 144, minWidth: double.infinity),
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                      '₸${NumberFormat.decimalPattern('en').format(monthlySavedTenge.round())}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 35,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text(
                          '$dayTariffLabel ₸${dayTariff.toStringAsFixed(2)}/kWh',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                      Text(
                          '$nightTariffLabel ₸${nightTariff.toStringAsFixed(2)}/kWh',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
