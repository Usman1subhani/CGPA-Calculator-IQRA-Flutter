import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_info.dart';
import '../app_state.dart';
import '../models/history_entry.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'cgpa_screen.dart';
import 'gpa_screen.dart';

void _openEntry(BuildContext context, HistoryEntry entry) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => entry.type == HistoryType.gpa
          ? GpaScreen(existingEntry: entry)
          : CgpaScreen(existingEntry: entry),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  final VoidCallback onOpenGpa;
  final VoidCallback onOpenCgpa;
  final VoidCallback onOpenHistory;

  const HomeScreen({
    super.key,
    required this.onOpenGpa,
    required this.onOpenCgpa,
    required this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppInfo.appNameShort)),
      body: RefreshIndicator(
        onRefresh: state.reloadHistory,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            _Hero(state: state),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.calculate_rounded,
                    label: 'GPA\nCalculator',
                    color: AppColors.primary,
                    onTap: onOpenGpa,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.stacked_line_chart_rounded,
                    label: 'CGPA\nCalculator',
                    color: AppColors.accent,
                    onTap: onOpenCgpa,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent History', style: theme.textTheme.titleMedium),
                TextButton(
                  onPressed: onOpenHistory,
                  child: const Text('See all'),
                ),
              ],
            ),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.history.isEmpty)
              const EmptyState(
                icon: Icons.history_rounded,
                title: 'No calculations yet',
                subtitle: 'Your GPA and CGPA history will show up here.',
              )
            else
              ...state.history
                  .take(5)
                  .map(
                    (e) => HistoryTile(
                      entry: e,
                      onDelete: () => state.deleteHistory(e.id),
                      onTap: () => _openEntry(context, e),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final AppState state;
  const _Hero({required this.state});

  @override
  Widget build(BuildContext context) {
    final overall = state.latestCgpa;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back 👋',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            AppInfo.appName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (overall != null)
            Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.accentLight,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Overall CGPA: ${overall.value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            )
          else
            const Text(
              'Calculate your first GPA or CGPA below.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
