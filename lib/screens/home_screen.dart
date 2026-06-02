import 'dart:math' as math;
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
    final maxWidth = width >= 720
        ? 180.0
        : width >= 480
            ? 150.0
            : 128.0;
    final scheme = Theme.of(context).colorScheme;
    const textStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
    final textPainter = TextPainter(
      text: const TextSpan(style: textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..text = TextSpan(text: label, style: textStyle);
    textPainter.layout(maxWidth: maxWidth - 24);
    final pillWidth =
        math.min(maxWidth, math.max(46.0, textPainter.width + 24));

    return SizedBox(
      width: pillWidth,
      height: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.55)),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ),
      ),
    );
  }
}
