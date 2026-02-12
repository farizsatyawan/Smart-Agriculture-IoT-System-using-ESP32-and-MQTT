
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SensorChart extends StatelessWidget {
  final String title;
  final List<double> dataPoints;
  final Color color;

  const SensorChart({
    Key? key,
    required this.title,
    required this.dataPoints,
    this.color = Colors.green, // default warna hijau
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          height: 200, // tinggi tetap agar layout aman
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: dataPoints.isEmpty
                        ? 100
                        : dataPoints.reduce((a, b) => a > b ? a : b) + 10,
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          dataPoints.length,
                          (index) => FlSpot(index.toDouble(), dataPoints[index]),
                        ),
                        isCurved: true,
                        barWidth: 3,
                        color: color, // gunakan 'color' versi lama
                        dotData: FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}