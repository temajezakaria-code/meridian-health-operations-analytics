"""
Meridian Health Network — Synthetic Operational Data Generator
==================================================================
Business scenario: a 4-hospital regional health network with emergency
departments, inpatient specialty units, outpatient clinics, and staffing
across 3 years (2023-2025). Real multi-hospital operational data of this kind
is protected health information (HIPAA) and not available as a combined
public dataset — this generator builds a realistic, fictional dataset with
deliberate, documented operational patterns (ED overcrowding, seasonal
surges, weekday/weekend staffing mismatches, discharge delays) so the
analysis has genuine signal to find, exactly like a real hospital network's
data would.

Output: 4 dimension/fact CSVs + a loaded SQLite database.
"""
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
import random

random.seed(42)
np.random.seed(42)

OUT_DIR = "/home/claude/meridian-health/data"
START_DATE = datetime(2023, 1, 1)
END_DATE = datetime(2025, 12, 31)
N_DAYS = (END_DATE - START_DATE).days + 1

# ---------------------------------------------------------------------------
# DIMENSION: HOSPITALS
# ---------------------------------------------------------------------------
hospitals = pd.DataFrame([
    {"hospital_id": 1, "hospital_name": "Meridian Downtown Medical Center", "region": "Urban Core",   "type": "Academic Medical Center", "bed_capacity": 420},
    {"hospital_id": 2, "hospital_name": "Meridian Northside Community",      "region": "North Suburbs","type": "Community Hospital",       "bed_capacity": 180},
    {"hospital_id": 3, "hospital_name": "Meridian Westview Regional",        "region": "West Region",  "type": "Regional Hospital",         "bed_capacity": 260},
    {"hospital_id": 4, "hospital_name": "Meridian East County",              "region": "East County",  "type": "Community Hospital",       "bed_capacity": 140},
])

# ---------------------------------------------------------------------------
# DIMENSION: DEPARTMENTS
# ---------------------------------------------------------------------------
departments = pd.DataFrame([
    {"department_id": 1, "department_name": "Emergency",        "department_type": "Emergency"},
    {"department_id": 2, "department_name": "Cardiology",       "department_type": "Inpatient"},
    {"department_id": 3, "department_name": "Orthopedics",      "department_type": "Inpatient"},
    {"department_id": 4, "department_name": "Oncology",         "department_type": "Inpatient"},
    {"department_id": 5, "department_name": "General Surgery",  "department_type": "Inpatient"},
    {"department_id": 6, "department_name": "Pediatrics",       "department_type": "Inpatient"},
    {"department_id": 7, "department_name": "Internal Medicine","department_type": "Inpatient"},
    {"department_id": 8, "department_name": "Outpatient Clinic","department_type": "Outpatient"},
])

inpatient_dept_ids = departments[departments["department_type"]=="Inpatient"]["department_id"].tolist()
outpatient_dept_ids = [7, 8]  # Internal Medicine and Outpatient Clinic also run outpatient appointments
all_dept_ids = departments["department_id"].tolist()

def seasonal_factor(date):
    """Winter respiratory surge (Dec-Feb) + summer trauma bump (Jun-Aug)."""
    m = date.month
    if m in (12, 1, 2):
        return 1.35
    if m in (6, 7, 8):
        return 1.15
    return 1.0

def weekday_factor(date):
    return 1.2 if date.weekday() in (4, 5, 6) else 1.0  # Fri/Sat/Sun ED bump

# ---------------------------------------------------------------------------
# FACT: ED VISITS
# ---------------------------------------------------------------------------
print("Generating ED visits...")
ed_rows = []
ed_id = 1
hospital_ed_base = {1: 55, 2: 22, 3: 34, 4: 16}  # bigger hospitals see more ED volume
YEAR_GROWTH = {2023: 1.0, 2024: 1.08, 2025: 1.17}  # rising ED demand over time (real trend nationally)

for d in range(N_DAYS):
    date = START_DATE + timedelta(days=d)
    for hid, base_visits in hospital_ed_base.items():
        lam = base_visits * seasonal_factor(date) * weekday_factor(date) * YEAR_GROWTH[date.year]
        n_visits = np.random.poisson(lam)
        for _ in range(n_visits):
            triage = np.random.choice([1,2,3,4,5], p=[0.03,0.15,0.42,0.30,0.10])  # ESI scale, 1=most critical
            # Base wait time worsens with lower hospital capacity headroom & higher triage number (less urgent = waits longer)
            # and gets structurally worse over the 3 years (the "why is ED wait time increasing" story)
            base_wait = {1:8, 2:15, 3:35, 4:55, 5:70}[triage]
            capacity_strain = 1.0 + (YEAR_GROWTH[date.year] - 1.0) * 2.2  # wait times grow faster than visit volume (real bottleneck dynamic)
            wait_time = max(2, np.random.normal(base_wait * capacity_strain * seasonal_factor(date), base_wait*0.35))
            treatment_time = max(10, np.random.normal(90 if triage<=2 else 60, 25))
            disposition = np.random.choice(
                ["Discharged","Admitted","Transferred","Left Without Being Seen"],
                p=[0.68, 0.22, 0.03, 0.07] if triage <= 3 else [0.82, 0.10, 0.01, 0.07]
            )
            ed_rows.append({
                "ed_visit_id": ed_id, "hospital_id": hid, "visit_date": date.date().isoformat(),
                "triage_level": int(triage), "wait_time_minutes": round(wait_time,1),
                "treatment_time_minutes": round(treatment_time,1), "disposition": disposition,
                "age_group": np.random.choice(["0-17","18-34","35-54","55-74","75+"], p=[0.12,0.22,0.28,0.24,0.14]),
            })
            ed_id += 1

ed_visits = pd.DataFrame(ed_rows)
print(f"  ED visits: {len(ed_visits):,} rows")

# ---------------------------------------------------------------------------
# FACT: ADMISSIONS (from ED + direct/transfer admissions)
# ---------------------------------------------------------------------------
print("Generating admissions...")
adm_rows = []
adm_id = 1

# Admissions sourced from ED
ed_admitted = ed_visits[ed_visits["disposition"] == "Admitted"].copy()
for _, row in ed_admitted.iterrows():
    dept = random.choice(inpatient_dept_ids)
    admit_date = datetime.fromisoformat(row["visit_date"])
    los_base = {2:4.5, 3:3.8, 4:6.5, 5:4.2, 6:3.0, 7:4.8}[dept]
    los = max(1, np.random.gamma(shape=2.2, scale=los_base/2.2))
    discharge_date = admit_date + timedelta(days=round(los))
    readmit_risk = 0.09 + (0.05 if dept in (4,7) else 0) + (0.03 if los > 7 else 0)
    adm_rows.append({
        "admission_id": adm_id, "hospital_id": row["hospital_id"], "department_id": dept,
        "admission_date": admit_date.date().isoformat(), "discharge_date": discharge_date.date().isoformat(),
        "length_of_stay_days": round(los,1), "source": "Emergency Department",
        "readmitted_30d": int(np.random.random() < readmit_risk),
        "discharge_disposition": np.random.choice(["Home","Skilled Nursing Facility","Rehab","Home Health"], p=[0.62,0.16,0.12,0.10]),
        "patient_satisfaction_score": int(np.clip(np.random.normal(3.9 - (0.4 if los>7 else 0), 0.8), 1, 5)),
    })
    adm_id += 1

# Direct / transfer admissions (not through ED)
n_direct = int(len(ed_admitted) * 0.6)
for _ in range(n_direct):
    d = random.randint(0, N_DAYS-1)
    admit_date = START_DATE + timedelta(days=d)
    hid = random.choice(list(hospital_ed_base.keys()))
    dept = random.choice(inpatient_dept_ids)
    los_base = {2:4.5, 3:3.8, 4:6.5, 5:4.2, 6:3.0, 7:4.8}[dept]
    los = max(1, np.random.gamma(shape=2.2, scale=los_base/2.2))
    discharge_date = admit_date + timedelta(days=round(los))
    readmit_risk = 0.07 + (0.04 if dept in (4,7) else 0)
    adm_rows.append({
        "admission_id": adm_id, "hospital_id": hid, "department_id": dept,
        "admission_date": admit_date.date().isoformat(), "discharge_date": discharge_date.date().isoformat(),
        "length_of_stay_days": round(los,1), "source": random.choice(["Direct Admission","Transfer"]),
        "readmitted_30d": int(np.random.random() < readmit_risk),
        "discharge_disposition": np.random.choice(["Home","Skilled Nursing Facility","Rehab","Home Health"], p=[0.65,0.14,0.11,0.10]),
        "patient_satisfaction_score": int(np.clip(np.random.normal(4.0 - (0.4 if los>7 else 0), 0.8), 1, 5)),
    })
    adm_id += 1

admissions = pd.DataFrame(adm_rows)
print(f"  Admissions: {len(admissions):,} rows")

# ---------------------------------------------------------------------------
# FACT: APPOINTMENTS (outpatient)
# ---------------------------------------------------------------------------
print("Generating appointments...")
appt_rows = []
appt_id = 1
hospital_appt_base = {1: 38, 2: 16, 3: 24, 4: 11}

for d in range(N_DAYS):
    date = START_DATE + timedelta(days=d)
    if date.weekday() >= 5:  # clinics mostly closed weekends
        continue
    for hid, base in hospital_appt_base.items():
        for dept in outpatient_dept_ids:
            lam = (base/2) * YEAR_GROWTH[date.year]
            n_appts = np.random.poisson(lam)
            for _ in range(n_appts):
                appt_type = np.random.choice(["New Patient","Follow-up","Annual Physical","Procedure"], p=[0.18,0.48,0.20,0.14])
                lead_time = max(0, int(np.random.gamma(shape=2, scale=6)))
                # No-show risk rises with lead time and is higher for new patients / procedures
                no_show_base = 0.09 + (0.05 if appt_type=="New Patient" else 0) + min(lead_time/100, 0.12)
                status = np.random.choice(
                    ["Completed","No-Show","Cancelled","Rescheduled"],
                    p=[max(0.55,1-no_show_base-0.1-0.08), min(no_show_base,0.35), 0.10, 0.08]
                )
                appt_rows.append({
                    "appointment_id": appt_id, "hospital_id": hid, "department_id": dept,
                    "scheduled_date": date.date().isoformat(), "appointment_type": appt_type,
                    "lead_time_days": lead_time, "status": status,
                })
                appt_id += 1

appointments = pd.DataFrame(appt_rows)
print(f"  Appointments: {len(appointments):,} rows")

# ---------------------------------------------------------------------------
# FACT: STAFFING (shift-level)
# ---------------------------------------------------------------------------
print("Generating staffing shifts...")
staff_rows = []
staff_id = 1
shifts = ["Day", "Evening", "Night"]
base_staff_need = {1:14,2:5,3:5,4:5,5:6,6:4,7:6,8:6}  # per-department baseline staffing need

for d in range(N_DAYS):
    date = START_DATE + timedelta(days=d)
    for hid in hospital_ed_base.keys():
        hosp_size_factor = {1:1.6, 2:0.7, 3:1.0, 4:0.55}[hid]
        for dept in all_dept_ids:
            for shift in shifts:
                shift_factor = {"Day":1.15, "Evening":1.0, "Night":0.65}[shift]
                needed = max(1, round(base_staff_need[dept] * hosp_size_factor * shift_factor * seasonal_factor(date)))
                # Night shifts and weekends are chronically understaffed relative to need (a real, common pattern)
                staffing_ratio = np.random.normal(0.94 if shift!="Night" else 0.82, 0.08)
                if date.weekday() >= 5:
                    staffing_ratio -= 0.05
                actual = max(0, round(needed * staffing_ratio))
                overtime = max(0, round(np.random.normal(2.0 if staffing_ratio<0.85 else 0.5, 1.5)))
                staff_rows.append({
                    "staffing_id": staff_id, "hospital_id": hid, "department_id": dept,
                    "shift_date": date.date().isoformat(), "shift": shift,
                    "scheduled_staff": needed, "actual_staff": actual, "overtime_hours": overtime,
                })
                staff_id += 1

staffing = pd.DataFrame(staff_rows)
print(f"  Staffing shifts: {len(staffing):,} rows")

# ---------------------------------------------------------------------------
# SAVE
# ---------------------------------------------------------------------------
hospitals.to_csv(f"{OUT_DIR}/dim_hospitals.csv", index=False)
departments.to_csv(f"{OUT_DIR}/dim_departments.csv", index=False)
ed_visits.to_csv(f"{OUT_DIR}/fact_ed_visits.csv", index=False)
admissions.to_csv(f"{OUT_DIR}/fact_admissions.csv", index=False)
appointments.to_csv(f"{OUT_DIR}/fact_appointments.csv", index=False)
staffing.to_csv(f"{OUT_DIR}/fact_staffing.csv", index=False)

total = len(hospitals)+len(departments)+len(ed_visits)+len(admissions)+len(appointments)+len(staffing)
print(f"\nTOTAL ROWS ACROSS ALL TABLES: {total:,}")
