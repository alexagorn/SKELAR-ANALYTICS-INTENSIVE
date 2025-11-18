#Наскільки служба підтримки відповідає очікуванням менеджменту? Як вона працює зараз?
CREATE OR REPLACE VIEW `project.dataset.view_avg_time_by_team` AS
SELECT  t.team, 
date(t.request_time) as day,
round(avg(date_diff(t.finish_time, t.request_time, minute)), 2) as avg_handle_time_min,
round(avg(date_diff(t.finish_time, t.start_time, minute)), 2) as avg_solution_time_min
FROM `media-promo-2025.dark_diagram_4592.Task2` t
group by day, t.team
order by avg_handle_time_min ASC;


SELECT  e.moderator, 
date(e.request_time) as day,
round(avg(date_diff(e.finish_time, e.request_time, minute)), 2) as avg_handle_time_min_m,
round(avg(date_diff(e.finish_time, e.start_time, minute)), 2) as avg_solution_time_min_m
FROM `media-promo-2025`.dark_diagram_4592.Task2 AS e
group by day, e.moderator
order by avg_handle_time_min_m desc;

SELECT  e.moderator, 
date(e.request_time) as day,
round(avg(date_diff(e.finish_time, e.request_time, minute)), 2) as avg_handle_time_min_m,
round(avg(date_diff(e.finish_time, e.start_time, minute)), 2) as avg_solution_time_min_m
FROM `media-promo-2025`.dark_diagram_4592.Task2 AS e
WHERE DATE(request_time) NOT BETWEEN '2020-10-21' AND '2020-10-28'
group by day, e.moderator
order by avg_handle_time_min_m desc;


#На яких агентів варто звернути увагу задля підвищення якості обслуговування?
CREATE OR REPLACE VIEW `project.dataset.view_avg_time_by_moderator` AS
WITH
  avg_time_by_team_overall AS (
    SELECT
      team,
      ROUND(avg(DATE_DIFF(start_time, request_time, MINUTE)), 2) AS avg_minutes_for_handle_by_team_overall
    FROM
      `media-promo-2025`.dark_diagram_4592.Task2
    GROUP BY team
  ),
  avg_time_by_moderator_overall AS (
    SELECT
      moderator,
      team,
      ROUND(AVG(DATE_DIFF(finish_time, request_time, MINUTE)), 2) AS avg_minutes_for_handle_by_moderator_overall
    FROM
      `media-promo-2025`.dark_diagram_4592.Task2
    GROUP BY moderator, team
  )
SELECT
  m.moderator,
  m.avg_minutes_for_handle_by_moderator_overall,
  t.avg_minutes_for_handle_by_team_overall,
  m.team
FROM
  avg_time_by_moderator_overall AS m
  JOIN
  avg_time_by_team_overall AS t
  ON m.team = t.team
WHERE
  m.avg_minutes_for_handle_by_moderator_overall > t.avg_minutes_for_handle_by_team_overall
ORDER BY m.moderator;


#Кількість унікальних звернень по кожному модератору
SELECT 
  COUNT (DISTINCT id_request) as count_of_requests, 
  moderator,
  team
FROM `media-promo-2025`.dark_diagram_4592.Task2
GROUP BY moderator, team

#В які години доби приходить найбільше запитів для команд?
CREATE OR REPLACE VIEW `project.dataset.view_requests_by_hour` AS
SELECT 
    EXTRACT(HOUR FROM request_time) AS hour_of_day,
    COUNT(DISTINCT id_request) AS requests_count,
    team
FROM `media-promo-2025.dark_diagram_4592.Task2`
GROUP BY hour_of_day, team
ORDER BY hour_of_day DESC;


#Чи варто збільшити команду підтримки і наскільки?
select count(distinct (moderator)) as numbr_of_people_in_team
from `media-promo-2025.dark_diagram_4592.Task2` t
group by team


#Середня кількість оброблених звернень одним модератором за день
SELECT moderator,
    round(AVG(requests_processed_per_day), 2) AS avg_requests_per_day
FROM (
    SELECT
        moderator,
        DATE(request_time) AS day,
        COUNT(*) AS requests_processed_per_day
    FROM `media-promo-2025.dark_diagram_4592.Task2`
    GROUP BY moderator, day
)
GROUP BY moderator;

#capacity_per_day = кількість модераторів × середня кількість оброблених звернень одним модератором за день
CREATE OR REPLACE VIEW `project.dataset.view_team_capacity` AS
WITH
  requests_per_moderator_per_day AS (
    SELECT
      team,
      moderator,
      DATE(start_time) AS day,
      COUNT(DISTINCT id_request) AS requests_processed
    FROM
      `media-promo-2025`.dark_diagram_4592.Task2
    GROUP BY team, moderator, DATE(start_time)
  ),
  avg_requests_per_moderator AS (
    SELECT
      team,
      ROUND(AVG(requests_processed), 2) AS avg_requests_per_day_per_moderator
    FROM
      requests_per_moderator_per_day
    GROUP BY team
  ),
  daily_requests_summary AS (
    SELECT
      team,
      DATE(start_time) AS day,
      COUNT(DISTINCT id_request) AS unique_requests_per_day
    FROM
      `media-promo-2025`.dark_diagram_4592.Task2
    GROUP BY team, DATE(start_time)
  ),
  avg_daily_unique_requests AS (
    SELECT
      team,
      ROUND(AVG(unique_requests_per_day), 2) AS avg_unique_requests_per_team_per_day
    FROM
      daily_requests_summary
    GROUP BY team
  )
SELECT
  a.team,
  COUNT(DISTINCT r.moderator) AS moderators_count,
  COUNT(DISTINCT r.moderator) * a.avg_requests_per_day_per_moderator AS capacity_per_day,
  a.avg_requests_per_day_per_moderator,
  adu.avg_unique_requests_per_team_per_day
FROM
  requests_per_moderator_per_day AS r
  JOIN
  avg_requests_per_moderator AS a
  ON r.team = a.team
  LEFT JOIN
  avg_daily_unique_requests AS adu
  ON a.team = adu.team
GROUP BY a.team, a.avg_requests_per_day_per_moderator, adu.avg_unique_requests_per_team_per_day
ORDER BY a.team;






#кількість звернень по днях тижня 
CREATE OR REPLACE VIEW `project.dataset.view_avg_requests_by_month_by_teams` AS
WITH monthly_requests AS (
    SELECT
        team,
        DATE(start_time) AS day,
        COUNT(DISTINCT id_request) AS unique_requests_per_day
    FROM `media-promo-2025.dark_diagram_4592.Task2`
    GROUP BY team, day
)
SELECT
    team,
    EXTRACT(dayofweek FROM day) AS weekday_num,
    SUM(unique_requests_per_day) AS sum_requests
FROM monthly_requests
GROUP BY weekday_num, team
ORDER BY weekday_num;






#Середня кількість оброблених звернень командами за день
CREATE OR REPLACE VIEW `project.dataset.view_avg_requests_by_day_by_team` AS
WITH daily_requests AS (
    SELECT
        team,
        DATE(start_time) AS day,
        COUNT(DISTINCT id_request) AS unique_requests_per_day
    FROM `media-promo-2025.dark_diagram_4592.Task2`
    GROUP BY team, day
)

SELECT
    team,
    ROUND(AVG(unique_requests_per_day), 2) AS avg_unique_requests_per_day
FROM daily_requests
GROUP BY team
ORDER BY team;



#Як варто змінити графік служби підтримки?
Як варто змінити графік служби підтримки команди платформи для гуртового продажу.


#Чи є вигода від об'єднання команд?
Так, є


