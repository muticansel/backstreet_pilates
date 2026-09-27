class AdminDashboardData {
  const AdminDashboardData({
    required this.monthlySalesMinor,
    required this.completedSales,
    required this.activeMembers,
    required this.cashPaymentsToRecord,
    required this.members,
  });

  final int monthlySalesMinor;
  final int completedSales;
  final int activeMembers;
  final int cashPaymentsToRecord;
  final List<ActiveMember> members;

  static const preview = AdminDashboardData(
    monthlySalesMinor: 6840000,
    completedSales: 18,
    activeMembers: 34,
    cashPaymentsToRecord: 7,
    members: [
      ActiveMember(
        name: 'Aylin Demir',
        packageName: '8 class package',
        branchName: 'Oran',
        remainingCredits: 4,
        validUntil: '24 October',
      ),
      ActiveMember(
        name: 'Ece Yılmaz',
        packageName: '12 class package',
        branchName: 'İncek',
        remainingCredits: 9,
        validUntil: '02 November',
      ),
      ActiveMember(
        name: 'Selin Kaya',
        packageName: '20 class package',
        branchName: 'Oran',
        remainingCredits: 15,
        validUntil: '16 December',
      ),
    ],
  );
}

class ActiveMember {
  const ActiveMember({
    required this.name,
    required this.packageName,
    required this.branchName,
    required this.remainingCredits,
    required this.validUntil,
  });

  final String name;
  final String packageName;
  final String branchName;
  final int remainingCredits;
  final String validUntil;
}
