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
      setState(() => _slots = _load());
    } catch (_) {
      if (mounted) {
        AppNotifications.error(
            AppLocalizations.of(context).text('privateLessonRequestError'));
        setState(() => _slots = _load());
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
        onRefresh: () async => setState(() => _slots = _load()),
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
                ...snapshot.data!.map((slot) => _SlotTile(
                      slot: slot,
                      requesting:
                          _requestingSlot == slot.startsAt.toIso8601String(),
                      onTap: slot.isAvailable ? () => _request(slot) : null,
                      onUnavailable: () => _showUnavailableReason(slot),
                      strings: strings,
                    )),
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
  Widget build(BuildContext context) => Row(children: [
        _LegendItem(
            color: const Color(0xFFE1EEE4), text: strings.text('available')),
        const SizedBox(width: 16),
        _LegendItem(
            color: const Color(0xFFECECE8), text: strings.text('unavailable')),
      ]);
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

class _SlotTile extends StatelessWidget {
  const _SlotTile(
      {required this.slot,
      required this.requesting,
      required this.onTap,
      required this.onUnavailable,
      required this.strings});
  final PrivateLessonSlot slot;
  final bool requesting;
  final VoidCallback? onTap;
  final VoidCallback onUnavailable;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final start = slot.startsAt;
    final end = start.add(const Duration(hours: 1));
    final time = '${_clock(start)} – ${_clock(end)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: slot.isAvailable
            ? const Color(0xFFEAF1E7)
            : const Color(0xFFF0F0EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(slot.isAvailable ? Icons.schedule : Icons.block_outlined,
            color: slot.isAvailable ? AppTheme.sage : Colors.black45),
        title: Text(time, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(slot.isAvailable
            ? strings.text('available')
            : slot.isDefaultClosed
                ? strings.text('privateLessonDefaultClosed')
                : strings.text('unavailable')),
        trailing: slot.isAvailable
            ? requesting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.arrow_forward)
            : const Icon(Icons.lock_outline, size: 18),
        enabled: !requesting,
        onTap: requesting ? null : (onTap ?? onUnavailable),
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
