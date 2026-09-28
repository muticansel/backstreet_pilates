# Page 08: Member profile

Status: awaiting user review.

The member dashboard header has a round profile control. It opens a profile
page where the signed-in member can edit name, email, phone number, date of
birth and gender. The page reads and updates only the member's own RLS-protected
`profiles` row.

Email is managed by Supabase Auth rather than the public profile table. An email
change asks the member to confirm the new address through the existing app
redirect URL. The app never reads or stores passwords.

The round control and page avatar currently show a person icon or name initials.
Actual photo upload is intentionally deferred until Storage, image size limits,
and deletion/privacy rules are reviewed.

Apply `20260929000200_add_member_profile_fields.sql` before using birth date or
gender fields in Supabase.
