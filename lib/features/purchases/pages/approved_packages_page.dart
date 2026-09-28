import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/pilates_loading_indicator.dart';
import '../data/purchase_gateway.dart';

class ApprovedPackagesPage extends StatefulWidget {
  const ApprovedPackagesPage({super.key, required this.purchases});

  final PurchaseGateway purchases;

  @override
  State<ApprovedPackagesPage> createState() => _ApprovedPackagesPageState();
}

class _ApprovedPackagesPageState extends State<ApprovedPackagesPage> {
  late Future<List<ApprovedPackage>> _packages = _loadPackages();

  Future<List<ApprovedPackage>> _loadPackages() =>
      widget.purchases.loadApprovedPackages();

  Future<void> _refresh() async {
    setState(() => _packages = _loadPackages());
    await _packages;
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
          _ => ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
              itemCount: snapshot.data!.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                if (index == 0)
                  return _PageHeader(count: snapshot.data!.length);
                return _ApprovedPackageCard(package: snapshot.data![index - 1]);
              },
            ),
        };
        return RefreshIndicator(onRefresh: _refresh, child: content);
      },
    );
  }
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
          Text('My packages', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 10),
          Text(
            '$count approved ${count == 1 ? 'package' : 'packages'}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
        ],
      );
}

class _ApprovedPackageCard extends StatelessWidget {
  const _ApprovedPackageCard({required this.package});

  final ApprovedPackage package;

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
      ]),
    );
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
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
          Text('No approved packages yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          const Text(
              'Approved packages will appear here after the studio confirms your payment.',
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
          Text('Packages could not be loaded',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          Center(
              child: OutlinedButton(
                  onPressed: onRetry, child: const Text('Try again'))),
        ],
      );
}
