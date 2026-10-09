import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/pilates_loading_indicator.dart';
import '../data/booking_gateway.dart';

class MyPrivateLessonsPage extends StatefulWidget {
  const MyPrivateLessonsPage({super.key, required this.bookings});

  final BookingGateway bookings;

  @override
  State<MyPrivateLessonsPage> createState() => _MyPrivateLessonsPageState();
}

class _MyPrivateLessonsPageState extends State<MyPrivateLessonsPage> {
  late Future<List<MemberPrivateLesson>> _lessons = _load();

  Future<List<MemberPrivateLesson>> _load() =>
      widget.bookings.loadMyPrivateLessons();

  Future<void> _refresh() async {
    setState(() => _lessons = _load());
    await _lessons;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('myPrivateLessons'))),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<MemberPrivateLesson>>(
          future: _lessons,
          builder: (context, snapshot) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            children: [
              Text(strings.text('myPrivateLessons'),
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(strings.text('myPrivateLessonsSubtitle'),
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 28),
              if (snapshot.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: PilatesLoadingIndicator()),
                )
              else if (snapshot.hasError)
                _PrivateLessonNotice(
                  icon: Icons.cloud_off_outlined,
                  text: strings.text('myPrivateLessonsLoadError'),
                )
              else if (snapshot.data!.isEmpty)
                _PrivateLessonNotice(
                  icon: Icons.event_available_outlined,
                  text: strings.text('noMyPrivateLessons'),
                )
              else
                ...snapshot.data!.map(
                  (lesson) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _MemberPrivateLessonCard(lesson: lesson),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberPrivateLessonCard extends StatelessWidget {
  const _MemberPrivateLessonCard({required this.lesson});

  final MemberPrivateLesson lesson;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final approved = lesson.status == 'approved';
    final rejected = lesson.status == 'rejected';
    final color = approved
        ? const Color(0xFFE6F0E6)
        : rejected
            ? const Color(0xFFF7E9E7)
            : const Color(0xFFFFF4E1);
    final icon = approved
        ? Icons.check_circle_outline
        : rejected
            ? Icons.cancel_outlined
            : Icons.hourglass_top_outlined;
    final iconColor = rejected ? const Color(0xFFA64840) : AppTheme.sage;
    final status = approved
        ? strings.text('approved')
        : rejected
            ? strings.text('declined')
            : lesson.status == 'cancelled'
                ? strings.text('cancelled')
                : strings.text('pending');
    final local = MaterialLocalizations.of(context);
    final time = '${_clock(lesson.startsAt)} – ${_clock(lesson.endsAt)}';

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 54,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${lesson.startsAt.day}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                Text(_month(lesson.startsAt.month, strings),
                    style: const TextStyle(
                      color: AppTheme.sage,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(strings.text('privateLesson'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 7),
                Text(local.formatMediumDate(lesson.startsAt)),
                const SizedBox(height: 3),
                Text(time,
                    style: const TextStyle(
                        color: AppTheme.sage, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(status,
                    style: TextStyle(
                        color: iconColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  static String _clock(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  static String _month(int month, AppLocalizations strings) =>
      strings.text('month$month');
}

class _PrivateLessonNotice extends StatelessWidget {
  const _PrivateLessonNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(children: [
          Icon(icon, size: 42, color: AppTheme.sage),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ]),
      );
}
