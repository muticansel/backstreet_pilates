import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_snack_bars.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/pilates_loading_indicator.dart';
import '../../bookings/data/booking_gateway.dart';

class PrivateLessonCalendarPage extends StatefulWidget {
  const PrivateLessonCalendarPage({super.key, required this.bookings});
  final AdminBookingGateway bookings;

  @override
  State<PrivateLessonCalendarPage> createState() =>
      _PrivateLessonCalendarPageState();
}

class _PrivateLessonCalendarPageState extends State<PrivateLessonCalendarPage> {
  late DateTime _weekStart = _monday(DateTime.now());
  late Future<List<AdminPrivateLessonEntry>> _entries = _load();
  String? _resolving;

  static DateTime _monday(DateTime date) =>
      DateTime(date.year, date.month, date.day)
          .subtract(Duration(days: date.weekday - 1));
  Future<List<AdminPrivateLessonEntry>> _load() =>
      widget.bookings.loadPrivateLessonCalendar(_weekStart);
  Future<void> _reload() async {
    setState(() => _entries = _load());
    await _entries;
  }

  void _changeWeek(int days) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: days));
      _entries = _load();
    });
  }

  Future<void> _resolve(AdminPrivateLessonEntry entry, bool approve) async {
    setState(() => _resolving = entry.id);
    try {
      await widget.bookings
          .resolvePrivateLessonRequest(requestId: entry.id, approve: approve);
      if (mounted) {
        AppNotifications.success(AppLocalizations.of(context)
            .text(approve ? 'privateLessonApproved' : 'privateLessonDeclined'));
        _reload();
      }
    } catch (_) {
      if (mounted)
        AppNotifications.error(
            AppLocalizations.of(context).text('privateLessonResolveError'));
    } finally {
      if (mounted) setState(() => _resolving = null);
    }
  }

  Future<void> _blockTime() async {
    final result = await showDialog<_BlockRange>(
      context: context,
      builder: (_) => _BlockDialog(initialDate: _weekStart),
    );
    if (result == null) return;
    try {
      await widget.bookings.blockPrivateLessonTime(
        startsAt: result.startsAt,
        endsAt: result.endsAt,
      );
      if (mounted) {
        AppNotifications.success(
            AppLocalizations.of(context).text('privateLessonTimeBlocked'));
        _reload();
      }
    } catch (_) {
      if (mounted)
        AppNotifications.error(
            AppLocalizations.of(context).text('privateLessonBlockError'));
    }
  }

  Future<void> _deleteBlock(AdminPrivateLessonEntry entry) async {
    final strings = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.text('deleteBlockedTime')),
        content: Text(strings.text('deleteBlockedTimeDetail')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.text('cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.text('deleteBlockedTime')),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    try {
      await widget.bookings.deletePrivateLessonBlock(blockId: entry.id);
      if (mounted) {
        AppNotifications.success(strings.text('blockedTimeDeleted'));
        _reload();
      }
    } catch (_) {
      if (mounted) {
        AppNotifications.error(strings.text('deleteBlockedTimeError'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.text('privateLessonCalendar')),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<AdminPrivateLessonEntry>>(
          future: _entries,
          builder: (context, snapshot) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
            children: [
              _CalendarHero(
                detail: strings.text('privateLessonCalendarDetail'),
                weekLabel: _weekLabel(context),
                previousWeek: () => _changeWeek(-7),
                nextWeek: () => _changeWeek(7),
              ),
              const SizedBox(height: 24),
              if (snapshot.connectionState != ConnectionState.done)
                const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: PilatesLoadingIndicator()))
              else if (snapshot.hasError)
                _CalendarNotice(
                    icon: Icons.cloud_off_outlined,
                    text: strings.text('privateLessonCalendarLoadError'))
              else
                _WeekEntries(
                    entries: snapshot.data!,
                    resolving: _resolving,
                    onResolve: _resolve,
                    onDeleteBlock: _deleteBlock,
                    strings: strings),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _blockTime,
        icon: const Icon(Icons.block_outlined),
        label: Text(strings.text('blockTime')),
      ),
    );
  }

  String _weekLabel(BuildContext context) {
    final end = _weekStart.add(const Duration(days: 6));
    final local = MaterialLocalizations.of(context);
    return '${local.formatMediumDate(_weekStart)} – ${local.formatMediumDate(end)}';
  }
}

class _CalendarHero extends StatelessWidget {
  const _CalendarHero({
    required this.detail,
    required this.weekLabel,
    required this.previousWeek,
    required this.nextWeek,
  });

  final String detail;
  final String weekLabel;
  final VoidCallback previousWeek;
  final VoidCallback nextWeek;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
        decoration: BoxDecoration(
          color: AppTheme.sage,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.calendar_view_week_outlined,
              color: Color(0xFFEAF1E7), size: 24),
          const SizedBox(height: 12),
          Text(detail,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.4,
              )),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              IconButton(
                onPressed: previousWeek,
                color: Colors.white,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(weekLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                onPressed: nextWeek,
                color: Colors.white,
                icon: const Icon(Icons.chevron_right),
              ),
            ]),
          ),
        ]),
      );
}

class _WeekEntries extends StatelessWidget {
  const _WeekEntries(
      {required this.entries,
      required this.resolving,
      required this.onResolve,
      required this.onDeleteBlock,
      required this.strings});
  final List<AdminPrivateLessonEntry> entries;
  final String? resolving;
  final void Function(AdminPrivateLessonEntry, bool) onResolve;
  final ValueChanged<AdminPrivateLessonEntry> onDeleteBlock;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final byDay = <DateTime, List<AdminPrivateLessonEntry>>{};
    // Never hide records in the operational calendar. In particular, a
    // declined request and a newer pending request may occupy the same slot
    // while the admin is troubleshooting or reviewing history.
    final orderedEntries = entries.toList()
      ..sort((first, second) {
        final byTime = first.startsAt.compareTo(second.startsAt);
        if (byTime != 0) return byTime;
        final firstPriority = first.status == 'pending' ? 0 : 1;
        final secondPriority = second.status == 'pending' ? 0 : 1;
        return firstPriority.compareTo(secondPriority);
      });
    for (final entry in orderedEntries) {
      final day = DateTime(
          entry.startsAt.year, entry.startsAt.month, entry.startsAt.day);
      byDay.putIfAbsent(day, () => []).add(entry);
    }
    if (byDay.isEmpty)
      return _CalendarNotice(
          icon: Icons.event_available_outlined,
          text: strings.text('noPrivateLessonCalendarEntries'));
    return Column(
      children: byDay.entries
          .map((group) => Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4ECE1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        MaterialLocalizations.of(context)
                            .formatFullDate(group.key),
                        style: const TextStyle(
                          color: AppTheme.sage,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...group.value.map((entry) => _EntryCard(
                          entry: entry,
                          resolving: resolving == entry.id,
                          onResolve: onResolve,
                          onDeleteBlock: onDeleteBlock,
                          strings: strings,
                        )),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard(
      {required this.entry,
      required this.resolving,
      required this.onResolve,
      required this.onDeleteBlock,
      required this.strings});
  final AdminPrivateLessonEntry entry;
  final bool resolving;
  final void Function(AdminPrivateLessonEntry, bool) onResolve;
  final ValueChanged<AdminPrivateLessonEntry> onDeleteBlock;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final pending = !entry.isBlock && entry.status == 'pending';
    final rejected = !entry.isBlock && entry.status == 'rejected';
    final background = entry.isBlock
        ? const Color(0xFFF2EFEB)
        : pending
            ? const Color(0xFFFFF4E1)
            : rejected
                ? const Color(0xFFF7E9E7)
                : const Color(0xFFE6F0E6);
    final icon = entry.isBlock
        ? Icons.block_outlined
        : pending
            ? Icons.hourglass_top_outlined
            : rejected
                ? Icons.cancel_outlined
                : Icons.check_circle_outline;
    final status = entry.isBlock
        ? strings.text('unavailable')
        : strings.text(entry.status == 'approved'
            ? 'approved'
            : rejected
                ? 'declined'
                : 'pending');
    // Keep a record as one self-contained, full-width card. The former
    // timeline row used a nested Expanded in a scrolling list and was being
    // laid out without its card body on some iOS builds.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon,
              color: rejected ? const Color(0xFFA64840) : AppTheme.sage,
              size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.isBlock
                  ? strings.text('blockedTime')
                  : entry.memberName ?? strings.text('member'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (entry.isBlock)
            IconButton(
              onPressed: () => onDeleteBlock(entry),
              tooltip: strings.text('deleteBlockedTime'),
              icon: const Icon(Icons.delete_outline, size: 20),
            ),
        ]),
        const SizedBox(height: 12),
        Text(
          '${_clock(entry.startsAt)} – ${_clock(entry.endsAt)}',
          style: const TextStyle(
            color: AppTheme.sage,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(status),
        if (pending) ...[
          const SizedBox(height: 14),
          Row(children: [
            OutlinedButton(
              onPressed: resolving ? null : () => onResolve(entry, false),
              child: Text(strings.text('decline')),
            ),
            const Spacer(),
            FilledButton(
              onPressed: resolving ? null : () => onResolve(entry, true),
              style: FilledButton.styleFrom(
                minimumSize: const Size(104, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: resolving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.text('approve')),
            ),
          ]),
        ],
      ]),
    );
  }

  String _clock(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _BlockDialog extends StatefulWidget {
  const _BlockDialog({required this.initialDate});
  final DateTime initialDate;
  @override
  State<_BlockDialog> createState() => _BlockDialogState();
}

class _BlockDialogState extends State<_BlockDialog> {
  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  late final DateTime _initialDate = DateTime(widget.initialDate.year,
              widget.initialDate.month, widget.initialDate.day)
          .isBefore(_today())
      ? _today()
      : DateTime(widget.initialDate.year, widget.initialDate.month,
          widget.initialDate.day);
  late DateTimeRange _dates = DateTimeRange(
    start: _initialDate,
    end: _initialDate,
  );
  int _startHour = 9;
  int _endHour = 10;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(strings.text('blockTime')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                  context: context,
                  initialDateRange: _dates,
                  firstDate: _today(),
                  lastDate: DateTime.now().add(const Duration(days: 365)));
              if (picked != null) setState(() => _dates = picked);
            },
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
                '${MaterialLocalizations.of(context).formatMediumDate(_dates.start)} – ${MaterialLocalizations.of(context).formatMediumDate(_dates.end)}')),
        const SizedBox(height: 22),
        DropdownButtonFormField<int>(
            initialValue: _startHour,
            decoration: InputDecoration(labelText: strings.text('startTime')),
            items: List.generate(
                17,
                (i) => DropdownMenuItem(
                    value: i + 5,
                    child: Text('${(i + 5).toString().padLeft(2, '0')}:00'))),
            onChanged: (value) => setState(() {
                  _startHour = value!;
                  if (_endHour <= _startHour) _endHour = _startHour + 1;
                })),
        const SizedBox(height: 18),
        DropdownButtonFormField<int>(
            initialValue: _endHour,
            decoration: InputDecoration(labelText: strings.text('endTime')),
            items: List.generate(
                17,
                (i) => DropdownMenuItem(
                    value: i + 6,
                    child: Text('${(i + 6).toString().padLeft(2, '0')}:00'))),
            onChanged: (value) => setState(() => _endHour = value!)),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.text('cancel'))),
        FilledButton(
            onPressed: DateTime(_dates.end.year, _dates.end.month,
                        _dates.end.day, _endHour)
                    .isAfter(DateTime(_dates.start.year, _dates.start.month,
                        _dates.start.day, _startHour))
                ? () => Navigator.pop(
                    context,
                    _BlockRange(
                        DateTime(_dates.start.year, _dates.start.month,
                            _dates.start.day, _startHour),
                        DateTime(_dates.end.year, _dates.end.month,
                            _dates.end.day, _endHour)))
                : null,
            child: Text(strings.text('blockTime')))
      ],
    );
  }
}

class _BlockRange {
  const _BlockRange(this.startsAt, this.endsAt);
  final DateTime startsAt;
  final DateTime endsAt;
}

class _CalendarNotice extends StatelessWidget {
  const _CalendarNotice({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(children: [
        Icon(icon, color: AppTheme.sage, size: 42),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center)
      ]));
}
