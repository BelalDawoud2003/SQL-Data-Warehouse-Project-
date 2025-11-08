use healthcare_dwh;
-- DIM DATE
INSERT INTO healthcare_dwh.dim_date (
    date_key, full_date, day_of_week, day_of_month, day_of_year,
    week_of_year, month_num, month_name, quarter, year,
    is_weekend, is_holiday, fiscal_year, fiscal_quarter
)
SELECT
    UNIX_TIMESTAMP(d.dt) AS date_key, 
    d.dt,
    DAYNAME(d.dt),
    DAY(d.dt),
    DAYOFYEAR(d.dt),
    WEEKOFYEAR(d.dt),
    MONTH(d.dt),
    MONTHNAME(d.dt),
    QUARTER(d.dt),
    YEAR(d.dt),
    CASE WHEN DAYOFWEEK(d.dt) IN (1,7) THEN TRUE ELSE FALSE END,
    FALSE AS is_holiday,
    YEAR(d.dt) AS fiscal_year,
    QUARTER(d.dt) AS fiscal_quarter
FROM (
    SELECT DISTINCT dt
    FROM (
        SELECT appt_date AS dt FROM cleaned_hosp.cl_appointments
        UNION
        SELECT service_date FROM cleaned_hosp.cl_billing_transactions
        UNION
        SELECT billing_date FROM cleaned_hosp.cl_billing_transactions
        UNION
        SELECT claim_submitted_date FROM cleaned_hosp.cl_billing_transactions
        UNION
        SELECT hire_date FROM cleaned_hosp.cl_doctors
        UNION
        SELECT service_date FROM cleaned_hosp.cl_patient_surveys
        UNION
        SELECT survey_date FROM cleaned_hosp.cl_patient_surveys
        UNION
        SELECT diagnosis_date FROM cleaned_hosp.cl_medical_history
        UNION
        SELECT payment_date FROM cleaned_hosp.cl_billing_transactions
        UNION
        SELECT date_of_birth FROM cleaned_hosp.cl_patients
        UNION
        SELECT registration_date FROM cleaned_hosp.cl_patients
    ) AS all_dates
) AS d
WHERE d.dt >= '1970-01-01'
  AND NOT EXISTS (
      SELECT 1 FROM healthcare_dwh.dim_date dd
      WHERE dd.full_date = d.dt
  );





select * from healthcare_dwh.dim_date;

-- DIM TIME
INSERT INTO healthcare_dwh.dim_time (
    time_key, time_24hr, hour, minute, time_period, business_hours_flag
)
SELECT DISTINCT
    (HOUR(t.t)*100 + MINUTE(t.t)), 
    t.t,
    HOUR(t.t),
    MINUTE(t.t),
    CASE
        WHEN HOUR(t.t) BETWEEN 6 AND 11 THEN 'MORNING'
        WHEN HOUR(t.t) BETWEEN 12 AND 16 THEN 'AFTERNOON'
        WHEN HOUR(t.t) BETWEEN 17 AND 20 THEN 'EVENING'
        ELSE 'NIGHT'
    END,
    CASE WHEN HOUR(t.t) BETWEEN 9 AND 17 THEN TRUE ELSE FALSE END
FROM (
    SELECT scheduled_start AS t FROM cleaned_hosp.cl_appointments
    UNION
    SELECT scheduled_end FROM cleaned_hosp.cl_appointments
    UNION
    SELECT actual_start FROM cleaned_hosp.cl_appointments
    UNION
    SELECT actual_end FROM cleaned_hosp.cl_appointments
) t
WHERE t.t IS NOT NULL;

select * from healthcare_dwh.dim_time;

-- DIM PATIENT
INSERT INTO healthcare_dwh.dim_patient (
    patient_id, first_name, last_name, full_name,
    date_of_birth, age, age_group, gender, city, zip_code,
    registration_date, primary_insurance, secondary_insurance, patient_status,
    effective_date, expiration_date, current_flag
)
SELECT DISTINCT
    p.patient_id,
    p.first_name,
    p.last_name,
    CONCAT(p.first_name, ' ', p.last_name),
    p.date_of_birth,
    TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()),
    CASE
        WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 18 THEN 'CHILD'
        WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) BETWEEN 18 AND 64 THEN 'ADULT'
        ELSE 'SENIOR'
    END,
    p.gender,
    p.city,
    p.zip_code,
    p.registration_date,
    p.primary_insurance,
    p.secondary_insurance,
    p.patient_status,
    CURDATE(),
    NULL,
    TRUE
FROM cleaned_hosp.cl_patients p;
select * from healthcare_dwh.dim_patient;

INSERT INTO healthcare_dwh.dim_doctor (
    doctor_id, doctor_name, specialization, department,
    hire_date, experience_years, employment_status, primary_clinic,
    effective_date, expiration_date, current_flag
)
SELECT DISTINCT
    d.doctor_code,
    d.doctor_name,
    d.specialization,
    d.department,
    d.hire_date,
    TIMESTAMPDIFF(YEAR, d.hire_date, CURDATE()),
    d.status,
    d.primary_clinic,
    CURDATE(),
    NULL,
    TRUE
FROM cleaned_hosp.cl_doctors d;
select * from healthcare_dwh.dim_doctor;

INSERT INTO healthcare_dwh.dim_clinic (
    clinic_id, clinic_name, address, city,
    manager_name, capacity_rooms, operating_hours, clinic_type,
    effective_date, expiration_date, current_flag
)
SELECT DISTINCT
    c.clinic_code,
    c.clinic_name,
    c.address,
    c.city,
    c.manager_name,
    c.capacity_rooms,
    c.operating_hours,
    c.clinic_type,
    CURDATE(),
    NULL,
    TRUE
FROM cleaned_hosp.cl_clinics c;
select * from healthcare_dwh.dim_clinic;

INSERT INTO healthcare_dwh.dim_treatment (
    treatment_id, treatment_name, treatment_category,
    department, base_cost, typical_duration_minutes, complexity_level
)
SELECT DISTINCT
    s.service_code,
    s.service_description,
    s.service_category,
    s.department,
    s.base_cost,
    s.duration_minutes,
    CASE
        WHEN s.duration_minutes <= 15 THEN 'LOW'
        WHEN s.duration_minutes <= 45 THEN 'MEDIUM'
        ELSE 'HIGH'
    END
FROM cleaned_hosp.cl_service_codes s;
select* from healthcare_dwh.dim_treatment;

INSERT INTO healthcare_dwh.dim_insurance (
    insurance_company, company_type, plan_type,
    coverage_percentage, payment_terms_days
)
SELECT DISTINCT
    i.company_name,
    i.company_type,
    b.insurance_plan,
    80.00, -- default coverage, adjust if needed
    i.payment_terms_days
FROM cleaned_hosp.cl_insurance_companies i
LEFT JOIN cleaned_hosp.cl_billing_transactions b
    ON i.company_name = b.insurance_company;
select * from healthcare_dwh.dim_insurance;

INSERT INTO healthcare_dwh.dim_appointment_type (
    appointment_type, typical_duration, priority_level, requires_preparation
)
SELECT DISTINCT
    a.appt_type,
    TIMESTAMPDIFF(MINUTE, a.scheduled_start, a.scheduled_end),
    'NORMAL',
    FALSE
FROM cleaned_hosp.cl_appointments a
WHERE a.appt_type IS NOT NULL;

select * from healthcare_dwh.dim_appointment_type;

INSERT INTO healthcare_dwh.dim_diagnosis (
    diagnosis_code, diagnosis_name, severity_level, chronic_flag
)
SELECT DISTINCT
    m.condition_code,
    m.condition_name,
    m.severity,
    CASE WHEN m.chronic_flag = 'Y' THEN TRUE ELSE FALSE END
FROM cleaned_hosp.cl_medical_history m;

select * from healthcare_dwh.dim_diagnosis;

-- ==========================================
-- FACT TABLES
-- ==========================================
INSERT INTO healthcare_dwh.fact_appointments (
    date_key,
    time_key,
    patient_key,
    doctor_key,
    clinic_key,
    appointment_type_key,
    appointment_id,
    scheduled_duration_minutes,
    actual_duration_minutes,
    wait_time_minutes,
    no_show_flag,
    cancelled_flag,
    completed_flag,
    late_arrival_minutes
)
SELECT
    d.date_key,
    t.time_key,
    p.patient_key,
    doc.doctor_key,
    c.clinic_key,
    atype.appointment_type_key,
    a.appt_id,
    TIMESTAMPDIFF(MINUTE, a.scheduled_start, a.scheduled_end) AS scheduled_duration_minutes,
    TIMESTAMPDIFF(MINUTE, a.actual_start, a.actual_end) AS actual_duration_minutes,
    a.wait_time_mins,
    (a.appt_status = 'NO_SHOW')     AS no_show_flag,
    (a.appt_status = 'CANCELLED')   AS cancelled_flag,
    (a.appt_status = 'COMPLETED')   AS completed_flag,
    CASE
        WHEN a.actual_start > a.scheduled_start
        THEN TIMESTAMPDIFF(MINUTE, a.scheduled_start, a.actual_start)
        ELSE 0
    END AS late_arrival_minutes
FROM cleaned_hosp.cl_appointments a
JOIN healthcare_dwh.dim_date d
  ON d.full_date = DATE(a.appt_date)
JOIN healthcare_dwh.dim_time t
  ON t.time_24hr = TIME(a.scheduled_start)
JOIN healthcare_dwh.dim_patient p
  ON p.patient_id = a.patient_ref
  AND p.current_flag = TRUE
JOIN healthcare_dwh.dim_doctor doc
  ON doc.doctor_id = a.doctor_code
  AND doc.current_flag = TRUE
JOIN healthcare_dwh.dim_clinic c
  ON c.clinic_id = a.clinic_code
  AND c.current_flag = TRUE
JOIN healthcare_dwh.dim_appointment_type atype
  ON TRIM(LOWER(atype.appointment_type)) = TRIM(LOWER(a.appt_type));

select * from healthcare_dwh.fact_appointments;


INSERT INTO healthcare_dwh.fact_treatments (
    date_key, patient_key, doctor_key, clinic_key, treatment_key_dim,
    diagnosis_key, appointment_key, transaction_id,
    treatment_duration_minutes, base_treatment_cost, actual_treatment_cost,
    success_flag, complication_flag
)
SELECT
    d.date_key,
    p.patient_key,
    doc.doctor_key,
    c.clinic_key,                      
    tdim.treatment_key,
    diag.diagnosis_key,
    fa.appointment_key,
    b.transaction_id,
    tdim.typical_duration_minutes,
    tdim.base_cost,
    b.charged_amount,
    TRUE  AS success_flag,             
    FALSE AS complication_flag
FROM cleaned_hosp.cl_billing_transactions b
JOIN healthcare_dwh.dim_date d
    ON d.full_date = b.service_date
JOIN healthcare_dwh.dim_patient p
    ON p.patient_id = b.patient_number
   AND p.current_flag = TRUE
JOIN healthcare_dwh.dim_doctor doc
    ON doc.doctor_id = b.doctor_ref
   AND doc.current_flag = TRUE
JOIN healthcare_dwh.dim_treatment tdim
    ON tdim.treatment_id = b.service_code
LEFT JOIN healthcare_pms.medical_history mh
    ON mh.patient_id = b.patient_number
LEFT JOIN healthcare_dwh.dim_diagnosis diag
    ON diag.diagnosis_code = mh.condition_code
LEFT JOIN healthcare_dwh.fact_appointments fa
    ON fa.appointment_id = b.appointment_ref
JOIN healthcare_dwh.dim_clinic c
    ON c.clinic_id = doc.primary_clinic  
   AND c.current_flag = TRUE;
   
select * from healthcare_dwh.fact_treatments;

INSERT INTO healthcare_dwh.fact_billing (
    service_date_key, billing_date_key, payment_date_key,
    patient_key, doctor_key, clinic_key, treatment_key, insurance_key,
    appointment_key, transaction_id, claim_number,
    charged_amount, insurance_paid_amount, patient_paid_amount,
    adjustment_amount, outstanding_amount, claim_processing_days,
    claim_approved_flag, payment_complete_flag
)
SELECT
    sd.date_key,
    bd.date_key,
    pd.date_key,
    p.patient_key,
    doc.doctor_key,
    c.clinic_key,  -- جاي من dim_clinic
    tdim.treatment_key,
    ins.insurance_key,
    fa.appointment_key,
    b.transaction_id,
    b.claim_number,
    b.charged_amount,
    b.insurance_paid,
    b.patient_paid,
    b.adjustment_amount,
    b.outstanding_balance,
    DATEDIFF(b.payment_date, b.claim_submitted_date),
    (b.claim_status = 'APPROVED') AS claim_approved_flag,
    (b.outstanding_balance = 0) AS payment_complete_flag
FROM cleaned_hosp.cl_billing_transactions b
JOIN healthcare_dwh.dim_date sd
    ON sd.full_date = b.service_date
JOIN healthcare_dwh.dim_date bd
    ON bd.full_date = DATE(b.billing_date)
LEFT JOIN healthcare_dwh.dim_date pd
    ON pd.full_date = b.payment_date
JOIN healthcare_dwh.dim_patient p
    ON p.patient_id = b.patient_number
   AND p.current_flag = TRUE
JOIN healthcare_dwh.dim_doctor doc
    ON doc.doctor_id = b.doctor_ref
   AND doc.current_flag = TRUE
JOIN healthcare_dwh.dim_clinic c
    ON c.clinic_id = doc.primary_clinic   -- الربط بين الدكتور والعيادة
   AND c.current_flag = TRUE
JOIN healthcare_dwh.dim_treatment tdim
    ON tdim.treatment_id = b.service_code
JOIN healthcare_dwh.dim_insurance ins
    ON ins.insurance_company = b.insurance_company
LEFT JOIN healthcare_dwh.fact_appointments fa
    ON fa.appointment_id = b.appointment_ref;

select * from healthcare_dwh.fact_billing;

INSERT INTO healthcare_dwh.fact_patient_satisfaction (
    survey_date_key, service_date_key, patient_key, doctor_key,
    clinic_key, appointment_key, survey_id, treatment_key,
    overall_satisfaction_score, doctor_rating, facility_rating,
    wait_time_rating, recommendation_likelihood
)
SELECT
    sd.date_key,
    servd.date_key,
    p.patient_key,
    doc.doctor_key,
    c.clinic_key,
    fa.appointment_key,
    s.survey_id,
    tdim.treatment_key,  -- use dim_treatment
    s.overall_satisfaction,
    s.doctor_rating,
    s.facility_rating,
    s.wait_time_rating,
    s.recommendation_likelihood
FROM cleaned_hosp.cl_patient_surveys s
JOIN healthcare_dwh.dim_date sd 
    ON sd.full_date = s.survey_date
JOIN healthcare_dwh.dim_date servd 
    ON servd.full_date = s.service_date
JOIN healthcare_dwh.dim_patient p 
    ON p.patient_id = s.patient_id AND p.current_flag = TRUE
JOIN healthcare_dwh.dim_doctor doc 
    ON doc.doctor_id = s.doctor_id AND doc.current_flag = TRUE
JOIN healthcare_dwh.dim_clinic c 
    ON c.clinic_id = s.clinic_id AND c.current_flag = TRUE
LEFT JOIN healthcare_dwh.fact_appointments fa 
    ON fa.appointment_id = s.appointment_id
LEFT JOIN healthcare_dwh.fact_treatments ft 
    ON ft.appointment_key = fa.appointment_key
LEFT JOIN healthcare_dwh.dim_treatment tdim
    ON tdim.treatment_key = ft.treatment_key_dim;


