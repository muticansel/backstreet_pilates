import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/pilates_loading_indicator.dart';
import '../data/booking_gateway.dart';

class UpcomingClassesPage extends StatefulWidget {
  const UpcomingClassesPage({super.key, required this.bookings});

  final BookingGateway bookings;

  @override
  State<UpcomingClassesPage> createState() => _UpcomingClassesPageState();
}

class _UpcomingClassesPageState extends State<UpcomingClassesPage> {
  late Future<List<ScheduledClass>> _classes =
      widget.bookings.loadUpcomingClasses();

  Future<void> _refresh() async {
    setState(() => _classes = widget.bookings.loadUpcomingClasses());
    await _classes;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<ScheduledClass>>(
        future: _classes,
        builder: (context, snapshot) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
          children: [
            Text(strings.text('myClasses'),
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(strings.text('myClassesSubtitle'),
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 28),
            if (snapshot.connectionState != ConnectionState.done)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: PilatesLoadingIndicator()),
              )
            else if (snapshot.hasError)
              _EmptyState(
                icon: Icons.cloud_off_outlined,
                message: strings.text('classesLoadError'),
              )
            else if (snapshot.data!.isEmpty)
              _EmptyState(
                icon: Icons.event_available_outlined,
                message: strings.text('noUpcomingClasses'),
              )
            else
              ...snapshot.data!.map(
                (scheduledClass) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ClassCard(scheduledClass: scheduledClass),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              strings.text('classChangesLater'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.sage),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.scheduledClass});

  final ScheduledClass scheduledClass;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final date = scheduledClass.startsAt;
    final time = '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8DED5)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE3E9DD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${date.day}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                Text(_month(date.month, strings),
                    style: const TextStyle(
                        color: AppTheme.sage,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scheduledClass.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${scheduledClass.branchName} · $time'),
                const SizedBox(height: 7),
                Text(strings.text('reserved'),
                    style: const TextStyle(
                        color: AppTheme.sage,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  static String _month(int month, AppLocalizations strings) =>
      strings.text('month$month');
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.sage, size: 42),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      );
}
