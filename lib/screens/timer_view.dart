import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../main.dart' show kBrand, kCard, kCard2;
import '../models.dart';

String fmt(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}

String fmtMs(int ms) => fmt(Duration(milliseconds: ms));

class TimerView extends StatelessWidget {
  const TimerView({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final user = st.user!;
    final baseMs = user.dayLog?.studyMs ?? 0;
    final liveMs = baseMs + (st.studying ? st.elapsed.inMilliseconds : 0);
    final active = st.activeSubject;
    final ringColor = active?.color ?? kBrand;
    // 진행 중이면 1분 주기로 채워지는 링, 아니면 비움
    final progress = st.studying ? (st.elapsed.inSeconds % 60) / 60.0 : 0.0;

    return Column(
      children: [
        const SizedBox(height: 24),
        // 원형 타이머
        SizedBox(
          width: 250,
          height: 250,
          child: CustomPaint(
            painter: _RingPainter(progress: progress, color: ringColor),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("TODAY",
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(fmtMs(liveMs),
                      style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1,
                          fontFeatures: [FontFeature.tabularFigures()])),
                  const SizedBox(height: 8),
                  if (active != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: ringColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(active.title,
                          style: TextStyle(
                              color: ringColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    )
                  else
                    Text("Tap a subject to start",
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (st.studying)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: ringColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            onPressed:
                st.timerLoading ? null : () => context.read<AppState>().stopTimer(),
            icon: st.timerLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.stop_rounded),
            label: const Text('STOP',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          )
        else
          const SizedBox(height: 44),
        if (st.timerErrorText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              st.timerErrorText!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
        const SizedBox(height: 20),
        // 과목 카드 리스트
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: user.subjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _SubjectCard(subject: user.subjects[i]),
          ),
        ),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final s = subject;
    final active = st.activeSubject?.id == s.id;
    final disabled = st.timerLoading;
    final today = st.subjectTimes[s.title] ?? 0; // /logs/day 의 과목별 오늘 시간
    final liveMs = today + (active ? st.elapsed.inMilliseconds : 0);

    void toggle() {
      final app = context.read<AppState>();
      if (active) {
        app.stopTimer();
      } else {
        app.startTimer(s);
      }
    }

    return Opacity(
      opacity: disabled && !active ? 0.55 : 1,
      child: Material(
        color: active ? kCard2 : kCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: disabled ? null : toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: active
                  ? Border.all(
                      color: s.color.withValues(alpha: 0.6), width: 1.4)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: s.color.withValues(alpha: 0.18),
                      shape: BoxShape.circle),
                  child: Icon(
                      active ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: s.color,
                      size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(s.title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              active ? FontWeight.bold : FontWeight.w500)),
                ),
                Text(fmtMs(liveMs),
                    style: TextStyle(
                        color: active ? s.color : Colors.grey[500],
                        fontWeight:
                            active ? FontWeight.bold : FontWeight.normal,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, track);

    if (progress > 0) {
      final arc = Paint()
        ..color = color // 단색 (그라데이션 제거)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2, 2 * math.pi * progress, false, arc);
    } else {
      final dot = Paint()..color = color.withValues(alpha: 0.4);
      canvas.drawCircle(
          Offset(center.dx, center.dy - radius), 5, dot);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
