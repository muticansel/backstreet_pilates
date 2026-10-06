import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_snack_bars.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/pilates_loading_indicator.dart';
import '../../bookings/data/booking_gateway.dart';

class _IndividualLessonData {
  const _IndividualLessonData({required this.members, required this.lessons});

  final List<AdminIndividualLessonMember> members;
  final List<AdminIndividualLessonRecord> lessons;
}

class IndividualLessonsPage extends StatefulWidget {
  const IndividualLessonsPage({super.key, required this.bookings});

  final AdminBookingGateway bookings;

  @override
  State<IndividualLessonsPage> createState() => _IndividualLessonsPageState();
}

class _IndividualLessonsPageState extends State<IndividualLessonsPage> {
  late Future<_IndividualLessonData> _data = _load();
  String? _selectedMemberId;

  Future<_IndividualLessonData> _load() async {
    final values = await Future.wait([
      widget.bookings.loadIndividualLessonMembers(),
      widget.bookings.loadIndividualLessons(),
    ]);
    return _IndividualLessonData(
      members: values[0] as List<AdminIndividualLessonMember>,
      lessons: values[1] as List<AdminIndividualLessonRecord>,
    );
  }

  void _reload() {
    setState(() {
      _data = _load();
    });
  }

  Future<void> _showRecordDialog(
      List<AdminIndividualLessonMember> members) async {
    final strings = AppLocalizations.of(context);
    if (members.isEmpty) return;
    var memberId = members.first.id;
    var date = DateTime.now();
    final price = TextEditingController();
    final rate = TextEditingController(text: '10');
    var saving = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(strings.text('recordPrivateLesson')),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: memberId,
                    decoration: InputDecoration(
                        labelText: strings.text('selectMember')),
                    items: members
                        .map((member) => DropdownMenuItem(
                              value: member.id,
                              child: Text(member.name),
                            ))
                        .toList(),
                    onChanged: saving
                        ? null
                        : (value) => setDialog(() => memberId = value!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        InputDecoration(labelText: strings.text('lessonPrice')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rate,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        InputDecoration(labelText: strings.text('ratePercent')),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            final selected = await showDatePicker(
                              context: dialogContext,
                              initialDate: date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (selected != null)
                              setDialog(() => date = selected);
                          },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label:
                        Text('${strings.text('lessonDate')}: ${_date(date)}'),
                  ),
                  const SizedBox(height: 4),
                  _EarningsPreview(price: price, rate: rate, strings: strings),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: Text(strings.text('cancel'))),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final priceMinor = _tryMinor(price.text);
                      final rateBps = _tryRateBasisPoints(rate.text);
                      if (priceMinor == null || rateBps == null) {
                        AppNotifications.error(
                            strings.text('invalidPrivateLesson'));
                        return;
                      }
                      setDialog(() => saving = true);
                      try {
                        await widget.bookings.recordIndividualLesson(
                          memberId: memberId,
                          lessonDate: date,
                          lessonPriceMinor: priceMinor,
                          rateBasisPoints: rateBps,
                        );
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (error) {
                        if (context.mounted)
                          AppNotifications.error(error.toString());
                        setDialog(() => saving = false);
                      }
                    },
              child: Text(strings.text('saveLesson')),
            ),
          ],
        ),
      ),
    );
    // AlertDialog exits with an animation; disposing controllers immediately
    // can leave the final TextField frame reading a disposed controller.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    price.dispose();
    rate.dispose();
    if (saved == true && mounted) {
      AppNotifications.success(strings.text('lessonSaved'));
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('privateLessons'))),
      floatingActionButton: FutureBuilder<_IndividualLessonData>(
        future: _data,
        builder: (context, snapshot) => FloatingActionButton.extended(
          onPressed: snapshot.hasData
              ? () => _showRecordDialog(snapshot.data!.members)
              : null,
          icon: const Icon(Icons.add),
          label: Text(strings.text('recordPrivateLesson')),
        ),
      ),
      body: FutureBuilder<_IndividualLessonData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: PilatesLoadingIndicator());
          if (snapshot.hasError)
            return Center(
                child: TextButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again')));
          final data = snapshot.data!;
          final lessons = _selectedMemberId == null
              ? data.lessons
              : data.lessons
                  .where((lesson) => lesson.memberId == _selectedMemberId)
                  .toList();
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
              children: [
                Text(strings.text('privateLessonsSubtitle'),
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 20),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedMemberId,
                  decoration:
                      InputDecoration(labelText: strings.text('selectMember')),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('All members')),
                    ...data.members.map((member) => DropdownMenuItem<String?>(
                        value: member.id, child: Text(member.name))),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedMemberId = value),
                ),
                const SizedBox(height: 20),
                if (lessons.isEmpty)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Text(strings.text('noPrivateLessons'),
                          textAlign: TextAlign.center))
                else
                  ...lessons.map((lesson) => _LessonCard(lesson: lesson)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson});
  final AdminIndividualLessonRecord lesson;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD8DED5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(lesson.memberName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 5),
        Text(
            '${_date(lesson.lessonDate)} · ${_money(lesson.lessonPriceMinor)} · ${_rate(lesson.rateBasisPoints)}'),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.payments_outlined, color: AppTheme.sage, size: 19),
          const SizedBox(width: 8),
          Text('${strings.text('earnings')}: ${_money(lesson.earningMinor)}',
              style: const TextStyle(
                  color: AppTheme.sage, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

class _EarningsPreview extends StatefulWidget {
  const _EarningsPreview(
      {required this.price, required this.rate, required this.strings});
  final TextEditingController price;
  final TextEditingController rate;
  final AppLocalizations strings;
  @override
  State<_EarningsPreview> createState() => _EarningsPreviewState();
}

class _EarningsPreviewState extends State<_EarningsPreview> {
  @override
  void initState() {
    super.initState();
    widget.price.addListener(_update);
    widget.rate.addListener(_update);
  }

  @override
  void dispose() {
    widget.price.removeListener(_update);
    widget.rate.removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});
  @override
  Widget build(BuildContext context) {
    final amount = _tryMinor(widget.price.text);
    final rate = _tryRateBasisPoints(widget.rate.text);
    final earning =
        amount == null || rate == null ? null : (amount * rate + 5000) ~/ 10000;
    return Text(
        '${widget.strings.text('earnings')}: ${earning == null ? '—' : _money(earning)}',
        style:
            const TextStyle(color: AppTheme.sage, fontWeight: FontWeight.w700));
  }
}

int? _tryMinor(String value) {
  final amount = double.tryParse(value.trim().replaceAll(',', '.'));
  return amount == null || amount <= 0 ? null : (amount * 100).round();
}

int? _tryRateBasisPoints(String value) {
  final rate = double.tryParse(value.trim().replaceAll(',', '.'));
  if (rate == null || rate < 10 || rate > 100) return null;
  return (rate * 100).round();
}

String _rate(int basisPoints) =>
    '${(basisPoints / 100).toStringAsFixed(basisPoints % 100 == 0 ? 0 : 2)}%';
String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
String _money(int minor) => '₺${(minor / 100).toStringAsFixed(2)}';
