enum AccountRole { member, admin }

abstract interface class AccountRoleResolver {
  Future<AccountRole> currentRole();
}

class MemberAccountRoleResolver implements AccountRoleResolver {
  const MemberAccountRoleResolver();

  @override
  Future<AccountRole> currentRole() async => AccountRole.member;
}
