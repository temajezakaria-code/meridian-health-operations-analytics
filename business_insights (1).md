# Meridian Health Network — Executive Insights & Recommendations

All figures below are pulled directly from the SQL analysis and Python notebooks in
this repository (183,215 ED visits, 50,313 admissions, 75,531 appointments, 105,216
staffing records, 2023-2025). Where an estimate is scenario-based rather than a direct
data measurement, that is stated explicitly — this project uses fictional data, and
overstating precision would undercut its credibility, not add to it.

---

## 15 Executive Insights

1. **ED wait times have climbed structurally, not randomly**: 46.6 → 54.5 → 64.0
   minutes average (2023 → 2025), confirmed via 3-month rolling average, not a single
   bad quarter.
2. **Triage severity explains the majority of wait-time variation**: triage 5 (least
   urgent) patients wait ~96 minutes on average vs. ~11 minutes for triage 1 (most
   critical) — statistically confirmed (ANOVA F=69,141, p<0.001).
3. **Night shift is understaffed across every single department**, network-wide —
   80-85% of needed staffing vs. 92-93% on Day/Evening shifts. This is not isolated to
   one department or hospital.
4. **The staffing-to-wait-time link is not statistically confirmed at the data
   granularity available** (daily-level correlation p=0.38). Both trends worsen over
   the same 3 years, but the current data cannot prove same-day causation — see
   Critical Assessment.
5. **Readmissions are concentrated in 2 of 6 inpatient departments**: Internal
   Medicine (14.2%) and Oncology (13.9%) run 60-75% higher readmission rates than
   Cardiology, Orthopedics, General Surgery, and Pediatrics (8.1-8.7%).
6. **Oncology has a dramatically elevated extended-stay rate**: 36.3% of Oncology
   admissions exceed 7 days, more than double Internal Medicine's 20.5% and far above
   the 9.8-17.8% range seen elsewhere.
7. **No-show risk rises sharply with scheduling lead time**: New Patient appointments
   booked 15+ days out show a meaningfully higher no-show rate than those booked
   within 3 days, across every appointment type tested.
8. **New Patient appointments no-show at the highest rate of any appointment type**
   (22.2% overall), ahead of Follow-up, Annual Physical, and Procedure visits
   (17.2-17.5%).
9. **LWBS (Left Without Being Seen) rates are consistent across all 4 hospitals**
   (6.9-7.1%) — this is a network-wide systemic issue, not a single-site problem.
10. **Weekend ED volume runs meaningfully higher than mid-week** (Friday-Sunday above
    the weekly average), a demand pattern that staffing schedules should be built
    around explicitly.
11. **Overtime hours are remarkably consistent across all 4 hospitals** (1.29-1.31
    hours per shift record) — suggesting the understaffing problem is systemic to the
    network's scheduling model, not one hospital's local management issue.
12. **63% of admitted patients discharge home**, with the remaining 37% split across
    Skilled Nursing Facilities (15%), Rehab (12%), and Home Health (10%) — a
    meaningful share of post-acute care coordination volume.
13. **The 6-month forecast projects wait times remaining elevated** (65-82 minutes)
    if current conditions continue unaddressed — a concrete, quantified cost of
    inaction rather than a vague warning.
14. **Relative capacity utilization varies meaningfully by hospital**: Meridian East
    County shows the highest admission-volume-to-bed-capacity ratio among the 4
    hospitals, while Downtown Medical Center shows the lowest — a relative signal
    only (see Critical Assessment for why absolute occupancy figures are not
    reported).
15. **No single hospital is an outlier across every metric** — different hospitals
    lead in different problem areas (East County in relative capacity pressure,
    Downtown in absolute ED volume), meaning a one-size-fits-all network-wide fix
    would likely misallocate resources relative to a hospital-specific approach.

---

## 10 Operational Risks

1. **Rising ED wait times are a patient-safety and reputational risk** — if the
   3-year upward trend continues per the forecast, patient satisfaction and potential
   regulatory attention will likely follow.
2. **Night-shift understaffing, if left unaddressed, risks clinical staff burnout and
   turnover** — chronic short-staffing is a well-documented driver of healthcare
   worker attrition.
3. **Oncology's extended-stay rate concentrates bed-capacity risk in one department**
   — a surge in Oncology demand could cascade into network-wide capacity strain faster
   than leadership might expect.
4. **The unconfirmed staffing/wait-time causal link is itself a risk** — if leadership
   acts on an assumed causal relationship that a rigorous test didn't confirm, a
   staffing investment might not deliver the expected wait-time improvement.
5. **High-lead-time New Patient no-shows represent lost access capacity** — every
   no-show is a slot that could have gone to another patient, compounding access
   problems in already-strained specialties.
6. **LWBS patients represent an unquantified clinical risk** — patients who leave
   without treatment may return in worse condition, potentially to the same or a
   different network hospital, with no current process to track this.
7. **Consistent overtime hours across all hospitals suggest a structural scheduling
   gap**, not isolated bad luck — if unaddressed, overtime costs will persist
   indefinitely rather than resolve on their own.
8. **Readmission concentration in Internal Medicine and Oncology could trigger payer
   penalties** if these departments' rates are visible to payers tracking excess
   readmissions.
9. **Weekend ED demand exceeding weekday staffing patterns risks a compounding
   effect** — if weekend wait times run structurally worse, patient perception of
   overall ED quality may anchor on the worst experience, not the average.
10. **Relying on hospital-specific point solutions without addressing the shared
    Night-shift and no-show patterns risks solving symptoms at one site while the
    same root cause persists everywhere else.**

---

## 15 Strategic Recommendations

1. **Launch a fast-track/urgent-care diversion pathway for triage 4-5 patients** —
   the single largest, most statistically clear wait-time lever identified.
2. **Redesign Night-shift scheduling incentives** (differential pay, voluntary
   premium shifts) to close the 80-85% vs. 93% staffing gap, starting with Emergency
   and Outpatient Clinic (the two lowest-staffed departments).
3. **Build a targeted discharge-planning review for Internal Medicine and Oncology**,
   the two departments driving the majority of excess readmissions.
4. **Add a step-down/transitional care unit option for Oncology**, directly targeting
   its 36.3% extended-stay rate.
5. **Implement a lead-time-triggered reminder program for New Patient appointments**
   booked 8+ days out — the exact segment showing the highest no-show risk.
6. **Instrument ED visits with hour-of-day/shift-level timestamps** before further
   staffing investment decisions — this closes the exact data gap that prevented
   confirming the staffing/wait-time causal link.
7. **Create a standardized LWBS follow-up protocol** — a courtesy callback or triage
   nurse check-in for patients who leave without being seen, given the consistent 7%
   rate network-wide.
8. **Pilot weekend-specific ED staffing templates** rather than applying a flat
   weekly schedule, matching the confirmed Friday-Sunday volume bump.
9. **Share the overtime-hours pattern with network HR/Finance leadership as a single
   systemic issue**, not four separate hospital-level line items, since the
   consistency across sites suggests one shared root cause.
10. **Benchmark Meridian East County's relative capacity pressure against its staffing
    and referral patterns** specifically, since it shows the highest utilization index
    of the 4 hospitals.
11. **Stand up a cross-hospital "Night Shift Task Force"** since the understaffing
    pattern is genuinely network-wide, not a single-site fix.
12. **Track a rolling 3-month wait-time average on the executive dashboard**, not just
    the monthly figure, to avoid over-reacting to single-month noise (the same
    smoothing technique used in this analysis).
13. **Formalize a post-acute care coordination review** given that 37% of discharges
    go to SNF, Rehab, or Home Health — a substantial, currently under-examined
    handoff volume.
14. **Re-run the wait-time forecast quarterly** as new data arrives, rather than
    treating the current 6-month projection as fixed.
15. **Prioritize the fast-track pathway (Recommendation 1) and Night-shift scheduling
    (Recommendation 2) as the two highest-confidence, highest-leverage initiatives**
    — both are backed by the strongest statistical evidence in this analysis.

---

## 10 Quick Wins (Low Cost / Fast to Implement)

1. Launch the lead-time-triggered appointment reminder program (Recommendation 5) —
   no new staff or capital required, just a scheduling-system trigger rule.
2. Add the rolling 3-month wait-time metric to the existing executive dashboard —
   a reporting change, not an operational one.
3. Start the LWBS courtesy callback pilot at the single highest-LWBS-rate hospital
   before scaling network-wide.
4. Share the overtime-hours consistency finding directly with HR/Finance as a
   discussion item for the next leadership meeting.
5. Flag the Oncology extended-stay rate to the department's own leadership for a
   focused, internal case review before committing capital to a step-down unit.
6. Add hour-of-day timestamp capture to the ED intake system's next minor release —
   a data-collection fix, not a process overhaul.
7. Publish the triage-level wait-time gap internally as a simple 1-page visual — the
   fast-track case essentially makes itself once shown clearly.
8. Pilot a single weekend-specific staffing template at one hospital before a
   network-wide rollout.
9. Add a "New Patient, booked 8+ days out" flag to the existing appointment system
   as a manual outreach worklist while the automated reminder program is built.
10. Present the "no single hospital is an outlier across every metric" finding to
    leadership explicitly, to head off a one-size-fits-all policy response before it's
    proposed.

---

## 10 Long-Term Improvement Opportunities

1. Build a true survival/time-to-readmission model once longitudinal (not
   snapshot) data is available, enabling proactive rather than retrospective
   readmission risk flagging.
2. Develop hospital-specific staffing models instead of one network-wide template,
   given that different hospitals show different relative pressures.
3. Integrate real-time bed-management data to replace the current relative
   utilization index with an actual, benchmarkable occupancy metric.
4. Build a network-wide capacity-sharing protocol (e.g., patient transfer triggers)
   informed by which hospital is under the most relative pressure at a given time.
5. Invest in predictive no-show modeling (beyond lead-time alone) incorporating
   appointment history, distance from clinic, and prior cancellation patterns.
6. Establish a formal quarterly "operational KPI review" cadence tying this
   dashboard's metrics directly to departmental performance reviews.
7. Explore a dedicated Oncology transitional care partnership (external step-down
   facility) as a long-term capacity release valve.
8. Build a compensation/scheduling redesign specifically for Night-shift coverage,
   informed by what similar health systems have used successfully.
9. Develop a patient-reported LWBS follow-up survey to understand *why* patients
   leave, not just how often, informing a more targeted fix than volume statistics
   alone can support.
10. Revisit this entire analysis annually as new data accumulates, tracking whether
    the interventions above actually moved the metrics — turning this one-time
    analysis into an ongoing measurement program.

---

## Critical Assessment & Next Steps

A hospital operations analysis that stops at "here are the dashboards" isn't
finished — here's what I'd flag before any of this reaches a board presentation,
and what I'd do differently with more time or access.

**Limitations of this analysis:**
- **This dataset is entirely synthetic.** Real multi-hospital operational data at
  this granularity is protected health information (HIPAA) and isn't available as a
  combined public dataset. The synthetic generator was built with deliberate,
  documented realistic patterns (seasonal surges, Night-shift gaps, triage-based wait
  time structure) so the analysis has genuine signal to find — but every number here
  is illustrative, not a real hospital network's actual performance.
- **The staffing-to-wait-time causal link is not confirmed** — I tested it directly
  rather than assuming it, and the daily-level correlation came back non-significant
  (p=0.38). Rather than force the expected result, this is reported honestly, along
  with the specific data gap (no hour/shift-level ED timestamps) that limits how
  precisely this hypothesis can currently be tested.
- **The bed occupancy figures are a relative index, not an absolute benchmark.** The
  synthetic bed-capacity numbers weren't calibrated to produce realistic 80-90%
  occupancy rates seen in real hospitals — rather than present a misleadingly low
  absolute figure, this is reported as a relative cross-hospital comparison only.
- **The financial/cost impact of these recommendations is not quantified in dollar
  terms** in this version — unlike the retail and banking projects in this portfolio,
  translating operational metrics into a hospital's actual cost structure (staffing
  cost per hour, readmission penalty exposure, no-show revenue loss) would require
  real network financial data this project doesn't have access to.

**What I'd do with more time or access:**
- Add hour-of-day/shift-level ED visit timestamps — the single highest-value data
  addition, since it directly unlocks the staffing/wait-time causal test that
  currently can't be run precisely.
- Replace the relative capacity index with real bed-management system data once
  available, and validate the synthetic generator's assumptions against real
  published hospital capacity benchmarks.
- Build the readmission and no-show findings into a real predictive model (this
  project's SQL/Python analysis stops at descriptive and correlational analysis,
  deliberately, since a hospital operations project should demonstrate root-cause
  reasoning first — but a natural next step is a proper predictive model, similar to
  the churn model in this portfolio's PrimeBank project).
- Attach real (even if illustrative, clearly-labeled) cost assumptions to each
  recommendation, the way the PrimeBank project's business economics analysis did —
  this version prioritized operational clarity over a dollar figure that would have
  required fabricating hospital financial assumptions with no data to ground them.

I'd rather state these limitations plainly than let a polished dashboard imply more
certainty than a synthetic dataset can actually support.
