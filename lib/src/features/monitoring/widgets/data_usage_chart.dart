import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/data_usage_model.dart';

class DataUsageChart extends StatelessWidget {
  final List<DataUsage> data;

  const DataUsageChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("Tidak ada data"));
    }

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox();
                  }
                  return Text(data[index].day);
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              barWidth: 3,
              dotData: FlDotData(show: true),
              spots: List.generate(
                data.length,
                (i) => FlSpot(i.toDouble(), data[i].usageMb),
              ),
            ),
          ],
        ),
      ),
    );
  }
}