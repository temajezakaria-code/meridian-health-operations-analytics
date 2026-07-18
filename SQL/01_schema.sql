-- =============================================================================
-- Meridian Health Network — Operational Analytics Database Schema
-- =============================================================================
-- Business scenario: a 4-hospital regional health network experiencing rising
-- ED wait times, appointment no-shows, uneven staffing, and readmissions.
-- Star schema: 2 dimensions (hospitals, departments) + 4 fact tables at
-- different operational grains (ED visit, admission, appointment, shift).
-- =============================================================================

CREATE TABLE dim_hospitals (
    hospital_id     INTEGER PRIMARY KEY,
    hospital_name   VARCHAR(60) NOT NULL,
    region          VARCHAR(30) NOT NULL,
    type            VARCHAR(30) NOT NULL,   -- Academic Medical Center / Community / Regional
    bed_capacity    INTEGER NOT NULL
);

CREATE TABLE dim_departments (
    department_id    INTEGER PRIMARY KEY,
    department_name  VARCHAR(30) NOT NULL,
    department_type   VARCHAR(20) NOT NULL   -- Emergency / Inpatient / Outpatient
);

-- Grain: one row per ED visit
CREATE TABLE fact_ed_visits (
    ed_visit_id            INTEGER PRIMARY KEY,
    hospital_id            INTEGER NOT NULL REFERENCES dim_hospitals(hospital_id),
    visit_date             DATE NOT NULL,
    triage_level           INTEGER NOT NULL,   -- 1 (most critical) - 5 (least urgent), ESI scale
    wait_time_minutes      DECIMAL(6,1) NOT NULL,
    treatment_time_minutes DECIMAL(6,1) NOT NULL,
    disposition            VARCHAR(30) NOT NULL, -- Discharged / Admitted / Transferred / Left Without Being Seen
    age_group              VARCHAR(10) NOT NULL
);

-- Grain: one row per inpatient admission
CREATE TABLE fact_admissions (
    admission_id              INTEGER PRIMARY KEY,
    hospital_id               INTEGER NOT NULL REFERENCES dim_hospitals(hospital_id),
    department_id             INTEGER NOT NULL REFERENCES dim_departments(department_id),
    admission_date             DATE NOT NULL,
    discharge_date              DATE NOT NULL,
    length_of_stay_days         DECIMAL(5,1) NOT NULL,
    source                      VARCHAR(30) NOT NULL,  -- Emergency Department / Direct Admission / Transfer
    readmitted_30d              INTEGER NOT NULL,       -- 1/0 readmitted within 30 days
    discharge_disposition        VARCHAR(30),
    patient_satisfaction_score  INTEGER               -- 1-5
);

-- Grain: one row per scheduled outpatient appointment
CREATE TABLE fact_appointments (
    appointment_id    INTEGER PRIMARY KEY,
    hospital_id        INTEGER NOT NULL REFERENCES dim_hospitals(hospital_id),
    department_id       INTEGER NOT NULL REFERENCES dim_departments(department_id),
    scheduled_date       DATE NOT NULL,
    appointment_type    VARCHAR(20) NOT NULL,  -- New Patient / Follow-up / Annual Physical / Procedure
    lead_time_days       INTEGER NOT NULL,      -- days between scheduling and appointment date
    status               VARCHAR(15) NOT NULL   -- Completed / No-Show / Cancelled / Rescheduled
);

-- Grain: one row per department-shift-day staffing record
CREATE TABLE fact_staffing (
    staffing_id       INTEGER PRIMARY KEY,
    hospital_id        INTEGER NOT NULL REFERENCES dim_hospitals(hospital_id),
    department_id        INTEGER NOT NULL REFERENCES dim_departments(department_id),
    shift_date            DATE NOT NULL,
    shift                 VARCHAR(10) NOT NULL,  -- Day / Evening / Night
    scheduled_staff        INTEGER NOT NULL,
    actual_staff            INTEGER NOT NULL,
    overtime_hours           DECIMAL(5,1) NOT NULL
);

CREATE INDEX idx_ed_hospital_date ON fact_ed_visits(hospital_id, visit_date);
CREATE INDEX idx_adm_dept ON fact_admissions(department_id);
CREATE INDEX idx_adm_date ON fact_admissions(admission_date);
CREATE INDEX idx_appt_dept_date ON fact_appointments(department_id, scheduled_date);
CREATE INDEX idx_staff_hospital_dept ON fact_staffing(hospital_id, department_id, shift_date);

-- =============================================================================
-- Note: this dataset is entirely synthetic. Real multi-hospital operational
-- data at this granularity is protected health information (HIPAA) and is
-- not available as a combined public dataset — this generator (see
-- data/generate_data.py) builds realistic, documented operational patterns
-- so the analysis has genuine signal to uncover, exactly like a real
-- hospital network's data would.
-- =============================================================================
