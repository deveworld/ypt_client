import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../main.dart' show kBrand, kCard;
import 'timer_view.dart' show fmtMs;

class GroupRoomScreen extends StatefulWidget {
  final Group group;
  const GroupRoomScreen({super.key, required this.group});
  @override
  State<GroupRoomScreen> createState() => _GroupRoomScreenState();
}

class _GroupRoomScreenState extends State<GroupRoomScreen> {
  late Future<List<GroupMember>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppState>().fetchMembers(widget.group.id);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Scaffold(
      appBar: AppBar(title: Text(g.title)),
      body: Column(
        children: [
          // 그룹 헤더
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: kCard, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                      color: kBrand.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.groups_rounded,
                      color: kBrand, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      if (g.slogan.isNotEmpty)
                        Text(g.slogan,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${g.category} · ${g.memberCount} members · owner ${g.owner}',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Members',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<GroupMember>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final members = [...snap.data!]
                  ..sort((a, b) => b.studyMs.compareTo(a.studyMs));
                if (members.isEmpty) {
                  return Center(
                      child: Text('No members visible (private group)',
                          style: TextStyle(color: Colors.grey[600])));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = members[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: kBrand.withValues(alpha: 0.2),
                            child: Text(
                                m.nickname.isNotEmpty
                                    ? m.nickname.characters.first
                                    : '?',
                                style: const TextStyle(color: kBrand)),
                          ),
                          if (m.studying)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: const Color(0xFF0D0D0F), width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(m.nickname,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(m.category,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12)),
                      trailing: Text(fmtMs(m.studyMs),
                          style: const TextStyle(
                              color: Colors.grey,
                              fontFeatures: [FontFeature.tabularFigures()])),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
