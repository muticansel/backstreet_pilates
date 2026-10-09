-- Allow an administrator to reopen time they previously blocked. This never
-- touches a member request or an approved private lesson.
begin;

create function public.admin_delete_private_lesson_block(target_block_id uuid)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if not (select private.is_admin()) then raise exception 'Admin access required'; end if;
  delete from public.private_lesson_blocks
  where id = target_block_id and instructor_user_id = (select auth.uid());
  if not found then raise exception 'Blocked time was not found'; end if;
end;
$$;
revoke all on function public.admin_delete_private_lesson_block(uuid) from public, anon, authenticated;
grant execute on function public.admin_delete_private_lesson_block(uuid) to authenticated;

commit;
