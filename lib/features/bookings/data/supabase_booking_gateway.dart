import 'package:supabase_flutter/supabase_flutter.dart';

import 'booking_gateway.dart';

class SupabaseBookingGateway implements BookingGateway, AdminBookingGateway {
  SupabaseBookingGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<List<ScheduledClass>> loadUpcomingClasses() async {
    final rows = await _client
        .from('bookings')
        .select(
            'id, class_sessions!inner(starts_at, ends_at, class_series!inner(title, branches!inner(name)))')
        .eq('status', 'booked')
        .gt('class_sessions.starts_at',
            DateTime.now().toUtc().toIso8601String())
        .order('starts_at', referencedTable: 'class_sessions');
    final classes = (rows as List<dynamic>).map((row) {
      final session = row['class_sessions'] as Map<String, dynamic>;
      final series = session['class_series'] as Map<String, dynamic>;
      final branch = series['branches'] as Map<String, dynamic>;
      return ScheduledClass(
        id: row['id'] as String,
        title: series['title'] as String,
        branchName: branch['name'] as String,
        startsAt: DateTime.parse(session['starts_at'] as String).toLocal(),
        endsAt: DateTime.parse(session['ends_at'] as String).toLocal(),
      );
    }).toList()
      ..sort((first, second) => first.startsAt.compareTo(second.startsAt));
    return classes;
  }

  @override
  Future<List<DateTime>> loadCompletedClassDates() async {
    final rows = await _client
        .from('bookings')
        .select('class_sessions!inner(starts_at)')
        .eq('status', 'attended')
        .order('starts_at', referencedTable: 'class_sessions');
    return (rows as List<dynamic>).map((row) {
      final session = row['class_sessions'] as Map<String, dynamic>;
      return DateTime.parse(session['starts_at'] as String).toLocal();
    }).toList();
  }

  @override
  Future<List<FeedbackClass>> loadFeedbackClasses() async {
    final rows = await _client
        .from('bookings')
        .select(
            'id, class_sessions!inner(starts_at, class_series!inner(title, branches!inner(name))), class_feedback(enjoyment, difficulty)')
        .eq('status', 'attended')
        .order('starts_at',
            referencedTable: 'class_sessions', ascending: false);
    return (rows as List<dynamic>).map((row) {
      final session = row['class_sessions'] as Map<String, dynamic>;
      final series = session['class_series'] as Map<String, dynamic>;
      final branch = series['branches'] as Map<String, dynamic>;
      final rawFeedback = row['class_feedback'];
      final feedback = rawFeedback is Map<String, dynamic>
          ? rawFeedback
          : rawFeedback is List<dynamic> && rawFeedback.isNotEmpty
              ? rawFeedback.first as Map<String, dynamic>
              : null;
      return FeedbackClass(
        bookingId: row['id'] as String,
        title: series['title'] as String,
        branchName: branch['name'] as String,
        startsAt: DateTime.parse(session['starts_at'] as String).toLocal(),
        enjoyment: feedback?['enjoyment'] as int?,
        difficulty: feedback?['difficulty'] as int?,
      );
    }).toList();
  }

  @override
  Future<void> saveClassFeedback({
    required String bookingId,
    required int enjoyment,
    required int difficulty,
  }) =>
      _client.from('class_feedback').upsert({
        'booking_id': bookingId,
        'enjoyment': enjoyment,
        'difficulty': difficulty,
      }, onConflict: 'booking_id');

  @override
  Future<List<StudioBranch>> loadBranches() async {
    final rows =
        await _client.from('branches').select('id, name').eq('is_active', true);
    return (rows as List<dynamic>).map((row) {
      return StudioBranch(
        id: row['id'] as String,
        name: row['name'] as String,
      );
    }).toList();
  }

  @override
  Future<List<AdminFixedOffer>> loadFixedOffers() async {
    final rows = await _client
        .from('branch_offers')
        .select(
            'id, price_minor, membership_plans!inner(name), class_series!inner(capacity, branches!inner(name))')
        .eq('is_active', true)
        .order('created_at');
    return (rows as List<dynamic>).map((row) {
      final plan = row['membership_plans'] as Map<String, dynamic>;
      final series = row['class_series'] as Map<String, dynamic>;
      final branch = series['branches'] as Map<String, dynamic>;
      return AdminFixedOffer(
        id: row['id'] as String,
        title: plan['name'] as String,
        branchName: branch['name'] as String,
        capacity: series['capacity'] as int,
        priceMinor: row['price_minor'] as int,
      );
    }).toList();
  }

  @override
  Future<List<AdminAttendanceRecord>> loadPastAttendance() async {
    final rows = await _client
        .from('bookings')
        .select(
            'id, user_id, status, class_sessions!inner(starts_at, class_series!inner(title, branches!inner(name)))')
        .inFilter('status', ['booked', 'attended', 'no_show']).order(
            'starts_at',
            referencedTable: 'class_sessions');
    // PostgREST's embedded-resource date filter did not consistently return
    // matching rows for this relation. Fetch only attendance-eligible booking
    // statuses from the RLS-protected table, then apply the session-date rule
    // after decoding the joined session.
    final now = DateTime.now().toUtc();
    final pastRows = (rows as List<dynamic>).where((row) {
      final session = row['class_sessions'] as Map<String, dynamic>;
      return DateTime.parse(session['starts_at'] as String)
          .toUtc()
          .isBefore(now);
    }).toList();
    final memberIds =
        pastRows.map((row) => row['user_id'] as String).toSet().toList();
    final profileRows = memberIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _client
            .from('profiles')
            .select('id, display_name')
            .inFilter('id', memberIds);
    final namesByMemberId = {
      for (final profile in profileRows)
        profile['id'] as String: profile['display_name'] as String,
    };
    return pastRows.map((row) {
      final session = row['class_sessions'] as Map<String, dynamic>;
      final series = session['class_series'] as Map<String, dynamic>;
      final branch = series['branches'] as Map<String, dynamic>;
      final memberId = row['user_id'] as String;
      return AdminAttendanceRecord(
        bookingId: row['id'] as String,
        memberId: memberId,
        memberName: namesByMemberId[memberId] ?? 'Member',
        title: series['title'] as String,
        branchName: branch['name'] as String,
        startsAt: DateTime.parse(session['starts_at'] as String).toLocal(),
        status: row['status'] as String,
      );
    }).toList()
      ..sort((first, second) => first.startsAt.compareTo(second.startsAt));
  }

  @override
  Future<AdminTodayOperations> loadTodayOperations() async {
    final result = await _client.rpc('admin_today_operations');
    final data = result as Map<String, dynamic>;
    final classes = (data['classes'] as List<dynamic>).map((row) {
      final value = row as Map<String, dynamic>;
      return AdminTodayClass(
        title: value['title'] as String,
        branchName: value['branch_name'] as String,
        startsAt: DateTime.parse(value['starts_at'] as String).toLocal(),
        capacity: value['capacity'] as int,
        bookedCount: value['booked_count'] as int,
      );
    }).toList();
    final noShows = (data['no_shows'] as List<dynamic>).map((row) {
      final value = row as Map<String, dynamic>;
      return AdminNoShow(
        memberName: value['member_name'] as String,
        title: value['title'] as String,
        branchName: value['branch_name'] as String,
        startsAt: DateTime.parse(value['starts_at'] as String).toLocal(),
      );
    }).toList();
    final endingPackages =
        (data['ending_packages'] as List<dynamic>).map((row) {
      final value = row as Map<String, dynamic>;
      return AdminEndingPackage(
        memberName: value['member_name'] as String,
        packageName: value['package_name'] as String,
        endDate: DateTime.parse(value['end_date'] as String),
        remainingCredits: value['remaining_credits'] as int,
      );
    }).toList();
    final pendingPayments =
        (data['pending_payments'] as List<dynamic>).map((row) {
      final value = row as Map<String, dynamic>;
      return AdminPendingPayment(
        memberName: value['member_name'] as String,
        packageName: value['package_name'] as String,
        priceMinor: value['price_minor'] as int,
      );
    }).toList();
    return AdminTodayOperations(
      classes: classes,
      noShows: noShows,
      endingPackages: endingPackages,
      pendingPayments: pendingPayments,
    );
  }

  @override
  Future<void> recordAttendance({
    required String bookingId,
    required bool attended,
  }) =>
      _client.rpc('admin_record_booking_attendance', params: {
        'target_booking_id': bookingId,
        'target_status': attended ? 'attended' : 'no_show',
      });

  @override
  Future<String> createFixedOffer({
    required String name,
    required String branchId,
    required int priceMinor,
    required int capacity,
    required int totalClasses,
    required int sessionsPerWeek,
    required DateTime startsOn,
    required List<int> weekdays,
    required List<TimeOfDayValue> startTimes,
  }) async =>
      (await _client.rpc('admin_create_fixed_offer', params: {
        'target_name': name,
        'target_branch_id': branchId,
        'target_price_minor': priceMinor,
        'target_capacity': capacity,
        'target_total_credits': totalClasses,
        'target_sessions_per_week': sessionsPerWeek,
        'target_starts_on':
            '${startsOn.year.toString().padLeft(4, '0')}-${startsOn.month.toString().padLeft(2, '0')}-${startsOn.day.toString().padLeft(2, '0')}',
        'target_weekdays': weekdays,
        'target_start_times':
            startTimes.map((time) => time.databaseValue).toList(),
      })) as String;

  @override
  Future<void> deleteFixedOffer({required String offerId}) async {
    await _client.rpc('admin_delete_fixed_offer', params: {
      'target_offer_id': offerId,
    });
  }
}
