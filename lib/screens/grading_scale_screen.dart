import 'package:flutter/material.dart';
import '../data/grading_data.dart';
import '../widgets/screen_header.dart';

void openGradingScaleReference(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const GradingScaleScreen()));
}

class GradingScaleScreen extends StatelessWidget {
  const GradingScaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Grading Scale')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          const ScreenHeader(
            title: 'Iqra University grading scales',
            subtitle:
                'Choose the table that matches your admission batch. This independent app is not affiliated with or endorsed by Iqra University.',
          ),
          for (final scale in GradingScale.values) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                scale.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (index, band) in GradingData.gradeBandsFor(
                    scale,
                  ).indexed)
                    Column(
                      children: [
                        ListTile(
                          title: Text(
                            band.grade,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            band.minPercent == 0
                                ? 'Below ${GradingData.passingPercentFor(scale)}%'
                                : '${band.minPercent.toInt()}–${band.maxPercent.toInt()}%',
                          ),
                          trailing: Text(
                            band.gradePoint.toStringAsFixed(2),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (index < GradingData.gradeBandsFor(scale).length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          Text(
            'Quality points = grade point × course credit hours. GPA and CGPA are displayed truncated to two decimal places.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Source: Iqra University Undergraduate Handbook, version 14.0.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
