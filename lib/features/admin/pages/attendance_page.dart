import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_snack_bars.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/pilates_loading_indicator.dart';
import '../../bookings/data/booking_gateway.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key, required this.bookings});

  final AdminBookingGateway bookings;

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late Future<List<AdminAttendanceRecord>> _attendance = _load();
  String? _selectedMemberId;
  final _savingBookingIds = <String>{};

  Future<List<AdminAttendanceRecord>> _load() =>
      widget.bookings.loadPastAttendance();

  Future<void> _refresh() async {
    setState(() => _attendance = _load());
    await _attendance;
  }

  Future<void> _record(
    AdminAttendanceRecord record,
    bool attended,
  ) async {
    setState(() => _savingBookingIds.add(record.bookingId));
    try {
      await widget.bookings.recordAttendance(
        bookingId: record.bookingId,
        attended: attended,
      );
    } catch (_) {
      if (mounted) {
        AppNotifications.error(
            AppLocalizations.of(context).text('attendanceSaveError'));
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _savingBookingIds.remove(record.bookingId));
      }
    }

    if (!mounted) return;
    AppNotifications.success(
        AppLocalizations.of(context).text('attendanceSaved'));
    try {
      await _refresh();
    } catch (_) {
      if (mounted) {
        AppNotifications.error(
            AppLocalizations.of(context).text('attendanceLoadError'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('attendance'))),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AdminAttendanceRecord>>(
          future: _attendance,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: PilatesLoadingIndicator());
            }
            if (snapshot.hasError) {
              return ListView(children: [
                const SizedBox(height: 100),
                _EmptyState(message: strings.text('attendanceLoadError')),
              ]);
            }
            final records = snapshot.data!;
            final members = <String, String>{
              for (final record in records) record.memberId: record.memberName,
            };
            final selectedRecords = _selectedMemberId == null
                ? const <AdminAttendanceRecord>[]
                : records
                    .where((record) => record.memberId == _selectedMemberId)
                    .toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              children: [
                Text(strings.text('attendance'),
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(strings.text('manageAttendance'),
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedMemberId),
                  initialValue: _selectedMemberId,
                  decoration: InputDecoration(
                    labelText: strings.text('selectMember'),
                    border: const OutlineInputBorder(),
                  ),
                  items: members.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: records.isEmpty
                      ? null
                      : (memberId) =>
                          setState(() => _selectedMemberId = memberId),
                ),
                const SizedBox(height: 24),
                if (records.isEmpty)
                  _EmptyState(message: strings.text('noPastClasses'))
                else if (_selectedMemberId == null)
                  _EmptyState(message: strings.text('selectMember'))
                else if (selectedRecords.isEmpty)
                  _EmptyState(message: strings.text('noPastClassesForMember'))
                else
                  ...selectedRecords.map((record) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _AttendanceCard(
                          record: record,
                          saving: _savingBookingIds.contains(record.bookingId),
                          onAttended: () => _record(record, true),
                          onNoShow: () => _record(record, false),
                        ),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.record,
    required this.saving,
    required this.onAttended,
    required this.onNoShow,
  });

  final AdminAttendanceRecord record;
  final bool saving;
  final VoidCallback onAttended;
  final VoidCallback onNoShow;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final date =
        MaterialLocalizations.of(context).formatMediumDate(record.startsAt);
    final time = TimeOfDay.fromDateTime(record.startsAt).format(context);
    final pending = record.status == 'booked';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8DED5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(record.title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${record.branchName} · $date · $time'),
          const SizedBox(height: 12),
          Text(
            pending
                ? strings.text('attendancePending')
                : record.status == 'attended'
                    ? strings.text('attended')
                    : strings.text('didNotAttend'),
            style: const TextStyle(
              color: AppTheme.sage,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: saving ? null : onNoShow,
                  child: Text(strings.text('didNotAttend')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: saving ? null : onAttended,
                  child: Text(strings.text('attended')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Text(message, textAlign: TextAlign.center),
      );
}
