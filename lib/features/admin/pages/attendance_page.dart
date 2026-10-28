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
  final _updatedStatuses = <String, String>{};
  final _scrollController = ScrollController();

  Future<List<AdminAttendanceRecord>> _load() =>
      widget.bookings.loadPastAttendance();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _updatedStatuses.clear();
      _attendance = _load();
    });
    await _attendance;
  }

  Future<void> _selectMember(Map<String, String> members) async {
    final memberId = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MemberPickerSheet(
        members: members,
        selectedMemberId: _selectedMemberId,
      ),
    );
    if (!mounted || memberId == null) return;
    setState(() => _selectedMemberId = memberId);
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
    setState(() {
      _updatedStatuses[record.bookingId] = attended ? 'attended' : 'no_show';
    });
    AppNotifications.success(
        AppLocalizations.of(context).text('attendanceSaved'));
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
            final records = snapshot.data!
                .map((record) => _updatedStatuses.containsKey(record.bookingId)
                    ? record.copyWith(
                        status: _updatedStatuses[record.bookingId],
                      )
                    : record)
                .toList()
              ..sort(
                  (first, second) => second.startsAt.compareTo(first.startsAt));
            final members = <String, String>{
              for (final record in records) record.memberId: record.memberName,
            };
            final selectedRecords = _selectedMemberId == null
                ? const <AdminAttendanceRecord>[]
                : records
                    .where((record) => record.memberId == _selectedMemberId)
                    .toList();
            return ListView(
              key: const PageStorageKey('attendance-list'),
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              children: [
                Text(strings.text('attendance'),
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(strings.text('manageAttendance'),
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                _MemberPicker(
                  selectedName: _selectedMemberId == null
                      ? null
                      : members[_selectedMemberId],
                  enabled: records.isNotEmpty,
                  onPressed: () => _selectMember(members),
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
                          onAttended: record.status == 'attended'
                              ? null
                              : () => _record(record, true),
                          onNoShow: record.status == 'no_show'
                              ? null
                              : () => _record(record, false),
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

class _MemberPicker extends StatelessWidget {
  const _MemberPicker({
    required this.selectedName,
    required this.enabled,
    required this.onPressed,
  });

  final String? selectedName;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Semantics(
      button: enabled,
      label: strings.text('selectMember'),
      value: selectedName,
      child: OutlinedButton(
        key: const ValueKey('attendance-member-picker'),
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          minimumSize: const Size.fromHeight(62),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          side: const BorderSide(color: Color(0xFFD3D9D0)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.text('selectMember'),
                    style: const TextStyle(fontSize: 12, color: AppTheme.sage)),
                const SizedBox(height: 3),
                Text(
                  selectedName ?? strings.text('selectMember'),
                  style: TextStyle(
                    color: selectedName == null ? Colors.black54 : AppTheme.ink,
                    fontSize: 16,
                    fontWeight: selectedName == null
                        ? FontWeight.w400
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_up_rounded, color: AppTheme.sage),
        ]),
      ),
    );
  }
}

class _MemberPickerSheet extends StatelessWidget {
  const _MemberPickerSheet({
    required this.members,
    required this.selectedMemberId,
  });

  final Map<String, String> members;
  final String? selectedMemberId;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final entries = members.entries.toList()
      ..sort((first, second) => first.value.compareTo(second.value));
    return Container(
      constraints: const BoxConstraints(maxHeight: 460),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFEFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFCAD2C8),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(strings.text('selectMember'),
                style: Theme.of(context).textTheme.headlineSmall),
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            shrinkWrap: true,
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final selected = entry.key == selectedMemberId;
              return Material(
                color: selected ? const Color(0xFFE5EEE1) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  key: ValueKey('attendance-member-${entry.key}'),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  title: Text(entry.value,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: selected
                      ? const Icon(Icons.check_rounded, color: AppTheme.sage)
                      : const Icon(Icons.chevron_right_rounded,
                          color: Colors.black38),
                  onTap: () => Navigator.pop(context, entry.key),
                ),
              );
            },
          ),
        ),
      ]),
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
  final VoidCallback? onAttended;
  final VoidCallback? onNoShow;

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
                  key: ValueKey('attendance-attended-${record.bookingId}'),
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
