class PackageOffer {
  const PackageOffer({
    required this.id,
    required this.title,
    required this.branchName,
    required this.totalCredits,
    required this.durationWeeks,
    required this.priceMinor,
  });

  final String id;
  final String title;
  final String branchName;
  final int totalCredits;
  final int durationWeeks;
  final int priceMinor;
}

abstract interface class PurchaseGateway {
  Future<List<PackageOffer>> loadActiveOffers();
  Future<void> requestCashPurchase({
    required String offerId,
    required DateTime requestedStartDate,
  });
}

class PendingCashPurchase {
  const PendingCashPurchase({
    required this.id,
    required this.memberName,
    required this.packageName,
    required this.branchName,
    required this.requestedStartDate,
    required this.priceMinor,
    required this.totalCredits,
    required this.sessionsPerWeek,
    required this.durationWeeks,
    required this.createdAt,
  });

  final String id;
  final String memberName;
  final String packageName;
  final String branchName;
  final DateTime requestedStartDate;
  final int priceMinor;
  final int totalCredits;
  final int sessionsPerWeek;
  final int durationWeeks;
  final DateTime createdAt;
}

abstract interface class AdminPurchaseGateway {
  Future<List<PendingCashPurchase>> loadPendingCashPurchases();
  Future<void> confirmCashPurchase(String requestId);
}

class UnconfiguredPurchaseGateway implements PurchaseGateway {
  const UnconfiguredPurchaseGateway();

  @override
  Future<List<PackageOffer>> loadActiveOffers() async => const [];

  @override
  Future<void> requestCashPurchase({
    required String offerId,
    required DateTime requestedStartDate,
  }) async =>
      throw const PurchaseFailure('Package service is not configured.');
}

class UnconfiguredAdminPurchaseGateway implements AdminPurchaseGateway {
  const UnconfiguredAdminPurchaseGateway();

  @override
  Future<void> confirmCashPurchase(String requestId) async =>
      throw const PurchaseFailure('Package service is not configured.');

  @override
  Future<List<PendingCashPurchase>> loadPendingCashPurchases() async =>
      const [];
}

class PurchaseFailure implements Exception {
  const PurchaseFailure(this.message);

  final String message;
}
