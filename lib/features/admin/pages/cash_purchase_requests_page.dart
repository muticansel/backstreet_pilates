import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/app_snack_bars.dart';
import '../../../l10n/app_localizations.dart';
import '../../purchases/data/purchase_gateway.dart';

class CashPurchaseRequestsPage extends StatefulWidget {
  const CashPurchaseRequestsPage({super.key, required this.purchases});

  final AdminPurchaseGateway purchases;

  @override
  State<CashPurchaseRequestsPage> createState() =>
      _CashPurchaseRequestsPageState();
}

class _CashPurchaseRequestsPageState extends State<CashPurchaseRequestsPage> {
  late Future<List<PendingCashPurchase>> _requests;
  String? _confirmingId;

  @override
  void initState() {
    super.initState();
    _requests = widget.purchases.loadPendingCashPurchases();
  }

  Future<void> _reload() async {
    final requests = widget.purchases.loadPendingCashPurchases();
    setState(() => _requests = requests);
    await requests;
  }

  Future<void> _confirm(PendingCashPurchase request) async {
    final strings = AppLocalizations.of(context);
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.text('confirmCashPayment')),
        content: Text(
          '${request.memberName} will receive ${request.packageName}. '
          'This creates the membership and cannot be undone here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.text('confirmPayment')),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;

    setState(() => _confirmingId = request.id);
    try {
      await widget.purchases.confirmCashPurchase(request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBars.success(
          strings
              .text('membershipCreated')
              .replaceAll('{name}', request.memberName),
        ),
      );
      await _reload();
    } on PurchaseFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _confirmingId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).text('cashRequests')),
          actions: [
            const LanguageMenuButton(),
            IconButton(
              tooltip: AppLocalizations.of(context).text('refresh'),
              onPressed: _confirmingId == null ? _reload : null,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FutureBuilder<List<PendingCashPurchase>>(
          future: _requests,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return _LoadError(onRetry: _reload);
            final requests = snapshot.data!;
            if (requests.isEmpty) return const _EmptyRequests();
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                itemCount: requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) => _RequestCard(
                  request: requests[index],
                  confirming: _confirmingId == requests[index].id,
                  onConfirm: () => _confirm(requests[index]),
                ),
              ),
            );
          },
        ),
      );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.confirming,
    required this.onConfirm,
  });

  final PendingCashPurchase request;
  final bool confirming;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8DED5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(request.memberName,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${request.packageName} · ${request.branchName}'),
          const SizedBox(height: 16),
          Text('₺${request.priceMinor ~/ 100}',
              style: const TextStyle(
                  color: AppTheme.sage,
                  fontSize: 24,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            '${request.totalCredits} classes · ${request.sessionsPerWeek} per week · '
            '${request.durationWeeks} weeks',
          ),
          const SizedBox(height: 6),
          Text(strings
              .text('requestedStart')
              .replaceAll('{date}', _date(request.requestedStartDate))),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: confirming ? null : onConfirm,
              icon: confirming
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label:
                  Text(strings.text(confirming ? 'confirming' : 'confirmCash')),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.task_alt_outlined, color: AppTheme.sage, size: 52),
            SizedBox(height: 16),
            Text(AppLocalizations.of(context).text('noCashPayments'),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(AppLocalizations.of(context).text('cashRequestsLoadError'),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
                onPressed: onRetry,
                child: Text(AppLocalizations.of(context).text('tryAgain'))),
          ]),
        ),
      );
}

String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}.'
    '${value.month.toString().padLeft(2, '0')}.${value.year}';
