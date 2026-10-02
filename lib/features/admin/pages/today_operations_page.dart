import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/pilates_loading_indicator.dart';
import '../../bookings/data/booking_gateway.dart';
import '../../purchases/data/purchase_gateway.dart';
import 'attendance_page.dart';
import 'cash_purchase_requests_page.dart';

class TodayOperationsPage extends StatefulWidget {
  const TodayOperationsPage({
    super.key,
    required this.bookings,
    required this.purchases,
  });

  final AdminBookingGateway bookings;
  final AdminPurchaseGateway purchases;

  @override
  State<TodayOperationsPage> createState() => _TodayOperationsPageState();
}

class _TodayOperationsPageState extends State<TodayOperationsPage> {
  late Future<AdminTodayOperations> _operations = _load();

  Future<AdminTodayOperations> _load() => widget.bookings.loadTodayOperations();

  Future<void> _refresh() async {
    setState(() => _operations = _load());
    await _operations;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.text('todayOperations')),
        actions: [
          const LanguageMenuButton(),
          IconButton(
            tooltip: strings.text('refresh'),
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<AdminTodayOperations>(
          future: _operations,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: PilatesLoadingIndicator());
            }
            if (snapshot.hasError) {
              return ListView(children: [
                const SizedBox(height: 110),
                _Message(message: strings.text('todayOperationsLoadError')),
              ]);
            }
            final data = snapshot.data!;
            final totalCapacity = data.classes
                .fold<int>(0, (total, session) => total + session.capacity);
            final totalBooked = data.classes
                .fold<int>(0, (total, session) => total + session.bookedCount);
            final occupancy = totalCapacity == 0
                ? 0
                : (totalBooked * 100 / totalCapacity).round();
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              children: [
                Text(strings.text('today'),
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(strings.text('todayOperationsSubtitle'),
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: _Metric(
                      label: strings.text('todayClasses'),
                      value: '${data.classes.length}',
                      icon: Icons.calendar_today_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Metric(
                      label: strings.text('occupancy'),
                      value: '$occupancy%',
                      icon: Icons.pie_chart_outline,
                    ),
                  ),
                ]),
                const SizedBox(height: 28),
                _Section(
                  title: strings.text('todayClasses'),
                  empty: strings.text('noClassesToday'),
                  children: data.classes
                      .map((session) => _OperationCard(
                            icon: Icons.schedule_outlined,
                            title: session.title,
                            detail:
                                '${session.branchName} · ${TimeOfDay.fromDateTime(session.startsAt).format(context)}',
                            trailing:
                                '${session.bookedCount}/${session.capacity}',
                          ))
                      .toList(),
                ),
                _Section(
                  title: strings.text('noShowList'),
                  empty: strings.text('noNoShowsToday'),
                  action: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => AttendancePage(bookings: widget.bookings),
                  )),
                  children: data.noShows
                      .map((record) => _OperationCard(
                            icon: Icons.person_off_outlined,
                            title: record.memberName,
                            detail:
                                '${record.title} · ${record.branchName} · ${TimeOfDay.fromDateTime(record.startsAt).format(context)}',
                          ))
                      .toList(),
                ),
                _Section(
                  title: strings.text('upcomingPackageEndings'),
                  empty: strings.text('noUpcomingPackageEndings'),
                  children: data.endingPackages
                      .map((membership) => _OperationCard(
                            icon: Icons.timelapse_outlined,
                            title: membership.memberName,
                            detail:
                                '${membership.packageName} · ${strings.text('endsOn').replaceAll('{date}', MaterialLocalizations.of(context).formatMediumDate(membership.endDate))}',
                            trailing: strings.text('classesLeft').replaceAll(
                                '{count}', '${membership.remainingCredits}'),
                          ))
                      .toList(),
                ),
                _Section(
                  title: strings.text('paymentsAwaitingApproval'),
                  empty: strings.text('noPendingPayments'),
                  action: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) =>
                        CashPurchaseRequestsPage(purchases: widget.purchases),
                  )),
                  children: data.pendingPayments
                      .map((payment) => _OperationCard(
                            icon: Icons.payments_outlined,
                            title: payment.memberName,
                            detail: payment.packageName,
                            trailing: _formatTry(payment.priceMinor),
                          ))
                      .toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD8DED5)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppTheme.sage),
          const SizedBox(height: 18),
          Text(value,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 12)),
        ]),
      );
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title,
      required this.empty,
      required this.children,
      this.action});
  final String title;
  final String empty;
  final List<Widget> children;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: AppTheme.sage,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1))),
            if (action != null)
              TextButton(
                  onPressed: action,
                  child: Text(AppLocalizations.of(context).text('viewAll'))),
          ]),
          const SizedBox(height: 8),
          if (children.isEmpty)
            _Message(message: empty)
          else
            ...children.map((child) => Padding(
                padding: const EdgeInsets.only(bottom: 10), child: child)),
        ]),
      );
}

class _OperationCard extends StatelessWidget {
  const _OperationCard(
      {required this.icon,
      required this.title,
      required this.detail,
      this.trailing});
  final IconData icon;
  final String title;
  final String detail;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD8DED5))),
        child: Row(children: [
          Icon(icon, color: AppTheme.sage),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(detail, style: const TextStyle(fontSize: 12)),
              ])),
          if (trailing != null)
            Text(trailing!,
                style: const TextStyle(
                    color: AppTheme.sage, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(message, textAlign: TextAlign.center),
      );
}

String _formatTry(int amountMinor) {
  final digits = (amountMinor ~/ 100).toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    groups.add(digits.substring(end - 3 < 0 ? 0 : end - 3, end));
  }
  return '₺${groups.reversed.join('.')}';
}
