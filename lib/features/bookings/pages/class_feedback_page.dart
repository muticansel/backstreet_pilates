import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_snack_bars.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/pilates_loading_indicator.dart';
import '../data/booking_gateway.dart';

class ClassFeedbackPage extends StatefulWidget {
  const ClassFeedbackPage({super.key, required this.bookings});

  final BookingGateway bookings;

  @override
  State<ClassFeedbackPage> createState() => _ClassFeedbackPageState();
}

class _ClassFeedbackPageState extends State<ClassFeedbackPage> {
  late Future<List<FeedbackClass>> _classes =
      widget.bookings.loadFeedbackClasses();
  String? _savingBookingId;

  Future<void> _save(FeedbackClass item, int enjoyment, int difficulty) async {
    setState(() => _savingBookingId = item.bookingId);
    try {
      await widget.bookings.saveClassFeedback(
        bookingId: item.bookingId,
        enjoyment: enjoyment,
        difficulty: difficulty,
      );
      if (!mounted) return;
      AppNotifications.success(
          AppLocalizations.of(context).text('feedbackSaved'));
      setState(() => _classes = widget.bookings.loadFeedbackClasses());
    } catch (_) {
      if (mounted)
        AppNotifications.error(
            AppLocalizations.of(context).text('feedbackSaveError'));
    } finally {
      if (mounted) setState(() => _savingBookingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('classFeedback'))),
      body: FutureBuilder<List<FeedbackClass>>(
        future: _classes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: PilatesLoadingIndicator());
          }
          if (snapshot.hasError) {
            return _Message(
                icon: Icons.cloud_off_outlined,
                text: strings.text('feedbackLoadError'));
          }
          final classes = snapshot.data!;
          if (classes.isEmpty) {
            return _Message(
                icon: Icons.event_available_outlined,
                text: strings.text('noCompletedClasses'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 36),
            children: [
              Text(strings.text('classFeedbackSubtitle'),
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              ...classes.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: item.hasFeedback
                        ? _FeedbackHistory(item: item)
                        : _FeedbackForm(
                            item: item,
                            saving: _savingBookingId == item.bookingId,
                            onSave: (enjoyment, difficulty) =>
                                _save(item, enjoyment, difficulty),
                          ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _FeedbackForm extends StatefulWidget {
  const _FeedbackForm(
      {required this.item, required this.saving, required this.onSave});
  final FeedbackClass item;
  final bool saving;
  final void Function(int enjoyment, int difficulty) onSave;

  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  int? _enjoyment;
  int? _difficulty;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _ClassHeading(item: widget.item),
        const SizedBox(height: 20),
        Text(strings.text('howWasClass'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _ChoiceRow(
          labels: [
            strings.text('notForMe'),
            strings.text('good'),
            strings.text('lovedIt')
          ],
          selected: _enjoyment,
          onSelected: (value) => setState(() => _enjoyment = value),
        ),
        const SizedBox(height: 18),
        Text(strings.text('difficultyLevel'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _ChoiceRow(
          labels: [
            strings.text('easy'),
            strings.text('justRight'),
            strings.text('challenging')
          ],
          selected: _difficulty,
          onSelected: (value) => setState(() => _difficulty = value),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _enjoyment == null || _difficulty == null || widget.saving
              ? null
              : () => widget.onSave(_enjoyment!, _difficulty!),
          child: Text(widget.saving
              ? strings.text('saving')
              : strings.text('saveFeedback')),
        ),
      ]),
    );
  }
}

class _FeedbackHistory extends StatelessWidget {
  const _FeedbackHistory({required this.item});
  final FeedbackClass item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ClassHeading(item: item),
      const SizedBox(height: 16),
      Text(strings.text('feedbackRecorded'),
          style: const TextStyle(
              color: AppTheme.sage, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('${strings.text('howWasClass')}: ${_label(item.enjoyment!, [
            strings.text('notForMe'),
            strings.text('good'),
            strings.text('lovedIt')
          ])}'),
      Text('${strings.text('difficultyLevel')}: ${_label(item.difficulty!, [
            strings.text('easy'),
            strings.text('justRight'),
            strings.text('challenging')
          ])}'),
    ]));
  }

  String _label(int value, List<String> labels) => labels[value - 1];
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow(
      {required this.labels, required this.selected, required this.onSelected});
  final List<String> labels;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(
            labels.length,
            (index) => ChoiceChip(
                  label: Text(labels[index]),
                  selected: selected == index + 1,
                  onSelected: (_) => onSelected(index + 1),
                )),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD8DED5))),
        child: child,
      );
}

class _ClassHeading extends StatelessWidget {
  const _ClassHeading({required this.item});
  final FeedbackClass item;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(
            '${item.branchName} · ${item.startsAt.day.toString().padLeft(2, '0')}.${item.startsAt.month.toString().padLeft(2, '0')}.${item.startsAt.year}'),
      ]);
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 42, color: AppTheme.sage),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center)
          ])));
}
