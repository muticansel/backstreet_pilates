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

class PrivateLessonSlot {
  const PrivateLessonSlot({
    required this.startsAt,
    required this.isAvailable,
    required this.isDefaultClosed,
  });

  final DateTime startsAt;
  final bool isAvailable;
  final bool isDefaultClosed;
}

class AdminPrivateLessonEntry {
  const AdminPrivateLessonEntry({
    required this.id,
    required this.isBlock,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.memberName,
  });

  final String id;
  final bool isBlock;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final String? memberName;
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
  Future<List<PrivateLessonSlot>> loadPrivateLessonSlots(DateTime date) async =>
      const [];
  Future<void> requestPrivateLesson(DateTime startsAt) async {}
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

  AdminAttendanceRecord copyWith({String? status}) => AdminAttendanceRecord(
        bookingId: bookingId,
        memberId: memberId,
        memberName: memberName,
        title: title,
        branchName: branchName,
        startsAt: startsAt,
        status: status ?? this.status,
      );
}

class AdminIndividualLessonMember {
  const AdminIndividualLessonMember({required this.id, required this.name});
  final String id;
  final String name;
}

class AdminIndividualLessonRecord {
  const AdminIndividualLessonRecord({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.lessonDate,
    required this.lessonPriceMinor,
    required this.rateBasisPoints,
    required this.earningMinor,
  });
  final String id;
  final String memberId;
  final String memberName;
  final DateTime lessonDate;
  final int lessonPriceMinor;
  final int rateBasisPoints;
  final int earningMinor;
}

/// The operations snapshot is deliberately assembled by one admin-only RPC so
/// every card uses the same Istanbul calendar day.
class AdminTodayOperations {
  const AdminTodayOperations({
    required this.classes,
    required this.noShows,
    required this.endingPackages,
    required this.pendingPayments,
  });

  final List<AdminTodayClass> classes;
  final List<AdminNoShow> noShows;
  final List<AdminEndingPackage> endingPackages;
  final List<AdminPendingPayment> pendingPayments;
}

class AdminTodayClass {
  const AdminTodayClass({
    required this.title,
    required this.branchName,
    required this.startsAt,
    required this.capacity,
    required this.bookedCount,
  });

  final String title;
  final String branchName;
  final DateTime startsAt;
  final int capacity;
  final int bookedCount;
}

class AdminNoShow {
  const AdminNoShow({
    required this.memberName,
    required this.title,
    required this.branchName,
    required this.startsAt,
  });

  final String memberName;
  final String title;
  final String branchName;
  final DateTime startsAt;
}

class AdminEndingPackage {
  const AdminEndingPackage({
    required this.memberName,
    required this.packageName,
    required this.endDate,
    required this.remainingCredits,
  });

  final String memberName;
  final String packageName;
  final DateTime endDate;
  final int remainingCredits;
}

class AdminPendingPayment {
  const AdminPendingPayment({
    required this.memberName,
    required this.packageName,
    required this.priceMinor,
  });

  final String memberName;
  final String packageName;
  final int priceMinor;
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
  Future<AdminTodayOperations> loadTodayOperations();
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
  Future<List<AdminIndividualLessonMember>> loadIndividualLessonMembers();
  Future<List<AdminIndividualLessonRecord>> loadIndividualLessons();
  Future<void> recordIndividualLesson({
    required String memberId,
    required DateTime lessonDate,
    required int lessonPriceMinor,
    required int rateBasisPoints,
  });
  Future<List<AdminPrivateLessonEntry>> loadPrivateLessonCalendar(
      DateTime weekStart);
  Future<void> blockPrivateLessonTime({
    required DateTime startsAt,
    required DateTime endsAt,
  });
  Future<void> deletePrivateLessonBlock({required String blockId});
  Future<void> resolvePrivateLessonRequest({
    required String requestId,
    required bool approve,
  });
}

class UnconfiguredBookingGateway extends BookingGateway {
  const UnconfiguredBookingGateway();
  @override
  Future<List<ScheduledClass>> loadUpcomingClasses() async => const [];

  @override
  Future<List<DateTime>> loadCompletedClassDates() async => const [];

  @override
  Future<List<PrivateLessonSlot>> loadPrivateLessonSlots(DateTime date) async =>
      const [];

  @override
  Future<void> requestPrivateLesson(DateTime startsAt) async {}
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
  Future<AdminTodayOperations> loadTodayOperations() async =>
      const AdminTodayOperations(
        classes: [],
        noShows: [],
        endingPackages: [],
        pendingPayments: [],
      );
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
  @override
  Future<List<AdminIndividualLessonMember>>
      loadIndividualLessonMembers() async => const [];
  @override
  Future<List<AdminIndividualLessonRecord>> loadIndividualLessons() async =>
      const [];
  @override
  Future<void> recordIndividualLesson({
    required String memberId,
    required DateTime lessonDate,
    required int lessonPriceMinor,
    required int rateBasisPoints,
  }) async {}
  @override
  Future<List<AdminPrivateLessonEntry>> loadPrivateLessonCalendar(
          DateTime weekStart) async =>
      const [];
  @override
  Future<void> blockPrivateLessonTime({
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {}
  @override
  Future<void> deletePrivateLessonBlock({required String blockId}) async {}
  @override
  Future<void> resolvePrivateLessonRequest({
    required String requestId,
    required bool approve,
  }) async {}
}
