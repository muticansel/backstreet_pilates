import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_role_resolver.dart';

class SupabaseAccountRoleResolver implements AccountRoleResolver {
  SupabaseAccountRoleResolver(this._client);

  final SupabaseClient _client;

  @override
  Future<AccountRole> currentRole() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return AccountRole.member;
    try {
      final role = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();
      final resolved =
          role?['role'] == 'admin' ? AccountRole.admin : AccountRole.member;
      debugPrint('Account role resolved: ${resolved.name}');
      return resolved;
    } catch (error) {
      // A failed role lookup must never promote a member to administrator.
      debugPrint('Account role lookup failed: $error');
      return AccountRole.member;
    }
  }
}
