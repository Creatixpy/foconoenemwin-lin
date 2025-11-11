import 'package:flutter/material.dart';

import '../../shared/models/user_statistics.dart';

class DisciplineProgress extends StatelessWidget {
  const DisciplineProgress({super.key, required this.stats});

  final UserStatistics stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _DisciplineData(
        label: 'Matemática',
        correct: stats.acertosMatematica,
        total: stats.totalMatematica,
        color: Colors.blueAccent,
      ),
      _DisciplineData(
        label: 'Português',
        correct: stats.acertosPortugues,
        total: stats.totalPortugues,
        color: Colors.purpleAccent,
      ),
      _DisciplineData(
        label: 'Química',
        correct: stats.acertosQuimica,
        total: stats.totalQuimica,
        color: Colors.orangeAccent,
      ),
      _DisciplineData(
        label: 'Física',
        correct: stats.acertosFisica,
        total: stats.totalFisica,
        color: Colors.greenAccent,
      ),
      _DisciplineData(
        label: 'Geografia',
        correct: stats.acertosGeografia,
        total: stats.totalGeografia,
        color: Colors.tealAccent,
      ),
    ].where((item) => item.total > 0).toList();

    if (items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Faça um simulado para liberar o comparativo por disciplina.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Desempenho por disciplina',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            for (final item in items) ...[
              _DisciplineProgressBar(data: item),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _DisciplineData {
  const _DisciplineData({
    required this.label,
    required this.correct,
    required this.total,
    required this.color,
  });

  final String label;
  final int correct;
  final int total;
  final Color color;

  double get percent => total == 0 ? 0 : correct / total;
}

class _DisciplineProgressBar extends StatelessWidget {
  const _DisciplineProgressBar({required this.data});
  final _DisciplineData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(data.label, style: Theme.of(context).textTheme.bodyMedium),
            Text('${(data.percent * 100).toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: data.percent,
          minHeight: 10,
          borderRadius: BorderRadius.circular(8),
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation(data.color),
        ),
        Text(
          '${data.correct}/${data.total} questões',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
