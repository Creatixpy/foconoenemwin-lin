import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../shared/models/user_statistics.dart';

class CompetenceChart extends StatelessWidget {
  const CompetenceChart({super.key, required this.stats});

  final UserStatistics stats;

  @override
  Widget build(BuildContext context) {
    final values = [
      stats.mediaCompetencia1 ?? 0,
      stats.mediaCompetencia2 ?? 0,
      stats.mediaCompetencia3 ?? 0,
      stats.mediaCompetencia4 ?? 0,
      stats.mediaCompetencia5 ?? 0,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Média por competência',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: 200,
                  gridData: FlGridData(show: true, horizontalInterval: 50),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('C${value.toInt() + 1}'),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 50,
                      ),
                    ),
                  ),
                  barGroups: List.generate(values.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: values[index],
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
