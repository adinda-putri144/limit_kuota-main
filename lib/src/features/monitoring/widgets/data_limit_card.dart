import 'package:flutter/material.dart';

class DataLimitCard extends StatelessWidget {
  final double usedMb;
  final double limitMb;

  const DataLimitCard({
    super.key,
    required this.usedMb,
    required this.limitMb,
  });

  @override
  Widget build(BuildContext context) {
    final double percent =
        (limitMb == 0 ? 0 : (usedMb / limitMb)).clamp(0.0, 1.0).toDouble();

    final double remaining =
        (limitMb - usedMb).clamp(0.0, limitMb).toDouble();

    Color progressColor;
    if (percent >= 0.8) {
      progressColor = Colors.red;
    } else if (percent >= 0.5) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Limit Kuota Bulanan",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              color: progressColor,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              "Terpakai: ${usedMb.toStringAsFixed(2)} MB / ${limitMb.toStringAsFixed(0)} MB",
            ),
            Text(
              "Sisa kuota: ${remaining.toStringAsFixed(2)} MB",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}