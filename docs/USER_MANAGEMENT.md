# Admin user management

Apply `20260929000300_member_account_status.sql`, then deploy:

`supabase functions deploy admin-user-management`

The function requires an authenticated caller, independently checks the caller's
database admin role, and keeps the service-role key in Supabase only. It can
activate/deactivate an account and send a password reset link. Deactivation
bans the Auth account and globally signs out all sessions.
