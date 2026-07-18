-- =============================================================================
-- Meridian Health Network — Operational SQL Analysis
-- 10 queries covering ED bottlenecks, readmissions, staffing, and no-shows.
-- Tested and verified against meridian_health.db (SQLite).
-- =============================================================================

-- =============================================================================
-- QUERY 1: MONTHLY ED WAIT TIME TREND WITH 3-MONTH ROLLING AVERAGE
-- Techniques: CTE, window function (AVG OVER ROWS BETWEEN), time series analysis
-- =============================================================================
-- BUSINESS OBJECTIVE: Answer "why are ED wait times increasing?" starting
-- with the trend itself, smoothed to separate real drift from monthly noise.
-- WHY IT MATTERS: Leadership needs to know if this is a step-change, a
-- steady climb, or seasonal noise before committing capital to a fix.
-- EXECUTIVE INTERPRETATION: A steadily climbing rolling average (not just a
-- few bad months) indicates a structural capacity problem, not a blip.
-- OPERATIONAL IMPACT: Justifies capacity investment vs. a temporary staffing
-- fix, depending on which pattern the trend actually shows.
-- =============================================================================
WITH monthly_wait AS (
    SELECT strftime('%Y-%m', visit_date) AS year_month,
           ROUND(AVG(wait_time_minutes), 1) AS avg_wait
    FROM fact_ed_visits
    GROUP BY year_month
)
SELECT
    year_month,
    avg_wait,
    ROUND(AVG(avg_wait) OVER (ORDER BY year_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 1) AS rolling_3mo_avg_wait
FROM monthly_wait
ORDER BY year_month;


-- =============================================================================
-- QUERY 2: ED BOTTLENECK RANKING BY HOSPITAL AND TRIAGE LEVEL
-- Techniques: window function (RANK), aggregate, multi-dimensional grouping
-- =============================================================================
-- BUSINESS OBJECTIVE: Identify exactly which hospital/severity combination
-- has the worst wait times, not just an overall network average.
-- WHY IT MATTERS: A network-wide average can hide one hospital in crisis.
-- EXECUTIVE INTERPRETATION: If the worst delays are concentrated in
-- low-acuity triage levels (3-5) at one hospital, that points to a
-- fast-track/urgent-care diversion fix, not more trauma capacity.
-- OPERATIONAL IMPACT: Targets the fix to the specific hospital and patient
-- segment actually driving the problem.
-- =============================================================================
SELECT
    h.hospital_name,
    e.triage_level,
    COUNT(*) AS visit_count,
    ROUND(AVG(e.wait_time_minutes), 1) AS avg_wait_minutes,
    RANK() OVER (ORDER BY AVG(e.wait_time_minutes) DESC) AS bottleneck_rank
FROM fact_ed_visits e
JOIN dim_hospitals h ON h.hospital_id = e.hospital_id
GROUP BY h.hospital_name, e.triage_level
ORDER BY avg_wait_minutes DESC
LIMIT 10;


-- =============================================================================
-- QUERY 3: 30-DAY READMISSION RATE BY DEPARTMENT, RANKED
-- Techniques: aggregate, window function (RANK), JOIN
-- =============================================================================
-- BUSINESS OBJECTIVE: Identify which departments contribute most to
-- avoidable readmissions.
-- WHY IT MATTERS: Readmissions are both a quality-of-care signal and a
-- direct cost driver (many payers penalize excess readmissions).
-- EXECUTIVE INTERPRETATION: Departments ranked highest need a discharge
-- process review before any blanket network-wide readmission initiative.
-- OPERATIONAL IMPACT: Focuses discharge-planning investment where it will
-- move the readmission rate the most.
-- =============================================================================
SELECT
    d.department_name,
    COUNT(*) AS total_admissions,
    SUM(a.readmitted_30d) AS readmissions,
    ROUND(AVG(a.readmitted_30d) * 100, 1) AS readmission_rate_pct,
    RANK() OVER (ORDER BY AVG(a.readmitted_30d) DESC) AS readmission_risk_rank
FROM fact_admissions a
JOIN dim_departments d ON d.department_id = a.department_id
GROUP BY d.department_name
ORDER BY readmission_rate_pct DESC;


-- =============================================================================
-- QUERY 4: NO-SHOW RATE BY APPOINTMENT TYPE AND LEAD TIME BAND
-- Techniques: CASE bucketing, aggregate, multi-dimensional grouping
-- =============================================================================
-- BUSINESS OBJECTIVE: Determine whether no-shows are driven by appointment
-- type, scheduling lead time, or both together.
-- WHY IT MATTERS: A generic "reduce no-shows" initiative is far less
-- effective than one targeted at the specific type/lead-time combination
-- actually driving the problem.
-- EXECUTIVE INTERPRETATION: If no-show rate rises sharply with lead time,
-- a reminder-call/text program timed close to the appointment date is the
-- highest-leverage fix.
-- OPERATIONAL IMPACT: Directly informs where to spend a limited patient
-- outreach/reminder budget.
-- =============================================================================
SELECT
    appointment_type,
    CASE
        WHEN lead_time_days <= 3 THEN '0-3 days'
        WHEN lead_time_days <= 7 THEN '4-7 days'
        WHEN lead_time_days <= 14 THEN '8-14 days'
        ELSE '15+ days'
    END AS lead_time_band,
    COUNT(*) AS scheduled_appointments,
    ROUND(SUM(CASE WHEN status = 'No-Show' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS no_show_rate_pct
FROM fact_appointments
GROUP BY appointment_type, lead_time_band
ORDER BY appointment_type,
    CASE lead_time_band WHEN '0-3 days' THEN 1 WHEN '4-7 days' THEN 2 WHEN '8-14 days' THEN 3 ELSE 4 END;


-- =============================================================================
-- QUERY 5: STAFFING SHORTFALL BY SHIFT AND DEPARTMENT
-- Techniques: aggregate, CASE, ranking
-- =============================================================================
-- BUSINESS OBJECTIVE: Quantify exactly how understaffed each shift/department
-- combination is relative to its own stated need.
-- WHY IT MATTERS: "We need more staff" is not actionable: "Night shift ED
-- runs at 78% of needed staffing" is a specific, budgetable gap.
-- EXECUTIVE INTERPRETATION: A consistent shortfall concentrated in Night
-- shifts points to a shift-differential/incentive problem, not a total
-- headcount problem.
-- OPERATIONAL IMPACT: Directly sizes the staffing gap leadership needs to
-- close, shift by shift.
-- =============================================================================
SELECT
    d.department_name,
    s.shift,
    ROUND(AVG(s.actual_staff * 1.0 / s.scheduled_staff) * 100, 1) AS pct_of_needed_staffing,
    ROUND(AVG(s.overtime_hours), 2) AS avg_overtime_hours,
    RANK() OVER (ORDER BY AVG(s.actual_staff * 1.0 / s.scheduled_staff) ASC) AS understaffing_severity_rank
FROM fact_staffing s
JOIN dim_departments d ON d.department_id = s.department_id
GROUP BY d.department_name, s.shift
ORDER BY pct_of_needed_staffing ASC
LIMIT 10;


-- =============================================================================
-- QUERY 6: LENGTH OF STAY OUTLIER FLAGGING BY DEPARTMENT
-- Techniques: CTE, CASE, aggregate, subquery
-- =============================================================================
-- BUSINESS OBJECTIVE: Identify departments with a disproportionate share of
-- extended-stay admissions (a common driver of bed occupancy pressure).
-- WHY IT MATTERS: A few very long stays can quietly consume bed capacity
-- that shows up network-wide as "we're always full," without leadership
-- realizing which department is actually holding the beds.
-- EXECUTIVE INTERPRETATION: Departments with a high extended-stay share are
-- the right target for a discharge-planning or step-down-unit investment.
-- OPERATIONAL IMPACT: Connects a bed-capacity complaint to a specific,
-- fixable department-level process issue.
-- =============================================================================
WITH los_flagged AS (
    SELECT
        department_id,
        length_of_stay_days,
        CASE WHEN length_of_stay_days > 7 THEN 1 ELSE 0 END AS is_extended_stay
    FROM fact_admissions
)
SELECT
    d.department_name,
    COUNT(*) AS total_admissions,
    ROUND(AVG(l.length_of_stay_days), 1) AS avg_los_days,
    SUM(l.is_extended_stay) AS extended_stay_count,
    ROUND(AVG(l.is_extended_stay) * 100, 1) AS extended_stay_pct
FROM los_flagged l
JOIN dim_departments d ON d.department_id = l.department_id
GROUP BY d.department_name
ORDER BY extended_stay_pct DESC;


-- =============================================================================
-- QUERY 7: DAY-OF-WEEK ED VOLUME VS. STAFFING MISMATCH
-- Techniques: CTE, JOIN, date analysis, aggregate
-- =============================================================================
-- BUSINESS OBJECTIVE: Check whether ED patient volume and ED staffing levels
-- actually move together across the week, or are structurally mismatched.
-- WHY IT MATTERS: If volume peaks on weekends while staffing doesn't scale
-- up accordingly, that mismatch — not total headcount — is the real driver
-- of weekend wait-time spikes.
-- EXECUTIVE INTERPRETATION: A visible gap between the volume curve and the
-- staffing curve on the same days is a scheduling-policy fix, not a hiring
-- problem.
-- OPERATIONAL IMPACT: Directly supports a shift-scheduling policy change
-- (e.g., weekend shift incentives) instead of a broader headcount increase.
-- =============================================================================
WITH ed_by_dow AS (
    SELECT strftime('%w', visit_date) AS dow, COUNT(*) AS visits
    FROM fact_ed_visits GROUP BY dow
),
staff_by_dow AS (
    SELECT strftime('%w', shift_date) AS dow, ROUND(AVG(actual_staff*1.0/scheduled_staff)*100,1) AS pct_staffed
    FROM fact_staffing WHERE department_id = 1 GROUP BY dow
)
SELECT
    CASE e.dow WHEN '0' THEN 'Sunday' WHEN '1' THEN 'Monday' WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday' WHEN '4' THEN 'Thursday' WHEN '5' THEN 'Friday' ELSE 'Saturday' END AS day_of_week,
    e.visits AS ed_visit_volume,
    s.pct_staffed AS ed_staffing_pct_of_need
FROM ed_by_dow e
JOIN staff_by_dow s ON s.dow = e.dow
ORDER BY e.dow;


-- =============================================================================
-- QUERY 8: MONTHLY READMISSION COHORT TREND
-- Techniques: CTE, date/cohort analysis, aggregate
-- =============================================================================
-- BUSINESS OBJECTIVE: Track whether the readmission rate is improving,
-- worsening, or flat over time, by admission month cohort.
-- WHY IT MATTERS: A single overall readmission rate hides whether a recent
-- discharge-process change (if any) actually helped.
-- EXECUTIVE INTERPRETATION: A rising trend across recent cohorts (not just
-- one bad month) signals a systemic discharge-process problem worth
-- escalating.
-- OPERATIONAL IMPACT: Enables before/after measurement for any future
-- discharge-planning intervention.
-- =============================================================================
SELECT
    strftime('%Y-%m', admission_date) AS admission_month,
    COUNT(*) AS admissions,
    SUM(readmitted_30d) AS readmissions,
    ROUND(AVG(readmitted_30d) * 100, 1) AS readmission_rate_pct
FROM fact_admissions
GROUP BY admission_month
ORDER BY admission_month;


-- =============================================================================
-- QUERY 9: COMPOUND ED BOTTLENECK RISK SCORE
-- Techniques: CTE, CASE, multi-factor scoring
-- =============================================================================
-- BUSINESS OBJECTIVE: Combine triage severity, wait time, and disposition
-- into a single transparent score identifying the visits most indicative of
-- systemic strain (as opposed to one slow individual visit).
-- WHY IT MATTERS: A single long wait could be a fluke: a cluster of
-- high-risk-score visits on the same day/hospital is a genuine capacity
-- signal.
-- EXECUTIVE INTERPRETATION: Days with a high concentration of high-risk-score
-- visits are the ones to investigate first for root cause (staffing gap that
-- day? Unusual volume spike?).
-- OPERATIONAL IMPACT: Gives operations leaders a prioritized worklist of
-- specific high-strain days/hospitals to investigate, instead of aggregate
-- statistics alone.
-- =============================================================================
WITH risk_scored AS (
    SELECT
        hospital_id, visit_date, triage_level, wait_time_minutes, disposition,
        (CASE WHEN wait_time_minutes > 90 THEN 2 ELSE 0 END) +
        (CASE WHEN triage_level <= 2 THEN 2 ELSE 0 END) +
        (CASE WHEN disposition = 'Left Without Being Seen' THEN 3 ELSE 0 END) AS bottleneck_risk_score
    FROM fact_ed_visits
)
SELECT
    hospital_id,
    visit_date,
    COUNT(*) AS visits_that_day,
    SUM(CASE WHEN bottleneck_risk_score >= 3 THEN 1 ELSE 0 END) AS high_risk_visits,
    ROUND(AVG(bottleneck_risk_score), 2) AS avg_risk_score
FROM risk_scored
GROUP BY hospital_id, visit_date
HAVING high_risk_visits >= 5
ORDER BY high_risk_visits DESC
LIMIT 15;


-- =============================================================================
-- QUERY 10: LEFT WITHOUT BEING SEEN (LWBS) RATE BY HOSPITAL, RANKED
-- Techniques: aggregate, window function (RANK), CASE
-- =============================================================================
-- BUSINESS OBJECTIVE: Measure the most severe ED failure mode — patients who
-- leave before being treated at all — by hospital.
-- WHY IT MATTERS: LWBS is both a patient-safety risk and a leading indicator
-- of ED overcrowding that precedes formal complaints or regulatory scrutiny.
-- EXECUTIVE INTERPRETATION: Any hospital with an LWBS rate meaningfully above
-- the network average needs immediate operational review, not a wait-and-see
-- approach.
-- OPERATIONAL IMPACT: A leading-indicator KPI that should sit on the
-- executive dashboard, not just a lagging satisfaction score.
-- =============================================================================
SELECT
    h.hospital_name,
    COUNT(*) AS total_visits,
    SUM(CASE WHEN e.disposition = 'Left Without Being Seen' THEN 1 ELSE 0 END) AS lwbs_count,
    ROUND(SUM(CASE WHEN e.disposition = 'Left Without Being Seen' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS lwbs_rate_pct,
    RANK() OVER (ORDER BY SUM(CASE WHEN e.disposition = 'Left Without Being Seen' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) DESC) AS lwbs_risk_rank
FROM fact_ed_visits e
JOIN dim_hospitals h ON h.hospital_id = e.hospital_id
GROUP BY h.hospital_name
ORDER BY lwbs_rate_pct DESC;
