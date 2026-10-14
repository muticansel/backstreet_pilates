import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_snack_bars.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/pilates_loading_indicator.dart';
import '../data/booking_gateway.dart';

class PrivateLessonBookingPage extends StatefulWidget {
  const PrivateLessonBookingPage({super.key, required this.bookings});

  final BookingGateway bookings;

  @override
  State<PrivateLessonBookingPage> createState() =>
      _PrivateLessonBookingPageState();
}

class _PrivateLessonBookingPageState extends State<PrivateLessonBookingPage> {
  late DateTime _selectedDate = _today();
  late Future<List<PrivateLessonSlot>> _slots = _load();
  String? _requestingSlot;
  bool _availableOnly = false;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<List<PrivateLessonSlot>> _load() =>
      widget.bookings.loadPrivateLessonSlots(_selectedDate);

  Future<void> _chooseDate() async {
    final today = _today();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    setState(() {
      _selectedDate = date;
      _slots = _load();
    });
  }

  Future<void> _request(PrivateLessonSlot slot) async {
    setState(() => _requestingSlot = slot.startsAt.toIso8601String());
    try {
      await widget.bookings.requestPrivateLesson(slot.startsAt);
      if (!mounted) return;
      AppNotifications.success(
          AppLocalizations.of(context).text('privateLessonRequestSent'));
      setState(() {
        _slots = _load();
      });
    } catch (_) {
      if (mounted) {
        AppNotifications.error(
            AppLocalizations.of(context).text('privateLessonRequestError'));
        setState(() {
          _slots = _load();
        });
      }
    } finally {
      if (mounted) setState(() => _requestingSlot = null);
    }
  }

  void _showUnavailableReason(PrivateLessonSlot slot) {
    AppNotifications.error(AppLocalizations.of(context).text(
        slot.isDefaultClosed
            ? 'privateLessonDefaultClosedMessage'
            : 'privateLessonUnavailableMessage'));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('bookPrivateLesson'))),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {
          _slots = _load();
        }),
        child: FutureBuilder<List<PrivateLessonSlot>>(
          future: _slots,
          builder: (context, snapshot) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            children: [
              Text(strings.text('privateLessonBookingTitle'),
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(strings.text('privateLessonBookingDetail'),
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(MaterialLocalizations.of(context)
                    .formatMediumDate(_selectedDate)),
              ),
              const SizedBox(height: 18),
              if (snapshot.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: PilatesLoadingIndicator()),
                )
              else if (snapshot.hasError)
                _Notice(
                  icon: Icons.cloud_off_outlined,
                  text: strings.text('privateLessonSlotsLoadError'),
                )
              else ...[
                _Legend(strings: strings),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    selected: _availableOnly,
                    onSelected: (selected) =>
                        setState(() => _availableOnly = selected),
                    label: Text(strings.text('showAvailableTimesOnly')),
                    avatar: const Icon(Icons.filter_alt_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                _DailyTimeline(
                  slots: snapshot.data!,
                  requestingSlot: _requestingSlot,
                  availableOnly: _availableOnly,
                  onRequest: _request,
                  onUnavailable: _showUnavailableReason,
                  strings: strings,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.strings});
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.text('privateLessonTimeline'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(strings.text('privateLessonTimelineHint'),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          Row(children: [
            _LegendItem(
                color: const Color(0xFFE1EEE4),
                text: strings.text('available')),
            const SizedBox(width: 16),
            _LegendItem(
                color: const Color(0xFFECECE8),
                text: strings.text('unavailable')),
          ]),
        ],
      );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.text});
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ]);
}

class _DailyTimeline extends StatelessWidget {
  const _DailyTimeline({
    required this.slots,
    required this.requestingSlot,
    required this.availableOnly,
    required this.onRequest,
    required this.onUnavailable,
    required this.strings,
  });

  final List<PrivateLessonSlot> slots;
  final String? requestingSlot;
  final bool availableOnly;
  final ValueChanged<PrivateLessonSlot> onRequest;
  final ValueChanged<PrivateLessonSlot> onUnavailable;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final timelineSlots = slots
        .where((slot) => slot.startsAt.hour >= 5 && slot.startsAt.hour < 22)
        .where((slot) => !availableOnly || slot.isAvailable)
        .toList()
      ..sort((first, second) => first.startsAt.compareTo(second.startsAt));
    return SingleChildScrollView(
      key: const ValueKey('private-lesson-daily-timeline'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: timelineSlots
            .map((slot) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _TimelineSlot(
                    slot: slot,
                    requesting:
                        requestingSlot == slot.startsAt.toIso8601String(),
                    onRequest: onRequest,
                    onUnavailable: onUnavailable,
                    strings: strings,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _TimelineSlot extends StatelessWidget {
  const _TimelineSlot({
    required this.slot,
    required this.requesting,
    required this.onRequest,
    required this.onUnavailable,
    required this.strings,
  });

  final PrivateLessonSlot slot;
  final bool requesting;
  final ValueChanged<PrivateLessonSlot> onRequest;
  final ValueChanged<PrivateLessonSlot> onUnavailable;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final start = slot.startsAt;
    final end = start.add(const Duration(hours: 1));
    final time = '${_clock(start)} – ${_clock(end)}';
    final status = slot.isAvailable
        ? strings.text('available')
        : slot.isDefaultClosed
            ? strings.text('privateLessonDefaultClosed')
            : strings.text('unavailable');
    return Semantics(
      button: !requesting,
      label: '$time · $status',
      child: ExcludeSemantics(
        child: Material(
          color: slot.isAvailable
              ? const Color(0xFFEAF1E7)
              : const Color(0xFFF0F0EC),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: requesting
                ? null
                : slot.isAvailable
                    ? () => onRequest(slot)
                    : () => onUnavailable(slot),
            child: SizedBox(
              key: ValueKey('private-lesson-slot-${_clock(start)}'),
              width: 76,
              height: 104,
              child: Column(children: [
                Container(
                  height: 5,
                  color: slot.isAvailable
                      ? AppTheme.sage
                      : const Color(0xFFB7B7B1),
                ),
                const SizedBox(height: 13),
                Text(_clock(start),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(_clock(end), style: const TextStyle(fontSize: 11)),
                const Spacer(),
                requesting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        slot.isAvailable
                            ? Icons.arrow_forward
                            : Icons.lock_outline,
                        size: 18,
                        color:
                            slot.isAvailable ? AppTheme.sage : Colors.black45,
                      ),
                const SizedBox(height: 12),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  String _clock(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(children: [
          Icon(icon, size: 42, color: AppTheme.sage),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center)
        ]),
      );
}
