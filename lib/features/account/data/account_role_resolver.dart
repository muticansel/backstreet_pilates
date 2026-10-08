enum AccountRole { member, admin }

enum AccountApprovalStatus {
  awaitingEmailConfirmation,
  pendingAdminApproval,
  approved,
  inactive,
}

abstract interface class AccountRoleResolver {
  Future<AccountRole> currentRole();
}

/// Optional capability for resolvers backed by an account service.
/// Keeping this separate preserves the lightweight role resolver used by
/// previews and tests.
abstract interface class AccountApprovalResolver {
  Future<AccountApprovalStatus> currentApprovalStatus();
}

class MemberAccountRoleResolver implements AccountRoleResolver {
  const MemberAccountRoleResolver();

  @override
  Future<AccountRole> currentRole() async => AccountRole.member;
}
