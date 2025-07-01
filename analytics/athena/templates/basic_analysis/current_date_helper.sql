SELECT
  CAST(year(current_date) AS varchar) as current_year,
  LPAD(CAST(month(current_date) AS varchar), 2, '0') as current_month,
  LPAD(CAST(day(current_date) AS varchar), 2, '0') as current_day,
  LPAD(CAST(hour(current_timestamp) AS varchar), 2, '0') as current_hour
