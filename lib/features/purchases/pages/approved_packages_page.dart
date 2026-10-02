import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/app_snack_bars.dart';
import '../../../theme/pilates_loading_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../data/purchase_gateway.dart';

class ApprovedPackagesPage extends StatefulWidget {
  const ApprovedPackagesPage({super.key, required this.purchases});

  final PurchaseGateway purchases;

  @override
  State<ApprovedPackagesPage> createState() => _ApprovedPackagesPageState();
}

class _ApprovedPackagesPageState extends State<ApprovedPackagesPage> {
  late Future<List<ApprovedPackage>> _packages = _loadPackages();
  late Future<List<PackageOffer>> _offers = _loadOffers();
  String? _requestingOfferId;

  Future<List<ApprovedPackage>> _loadPackages() =>
      widget.purchases.loadApprovedPackages();

  Future<List<PackageOffer>> _loadOffers() =>
      widget.purchases.loadActiveOffers();

  Future<void> _refresh() async {
    setState(() {
      _packages = _loadPackages();
      _offers = _loadOffers();
    });
    await _packages;
  }

  Future<void> _requestCashRenewal(PackageOffer offer) async {
    setState(() => _requestingOfferId = offer.id);
    try {
      await widget.purchases.requestCashPurchase(
        offerId: offer.id,
        requestedStartDate: offer.startsOn,
      );
      if (!mounted) return;
      AppNotifications.success(
          AppLocalizations.of(context).text('cashRequestSent'));
    } on PurchaseFailure catch (error) {
      if (!mounted) return;
      AppNotifications.error(error.message);
    } finally {
      if (mounted) setState(() => _requestingOfferId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ApprovedPackage>>(
      future: _packages,
      builder: (context, snapshot) {
        final content = switch (snapshot.connectionState) {
          ConnectionState.waiting =>
            const Center(child: PilatesLoadingIndicator()),
          _ when snapshot.hasError => _LoadError(onRetry: _refresh),
          _ when snapshot.data!.isEmpty => const _EmptyPackages(),
          _ => FutureBuilder<List<PackageOffer>>(
              future: _offers,
              builder: (context, offersSnapshot) {
                final offers = offersSnapshot.data ?? const <PackageOffer>[];
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
                  itemCount: snapshot.data!.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _PageHeader(count: snapshot.data!.length);
                    }
                    final package = snapshot.data![index - 1];
                    return _ApprovedPackageCard(
                      package: package,
                      renewalOffer: _recommendedOffer(package, offers),
                      requesting: _requestingOfferId != null,
                      onRequestRenewal: _requestCashRenewal,
                    );
                  },
                );
              },
            ),
        };
        return RefreshIndicator(onRefresh: _refresh, child: content);
      },
    );
  }

  PackageOffer? _recommendedOffer(
    ApprovedPackage package,
    List<PackageOffer> offers,
  ) {
    if (!_isEnding(package)) return null;
    final matchingOffers = offers
        .where((offer) =>
            offer.branchName == package.branchName &&
            offer.totalCredits == package.totalCredits)
        .toList()
      ..sort((a, b) => a.startsOn.compareTo(b.startsOn));
    return matchingOffers.isEmpty ? null : matchingOffers.first;
  }
}

bool _isEnding(ApprovedPackage package) {
  final today = DateUtils.dateOnly(DateTime.now());
  return package.status == 'active' &&
      package.endDateExclusive.isAfter(today) &&
      package.remainingCredits >= 1 &&
      package.remainingCredits <= 3;
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_outlined, color: AppTheme.sage, size: 34),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context).text('myPackages'),
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)
                .text('approvedPackagesCount')
                .replaceAll('{count}', '$count'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
        ],
      );
}

class _ApprovedPackageCard extends StatelessWidget {
  const _ApprovedPackageCard({
    required this.package,
    required this.renewalOffer,
    required this.requesting,
    required this.onRequestRenewal,
  });

  final ApprovedPackage package;
  final PackageOffer? renewalOffer;
  final bool requesting;
  final Future<void> Function(PackageOffer offer) onRequestRenewal;

  bool get _isActive {
    final today = DateUtils.dateOnly(DateTime.now());
    return package.status == 'active' &&
        package.endDateExclusive.isAfter(today);
  }

  bool get _isUpcoming => package.status == 'pending_start';

  @override
  Widget build(BuildContext context) {
    final statusLabel = _isActive
        ? 'Active'
        : _isUpcoming
            ? 'Starts soon'
            : 'Old';
    final statusColor = _isActive
        ? AppTheme.sage
        : _isUpcoming
            ? const Color(0xFF9A6B28)
            : Colors.black54;
    final dateLabel = _isActive
        ? 'Valid until ${_formatDate(package.endDateExclusive.subtract(const Duration(days: 1)))}'
        : _isUpcoming
            ? 'Starts ${_formatDate(package.startDate)}'
            : 'Ended ${_formatDate(package.endDateExclusive.subtract(const Duration(days: 1)))}';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8DED5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(package.title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700))),
          _StatusChip(label: statusLabel, color: statusColor),
        ]),
        const SizedBox(height: 6),
        Text(package.branchName, style: const TextStyle(color: AppTheme.sage)),
        const SizedBox(height: 18),
        Text(
          _isActive
              ? '${package.remainingCredits} of ${package.totalCredits} classes remaining'
              : '${package.totalCredits} classes',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(dateLabel),
        if (renewalOffer != null) ...[
          const Divider(height: 32),
          _RenewalPrompt(
            remainingCredits: package.remainingCredits,
            offer: renewalOffer!,
            requesting: requesting,
            onPressed: () => onRequestRenewal(renewalOffer!),
          ),
        ],
      ]),
    );
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}

class _RenewalPrompt extends StatelessWidget {
  const _RenewalPrompt({
    required this.remainingCredits,
    required this.offer,
    required this.requesting,
    required this.onPressed,
  });

  final int remainingCredits;
  final PackageOffer offer;
  final bool requesting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3E9DD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings
                .text('packageEndingTitle')
                .replaceAll('{count}', '$remainingCredits'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(strings.text('packageEndingDetail')),
          const SizedBox(height: 12),
          Text(
            strings
                .text('renewalRecommendation')
                .replaceAll('{package}', offer.title)
                .replaceAll('{price}', '₺${offer.priceMinor ~/ 100}'),
            style: const TextStyle(fontSize: 12, color: AppTheme.sage),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: requesting ? null : onPressed,
              icon: requesting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.payments_outlined),
              label: Text(strings.text(
                  requesting ? 'creatingCashRequest' : 'requestCashRenewal')),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class _EmptyPackages extends StatelessWidget {
  const _EmptyPackages();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.style_outlined, color: AppTheme.sage, size: 48),
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context).text('noApprovedPackages'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(AppLocalizations.of(context).text('noApprovedPackagesDetail'),
              textAlign: TextAlign.center),
        ],
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline, color: AppTheme.sage, size: 48),
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context).text('approvedPackagesLoadError'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          Center(
              child: OutlinedButton(
                  onPressed: onRetry,
                  child: Text(AppLocalizations.of(context).text('tryAgain')))),
        ],
      );
}
