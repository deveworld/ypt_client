import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'timer_view.dart';
import 'stats_view.dart';
import 'groups_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final user = st.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'YPT · ${user.nickname}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Center(child: _CategoryPill(user.category)),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AppState>().logout(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [TimerView(), StatsView(), GroupsView()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer),
              label: 'Timer'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Stats'),
          NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'Groups'),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String category;
  const _CategoryPill(this.category);

  @override
  Widget build(BuildContext context) {
    final label = category.isEmpty ? '—' : category;
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = (width * 0.45).clamp(160.0, 360.0);
    final scheme = Theme.of(context).colorScheme;
    // Container가 콘텐츠 너비에 맞춰 늘어나고, maxWidth 초과 시에만 말줄임.
    return Tooltip(
      message: label,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.55)),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
