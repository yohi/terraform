-- Table Existence Check Queries
-- Run these individually to verify tables exist and have data

-- Check Django Web table
SELECT COUNT(*) as django_web_count
FROM rcs_stg_web_logs."rcs-stg-django_web"
LIMIT 1;
