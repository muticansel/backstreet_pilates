import { createClient } from 'npm:@supabase/supabase-js@2'

const cors = { 'Content-Type': 'application/json' }

Deno.serve(async (request) => {
  const auth = request.headers.get('Authorization')
  if (!auth) return Response.json({ error: 'Sign in required' }, { status: 401, headers: cors })
  const userClient = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: auth } },
  })
  const { data: { user } } = await userClient.auth.getUser()
  if (!user) return Response.json({ error: 'Sign in required' }, { status: 401, headers: cors })
  const { data: role } = await userClient.from('user_roles').select('role').eq('user_id', user.id).single()
  if (role?.role !== 'admin') return Response.json({ error: 'Admin access required' }, { status: 403, headers: cors })

  const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)
  const { action, userId } = await request.json()
  if (!['list', 'approve', 'activate', 'deactivate', 'send_password_reset'].includes(action)) {
    return Response.json({ error: 'Invalid request' }, { status: 400, headers: cors })
  }
  if (action === 'list') {
    const [{ data: users }, { data: profiles }] = await Promise.all([
      admin.auth.admin.listUsers({ perPage: 1000 }),
      admin.from('profiles').select('id, display_name, is_active, approval_status'),
    ])
    const profileById = new Map((profiles ?? []).map((profile) => [profile.id, profile]))
    return Response.json({ users: (users?.users ?? []).map((target) => ({
      id: target.id, email: target.email, displayName: profileById.get(target.id)?.display_name ?? '',
      isActive: profileById.get(target.id)?.is_active ?? true,
      approvalStatus: profileById.get(target.id)?.approval_status ?? 'awaiting_email_confirmation',
    })) }, { headers: cors })
  }
  if (!userId) return Response.json({ error: 'Invalid request' }, { status: 400, headers: cors })
  if (userId === user.id) return Response.json({ error: 'You cannot change your own account status here' }, { status: 400, headers: cors })

  if (action === 'approve') {
    const { data: target, error: lookupError } = await admin.auth.admin.getUserById(userId)
    if (lookupError || !target.user.email_confirmed_at) {
      return Response.json({ error: 'Email confirmation is required before approval' }, { status: 400, headers: cors })
    }
    const { error } = await admin.from('profiles').update({
      approval_status: 'approved', approved_at: new Date().toISOString(), approved_by: user.id,
    }).eq('id', userId).eq('approval_status', 'pending_admin_approval')
    if (error) return Response.json({ error: error.message }, { status: 400, headers: cors })
  }

  if (action === 'deactivate') {
    const { error } = await admin.auth.admin.updateUserById(userId, { ban_duration: '876000h' })
    if (error) return Response.json({ error: error.message }, { status: 400, headers: cors })
    await admin.auth.admin.signOut(userId, 'global')
    await admin.from('profiles').update({ is_active: false, deactivated_at: new Date().toISOString(), deactivated_by: user.id }).eq('id', userId)
  }
  if (action === 'activate') {
    const { error } = await admin.auth.admin.updateUserById(userId, { ban_duration: 'none' })
    if (error) return Response.json({ error: error.message }, { status: 400, headers: cors })
    await admin.from('profiles').update({ is_active: true, deactivated_at: null, deactivated_by: null }).eq('id', userId)
  }
  if (action === 'send_password_reset') {
    const { data: target, error: lookupError } = await admin.auth.admin.getUserById(userId)
    if (lookupError || !target.user.email) return Response.json({ error: 'User email could not be found' }, { status: 400, headers: cors })
    const { error } = await admin.auth.resetPasswordForEmail(target.user.email, { redirectTo: 'backstreetpilates://login-callback/' })
    if (error) return Response.json({ error: error.message }, { status: 400, headers: cors })
  }
  return Response.json({ ok: true }, { headers: cors })
})
