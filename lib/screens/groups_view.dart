import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../main.dart' show kBrand, kCard;
import 'group_room_screen.dart';

class GroupsView extends StatefulWidget {
  const GroupsView({super.key});
  @override
  State<GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<GroupsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    return RefreshIndicator(
      onRefresh: () => context.read<AppState>().loadGroups(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (st.joinedGroups.isNotEmpty) ...[
            const _SectionTitle('My Groups'),
            ...st.joinedGroups.map((g) => _GroupCard(group: g, joined: true)),
            const SizedBox(height: 20),
          ],
          const _SectionTitle('Browse Groups'),
          if (st.groupsLoading && st.groups.isEmpty)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator()))
          else if (st.groups.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                  child: Text('No groups found',
                      style: TextStyle(color: Colors.grey[600]))),
            )
          else
            ...st.groups.map((g) => _GroupCard(group: g, joined: false)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
}

class _GroupCard extends StatelessWidget {
  final Group group;
  final bool joined;
  const _GroupCard({required this.group, required this.joined});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GroupRoomScreen(group: group))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: kBrand.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.groups_rounded, color: kBrand),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text(
                          '${group.category.isNotEmpty ? '${group.category} · ' : ''}'
                          'owner ${group.owner}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    Text('${group.memberCount}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
