-- Run once per production project after applying
-- 20261015000100_operational_data_retention.sql and enabling pg_cron in the
-- Supabase Dashboard. Supabase Cron schedules use UTC: 00:15 UTC is 03:15 in
-- Istanbul while daylight saving time remains unchanged in Turkey.
--
-- Inspect existing jobs first: select jobid, jobname, schedule, command from cron.job;
-- If this job already exists, unschedule it before changing its schedule.
select cron.schedule(
  'backstreet-operational-retention',
  '15 0 * * *',
  $$select public.run_operational_retention();$$
);
