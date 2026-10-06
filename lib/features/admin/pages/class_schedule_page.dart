import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_snack_bars.dart';
import '../../../theme/pilates_loading_indicator.dart';
import '../../bookings/data/booking_gateway.dart';

class ClassSchedulePage extends StatefulWidget {
  const ClassSchedulePage({super.key, required this.bookings});

  final AdminBookingGateway bookings;

  @override
  State<ClassSchedulePage> createState() => _ClassSchedulePageState();
}

class _ClassSchedulePageState extends State<ClassSchedulePage> {
  late Future<_PackageData> _data = _load();

  Future<_PackageData> _load() async => _PackageData(
        branches: await widget.bookings.loadBranches(),
        offers: await widget.bookings.loadFixedOffers(),
      );

  void _reload() => setState(() => _data = _load());

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('classSchedule'))),
      body: FutureBuilder<_PackageData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: PilatesLoadingIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(strings.text('scheduleLoadError')));
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              children: [
                Text(
                  strings.text('fixedSeriesSubtitle'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: data.branches.isEmpty
                      ? null
                      : () => _createPackage(data.branches),
                  icon: const Icon(Icons.add),
                  label: Text(strings.text('createPackage')),
                ),
                const SizedBox(height: 28),
                Text(
                  strings.text('activePackages'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (data.offers.isEmpty) Text(strings.text('noClassSeries')),
                ...data.offers.map(
                  (offer) => Card(
                    child: ListTile(
                      title: Text(offer.title),
                      subtitle: Text(
                        '${offer.branchName} · ${_money(offer.priceMinor)} · '
                        '${strings.text('capacity')}: ${offer.capacity}',
                      ),
                      trailing: IconButton(
                        tooltip: strings.text('deletePackage'),
                        onPressed: () => _deletePackage(offer),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  strings.text('fixedSeriesNote'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deletePackage(AdminFixedOffer offer) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.text('deletePackage')),
        content: Text(
          strings
              .text('deletePackageConfirmation')
              .replaceAll('{name}', offer.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.text('deletePackage')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.bookings.deleteFixedOffer(offerId: offer.id);
      if (!mounted) return;
      AppNotifications.success(strings.text('packageDeleted'));
      _reload();
    } catch (error) {
      if (mounted) {
        AppNotifications.error(error.toString());
      }
    }
  }

  Future<void> _createPackage(List<StudioBranch> branches) async {
    final strings = AppLocalizations.of(context);
    final name = TextEditingController();
    final price = TextEditingController();
    final capacity = TextEditingController();
    final totalClasses = TextEditingController();
    final sessionsPerWeek = TextEditingController();
    var branchId = branches.first.id;
    var startsOn = DateTime.now();
    var slots = <_SlotInput>[
      _SlotInput(
        weekday: startsOn.weekday,
        time: const TimeOfDay(hour: 9, minute: 0),
      )
    ];
    var submitting = false;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(strings.text('createPackage')),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The first field's floating label extends above its outline.
                  // Keep it inside the scroll viewport when the keyboard moves
                  // this dialog upward.
                  const SizedBox(height: 10),
                  TextField(
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    decoration:
                        InputDecoration(labelText: strings.text('packageName')),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: branchId,
                    decoration:
                        InputDecoration(labelText: strings.text('branch')),
                    items: branches
                        .map((branch) => DropdownMenuItem(
                              value: branch.id,
                              child: Text(branch.name),
                            ))
                        .toList(),
                    onChanged: submitting
                        ? null
                        : (value) => setDialog(() => branchId = value!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        InputDecoration(labelText: strings.text('priceTry')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: totalClasses,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: strings.text('totalClasses')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sessionsPerWeek,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: strings.text('sessionsPerWeek')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: capacity,
                    keyboardType: TextInputType.number,
                    decoration:
                        InputDecoration(labelText: strings.text('capacity')),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: submitting
                          ? null
                          : () async {
                              final chosen = await showDatePicker(
                                context: dialogContext,
                                initialDate: startsOn,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 730)),
                              );
                              if (chosen != null) {
                                setDialog(() => startsOn = chosen);
                              }
                            },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        '${strings.text('firstClassDate')}: ${_date(startsOn)}',
                      ),
                    ),
                  ),
                  const Divider(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(strings.text('weeklySchedule')),
                  ),
                  const SizedBox(height: 8),
                  ...slots.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SlotEditor(
                            slot: entry.value,
                            strings: strings,
                            canRemove: slots.length > 1,
                            onChanged: (slot) =>
                                setDialog(() => slots[entry.key] = slot),
                            onRemove: () =>
                                setDialog(() => slots.removeAt(entry.key)),
                          ),
                        ),
                      ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: submitting || slots.length == 7
                          ? null
                          : () => setDialog(() => slots = [
                                ...slots,
                                const _SlotInput(
                                  weekday: 2,
                                  time: TimeOfDay(hour: 9, minute: 0),
                                ),
                              ]),
                      icon: const Icon(Icons.add),
                      label: Text(strings.text('addWeeklyClass')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(context),
              child: Text(strings.text('cancel')),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final priceMinor = _parsePriceMinor(price.text);
                      final capacityValue = int.tryParse(capacity.text);
                      final totalValue = int.tryParse(totalClasses.text);
                      final weeklyValue = int.tryParse(sessionsPerWeek.text);
                      final weekdays =
                          slots.map((slot) => slot.weekday).toList();
                      final message = name.text.trim().isEmpty ||
                              priceMinor == null ||
                              capacityValue == null ||
                              totalValue == null ||
                              weeklyValue == null
                          ? strings.text('completePackageFields')
                          : slots.length != weeklyValue
                              ? strings
                                  .text('weeklyClassCountMismatch')
                                  .replaceAll('{count}', '$weeklyValue')
                              : weekdays.toSet().length != weekdays.length
                                  ? strings.text('uniqueWeeklyDays')
                                  : !weekdays.contains(startsOn.weekday)
                                      ? strings.text('firstClassDayMismatch')
                                      : null;
                      if (message != null) {
                        AppNotifications.error(message);
                        return;
                      }
                      setDialog(() => submitting = true);
                      try {
                        await widget.bookings.createFixedOffer(
                          name: name.text.trim(),
                          branchId: branchId,
                          priceMinor: priceMinor!,
                          capacity: capacityValue!,
                          totalClasses: totalValue!,
                          sessionsPerWeek: weeklyValue!,
                          startsOn: startsOn,
                          weekdays: weekdays,
                          startTimes: slots
                              .map((slot) => TimeOfDayValue(
                                    hour: slot.time.hour,
                                    minute: slot.time.minute,
                                  ))
                              .toList(),
                        );
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (error) {
                        if (context.mounted) {
                          AppNotifications.error(error.toString());
                        }
                        setDialog(() => submitting = false);
                      }
                    },
              child: Text(strings.text('createPackage')),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    name.dispose();
    price.dispose();
    capacity.dispose();
    totalClasses.dispose();
    sessionsPerWeek.dispose();
    if (created == true && mounted) {
      AppNotifications.success(strings.text('packageCreated'));
      _reload();
    }
  }
}

class _SlotEditor extends StatelessWidget {
  const _SlotEditor({
    required this.slot,
    required this.strings,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final _SlotInput slot;
  final AppLocalizations strings;
  final bool canRemove;
  final ValueChanged<_SlotInput> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: slot.weekday,
              decoration: InputDecoration(
                labelText: strings.text('day'),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              ),
              items: List.generate(
                7,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text(strings.text('weekday${index + 1}')),
                ),
              ),
              onChanged: (weekday) =>
                  onChanged(slot.copyWith(weekday: weekday!)),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(70, 48),
              ),
              onPressed: () async {
                final time = await showTimePicker(
                    context: context, initialTime: slot.time);
                if (time != null) onChanged(slot.copyWith(time: time));
              },
              child: Text(slot.time.format(context)),
            ),
          ),
          const SizedBox(width: 2),
          SizedBox(
            width: 48,
            child: IconButton(
              tooltip: strings.text('removeWeeklyClass'),
              onPressed: canRemove ? onRemove : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
          ),
        ],
      );
}

class _SlotInput {
  const _SlotInput({required this.weekday, required this.time});

  final int weekday;
  final TimeOfDay time;

  _SlotInput copyWith({int? weekday, TimeOfDay? time}) => _SlotInput(
        weekday: weekday ?? this.weekday,
        time: time ?? this.time,
      );
}

class _PackageData {
  const _PackageData({required this.branches, required this.offers});

  final List<StudioBranch> branches;
  final List<AdminFixedOffer> offers;
}

String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}.'
    '${date.month.toString().padLeft(2, '0')}.${date.year}';

String _money(int minor) => '₺${(minor / 100).toStringAsFixed(2)}';

int? _parsePriceMinor(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  final amount = double.tryParse(normalized);
  if (amount == null || amount < 0) return null;
  return (amount * 100).round();
}
