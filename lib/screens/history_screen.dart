import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/history_entry.dart';
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

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _confirmClear(AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'This will permanently delete every saved GPA and CGPA calculation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) await state.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'GPA'),
            Tab(text: 'CGPA'),
          ],
        ),
        actions: [
          if (state.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(state),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _List(entries: state.history, state: state),
                _List(entries: state.gpaHistory, state: state),
                _List(entries: state.cgpaHistory, state: state),
              ],
            ),
    );
  }
}

class _List extends StatelessWidget {
  final List<HistoryEntry> entries;
  final AppState state;
  const _List({required this.entries, required this.state});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'Nothing here yet',
        subtitle: 'Calculations you save will appear in this list.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return HistoryTile(
          entry: e,
          onDelete: () => deleteHistoryWithUndo(
            context,
            entry: e,
            delete: () => state.deleteHistory(e.id),
            restore: state.restoreHistory,
          ),
          onTap: () => _openEntry(context, e),
        );
      },
    );
  }
}
