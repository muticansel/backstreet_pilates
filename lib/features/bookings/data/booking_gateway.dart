class ScheduledClass {
  const ScheduledClass(
      {required this.id,
      required this.title,
      required this.branchName,
      required this.startsAt,
      required this.endsAt});
  final String id;
  final String title;
  final String branchName;
  final DateTime startsAt;
  final DateTime endsAt;
}

class FeedbackClass {
  const FeedbackClass({
    required this.bookingId,
    required this.title,
    required this.branchName,
    required this.startsAt,
    this.enjoyment,
    this.difficulty,
  });

  final String bookingId;
  final String title;
  final String branchName;
  final DateTime startsAt;
  final int? enjoyment;
  final int? difficulty;

  bool get hasFeedback => enjoyment != null && difficulty != null;
}

abstract class BookingGateway {
  const BookingGateway();

  Future<List<ScheduledClass>> loadUpcomingClasses();
  Future<List<DateTime>> loadCompletedClassDates();
  Future<List<FeedbackClass>> loadFeedbackClasses() async => const [];
  Future<void> saveClassFeedback({
    required String bookingId,
    required int enjoyment,
    required int difficulty,
  }) async {}
}

class StudioBranch {
  const StudioBranch({required this.id, required this.name});

  final String id;
  final String name;
}

class AdminFixedOffer {
  const AdminFixedOffer({
    required this.id,
    required this.title,
    required this.branchName,
    required this.capacity,
    required this.priceMinor,
  });

  final String id;
  final String title;
  final String branchName;
  final int capacity;
  final int priceMinor;
}

class AdminAttendanceRecord {
  const AdminAttendanceRecord({
    required this.bookingId,
    required this.memberId,
    required this.memberName,
    required this.title,
    required this.branchName,
    required this.startsAt,
    required this.status,
  });

  final String bookingId;
  final String memberId;
  final String memberName;
  final String title;
  final String branchName;
  final DateTime startsAt;
  final String status;
}

class TimeOfDayValue {
  const TimeOfDayValue({required this.hour, required this.minute});

  final int hour;
  final int minute;

  String get databaseValue =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
}

abstract interface class AdminBookingGateway {
  Future<List<StudioBranch>> loadBranches();
  Future<List<AdminFixedOffer>> loadFixedOffers();
  Future<List<AdminAttendanceRecord>> loadPastAttendance();
  Future<void> recordAttendance({
    required String bookingId,
    required bool attended,
  });
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
  });
  Future<void> deleteFixedOffer({required String offerId});
}

class UnconfiguredBookingGateway extends BookingGateway {
  const UnconfiguredBookingGateway();
  @override
  Future<List<ScheduledClass>> loadUpcomingClasses() async => const [];

  @override
  Future<List<DateTime>> loadCompletedClassDates() async => const [];
}

class UnconfiguredAdminBookingGateway implements AdminBookingGateway {
  const UnconfiguredAdminBookingGateway();
  @override
  Future<List<StudioBranch>> loadBranches() async => const [];
  @override
  Future<List<AdminFixedOffer>> loadFixedOffers() async => const [];
  @override
  Future<List<AdminAttendanceRecord>> loadPastAttendance() async => const [];
  @override
  Future<void> recordAttendance({
    required String bookingId,
    required bool attended,
  }) async {}
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
      '';
  @override
  Future<void> deleteFixedOffer({required String offerId}) async {}
}
