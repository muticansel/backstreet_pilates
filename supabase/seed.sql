-- DEVELOPMENT ONLY. Fictional prices, not approved for sales.
-- Repeatable: never overwrites manually edited catalog records.
begin;
insert into public.branches(code, name) values ('oran', 'Oran'), ('incek', 'İncek')
on conflict (code) do nothing;

insert into public.membership_plans
  (code, name, total_credits, sessions_per_week, duration_weeks, is_active)
values
  ('demo-8-2-4', 'ÖRNEK: 8 ders / haftada 2 / 4 hafta', 8, 2, 4, false),
  ('demo-8-1-8', 'ÖRNEK: 8 ders / haftada 1 / 8 hafta', 8, 1, 8, false),
  ('demo-12-2-6', 'ÖRNEK: 12 ders / haftada 2 / 6 hafta', 12, 2, 6, false),
  ('demo-20-2-10', 'ÖRNEK: 20 ders / haftada 2 / 10 hafta', 20, 2, 10, false),
  ('demo-24-2-12', 'ÖRNEK: 24 ders / haftada 2 / 12 hafta', 24, 2, 12, false)
on conflict (code) do nothing;

-- Oran: fictional 500 TRY/lesson; İncek: fictional 600 TRY/lesson.
insert into public.branch_offers(branch_id, plan_id, price_minor, is_active)
select b.id, p.id, p.total_credits * case b.code when 'oran' then 50000 else 60000 end, false
from public.branches b cross join public.membership_plans p
where b.code in ('oran', 'incek')
  and p.code in ('demo-8-2-4', 'demo-8-1-8', 'demo-12-2-6', 'demo-20-2-10', 'demo-24-2-12')
on conflict (branch_id, plan_id) do nothing;
commit;
