import 'package:supabase_flutter/supabase_flutter.dart';

import 'purchase_gateway.dart';

class SupabasePurchaseGateway implements PurchaseGateway, AdminPurchaseGateway {
  SupabasePurchaseGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PackageOffer>> loadActiveOffers() async {
    try {
      final rows = await _client
          .from('branch_offers')
          .select(
              'id, price_minor, branches!inner(name), membership_plans!inner(name, total_credits, duration_weeks), class_series!inner(starts_on)')
          .eq('is_active', true);
      return rows.map((row) {
        final branch = row['branches'] as Map<String, dynamic>;
        final plan = row['membership_plans'] as Map<String, dynamic>;
        final series = row['class_series'] as Map<String, dynamic>;
        return PackageOffer(
          id: row['id'] as String,
          title: plan['name'] as String,
          branchName: branch['name'] as String,
          totalCredits: plan['total_credits'] as int,
          durationWeeks: plan['duration_weeks'] as int,
          priceMinor: row['price_minor'] as int,
          startsOn: DateTime.parse(series['starts_on'] as String),
        );
      }).toList();
    } catch (_) {
      throw const PurchaseFailure('Packages could not be loaded. Try again.');
    }
  }

  @override
  Future<List<ApprovedPackage>> loadApprovedPackages() async {
    try {
      final rows = await _client
          .from('user_memberships')
          .select(
              'id, status, total_credits, remaining_credits, effective_start_date, '
              'end_date_exclusive, '
              'branches!user_memberships_branch_id_fkey(name), '
              'membership_plans!user_memberships_plan_id_fkey(name)')
          .order('effective_start_date', ascending: false);
      return rows.map((row) {
        final branch = row['branches'] as Map<String, dynamic>;
        final plan = row['membership_plans'] as Map<String, dynamic>;
        return ApprovedPackage(
          id: row['id'] as String,
          title: plan['name'] as String,
          branchName: branch['name'] as String,
          status: row['status'] as String,
          totalCredits: row['total_credits'] as int,
          remainingCredits: row['remaining_credits'] as int,
          startDate: DateTime.parse(row['effective_start_date'] as String),
          endDateExclusive: DateTime.parse(row['end_date_exclusive'] as String),
        );
      }).toList();
    } on PostgrestException catch (error) {
      throw PurchaseFailure(error.message);
    } catch (_) {
      throw const PurchaseFailure(
          'Approved packages could not be loaded. Try again.');
    }
  }

  @override
  Future<void> requestCashPurchase({
    required String offerId,
    required DateTime requestedStartDate,
  }) async {
    try {
      await _client.rpc('request_cash_membership_purchase', params: {
        'target_offer_id': offerId,
        'target_requested_start_date':
            requestedStartDate.toIso8601String().split('T').first,
      });
    } on PostgrestException catch (error) {
      throw PurchaseFailure(error.message);
    } catch (_) {
      throw const PurchaseFailure(
          'Cash request could not be created. Try again.');
    }
  }

  @override
  Future<List<PendingCashPurchase>> loadPendingCashPurchases() async {
    try {
      final rows = await _client
          .from('membership_purchase_requests')
          .select(
              'id, user_id, requested_start_date, price_minor, total_credits, '
              'sessions_per_week, duration_weeks, created_at, '
              'branches!membership_purchase_requests_branch_id_fkey(name), '
              'membership_plans!membership_purchase_requests_plan_id_fkey(name)')
          .eq('status', 'cash_payment_pending')
          .order('created_at', ascending: true);
      final userIds = rows.map((row) => row['user_id'] as String).toSet();
      final profileRows = userIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _client
              .from('profiles')
              .select('id, display_name')
              .inFilter('id', userIds.toList());
      final namesByUserId = {
        for (final profile in profileRows)
          profile['id'] as String: profile['display_name'] as String,
      };
      return rows.map((row) {
        final branch = row['branches'] as Map<String, dynamic>;
        final plan = row['membership_plans'] as Map<String, dynamic>;
        return PendingCashPurchase(
          id: row['id'] as String,
          memberName: namesByUserId[row['user_id'] as String] ?? 'Member',
          packageName: plan['name'] as String,
          branchName: branch['name'] as String,
          requestedStartDate:
              DateTime.parse(row['requested_start_date'] as String),
          priceMinor: row['price_minor'] as int,
          totalCredits: row['total_credits'] as int,
          sessionsPerWeek: row['sessions_per_week'] as int,
          durationWeeks: row['duration_weeks'] as int,
          createdAt: DateTime.parse(row['created_at'] as String),
        );
      }).toList();
    } on PostgrestException catch (error) {
      throw PurchaseFailure(error.message);
    } catch (_) {
      throw const PurchaseFailure(
          'Cash requests could not be loaded. Try again.');
    }
  }

  @override
  Future<void> confirmCashPurchase(String requestId) async {
    try {
      await _client.rpc('confirm_cash_membership_purchase',
          params: {'target_request_id': requestId});
    } on PostgrestException catch (error) {
      throw PurchaseFailure(error.message);
    } catch (_) {
      throw const PurchaseFailure(
          'Cash request could not be confirmed. Try again.');
    }
  }
}
