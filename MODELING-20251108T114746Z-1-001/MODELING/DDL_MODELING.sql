-- PART 3: DATA WAREHOUSE IMPLEMENTATION
-- ========================================

CREATE DATABASE healthcare_dwh;
USE healthcare_dwh;

-- ========================================
-- DIMENSION TABLES
-- ========================================

-- Date Dimension
CREATE TABLE dim_date (
date_key INT PRIMARY KEY,
full_date DATE NOT NULL, 
day_of_week VARCHAR(10),
day_of_month INT,
day_of_year INT,
week_of_year INT,
month_num INT,
month_name VARCHAR(10),
quarter INT,
year INT,
is_weekend BOOLEAN,
is_holiday BOOLEAN,
fiscal_year INT,
fiscal_quarter INT
);


-- Time Dimension
CREATE TABLE dim_time (
time_key INT PRIMARY KEY,
time_24hr TIME NOT NULL,
hour INT,
minute INT,
time_period VARCHAR(10), -- MORNING, AFTERNOON, EVENING, NIGHT
business_hours_flag BOOLEAN
);


-- Patient Dimension
CREATE TABLE dim_patient (
patient_key INT AUTO_INCREMENT PRIMARY KEY,
patient_id VARCHAR(10) NOT NULL,
first_name VARCHAR(50),
last_name VARCHAR(50),
full_name VARCHAR(100),
date_of_birth DATE,
age INT,
age_group VARCHAR(20),
gender VARCHAR(10),
city VARCHAR(50),
zip_code VARCHAR(10),
registration_date DATE,
primary_insurance VARCHAR(50),
secondary_insurance VARCHAR(50),
patient_status VARCHAR(10),
-- SCD Type 2 fields
effective_date DATE,
expiration_date DATE,
current_flag BOOLEAN DEFAULT TRUE,
UNIQUE KEY unique_patient_current (patient_id, current_flag)
);


-- Doctor Dimension
CREATE TABLE dim_doctor (
doctor_key INT AUTO_INCREMENT PRIMARY KEY,
doctor_id VARCHAR(10) NOT NULL,
doctor_name VARCHAR(100),
specialization VARCHAR(50),
department VARCHAR(50),
hire_date DATE,
experience_years INT,
employment_status VARCHAR(10),
primary_clinic VARCHAR(5),
-- SCD Type 2 fields
effective_date DATE,
expiration_date DATE,
current_flag BOOLEAN DEFAULT TRUE,
UNIQUE KEY unique_doctor_current (doctor_id, current_flag)
);


-- Clinic Dimension
CREATE TABLE dim_clinic (
clinic_key INT AUTO_INCREMENT PRIMARY KEY,
clinic_id VARCHAR(5) NOT NULL,
clinic_name VARCHAR(100),
address VARCHAR(200),
city VARCHAR(50),
manager_name VARCHAR(100),
capacity_rooms INT,
operating_hours VARCHAR(50),
clinic_type VARCHAR(30),
-- SCD Type 2 fields
effective_date DATE,
expiration_date DATE,
current_flag BOOLEAN DEFAULT TRUE,
UNIQUE KEY unique_clinic_current (clinic_id, current_flag)
);


-- Treatment Dimension
CREATE TABLE dim_treatment (
treatment_key INT AUTO_INCREMENT PRIMARY KEY,
treatment_id VARCHAR(20) NOT NULL,
treatment_name VARCHAR(200),
treatment_category VARCHAR(50),
department VARCHAR(50),
base_cost DECIMAL(10,2),
typical_duration_minutes INT,
complexity_level VARCHAR(20)
);


-- Diagnosis Dimension
CREATE TABLE dim_diagnosis (
diagnosis_key INT AUTO_INCREMENT PRIMARY KEY,
diagnosis_code VARCHAR(10) NOT NULL,
diagnosis_name VARCHAR(200),
severity_level VARCHAR(20),
chronic_flag BOOLEAN
);


-- Insurance Dimension
CREATE TABLE dim_insurance (
insurance_key INT AUTO_INCREMENT PRIMARY KEY,
insurance_company VARCHAR(100) NOT NULL,
company_type VARCHAR(30),
plan_type VARCHAR(50),
coverage_percentage DECIMAL(5,2),
payment_terms_days INT
);

-- ========================================
-- FACT TABLES
-- ========================================

-- Fact Appointments
CREATE TABLE fact_appointments (
appointment_key INT AUTO_INCREMENT PRIMARY KEY,
-- Dimension Keys
date_key BIGINT,
time_key INT,
patient_key INT,
doctor_key INT,
clinic_key INT,
appointment_type_key INT,
-- Natural Keys for reference
appointment_id INT,
-- Measures
scheduled_duration_minutes INT,
actual_duration_minutes INT,
wait_time_minutes INT,
no_show_flag BOOLEAN,
cancelled_flag BOOLEAN,
completed_flag BOOLEAN,
late_arrival_minutes INT,
appointment_count INT DEFAULT 1,
-- Timestamps
created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
-- Foreign Keys
FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
FOREIGN KEY (time_key) REFERENCES dim_time(time_key),
FOREIGN KEY (patient_key) REFERENCES dim_patient(patient_key),
FOREIGN KEY (doctor_key) REFERENCES dim_doctor(doctor_key),
FOREIGN KEY (clinic_key) REFERENCES dim_clinic(clinic_key),
FOREIGN KEY (appointment_type_key) REFERENCES dim_appointment_type(appointment_type_key)
);



-- Fact Treatments (derived from billing transactions)
CREATE TABLE fact_treatments (
treatment_key INT AUTO_INCREMENT PRIMARY KEY,
-- Dimension Keys
date_key BIGINT,
patient_key INT,
doctor_key INT,
clinic_key INT,
treatment_key_dim INT,
diagnosis_key INT,
appointment_key INT, -- Reference to fact_appointments
-- Natural Keys
transaction_id INT,
-- Measures
treatment_duration_minutes INT,
base_treatment_cost DECIMAL(10,2),
actual_treatment_cost DECIMAL(10,2),
treatment_count INT DEFAULT 1,
success_flag BOOLEAN,
complication_flag BOOLEAN DEFAULT FALSE,
-- Timestamps
created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
-- Foreign Keys
FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
FOREIGN KEY (patient_key) REFERENCES dim_patient(patient_key),
FOREIGN KEY (doctor_key) REFERENCES dim_doctor(doctor_key),
FOREIGN KEY (clinic_key) REFERENCES dim_clinic(clinic_key),
FOREIGN KEY (treatment_key_dim) REFERENCES dim_treatment(treatment_key),
FOREIGN KEY (diagnosis_key) REFERENCES dim_diagnosis(diagnosis_key)
);




-- Fact Billing
CREATE TABLE fact_billing (
billing_key INT AUTO_INCREMENT PRIMARY KEY,
-- Dimension Keys
service_date_key BIGINT,
billing_date_key BIGINT,
payment_date_key BIGINT,
patient_key INT,
doctor_key INT,
clinic_key INT,
treatment_key INT,
insurance_key INT,
appointment_key INT, -- Reference to fact_appointments
-- Natural Keys
transaction_id INT,
claim_number VARCHAR(30),
-- Measures
charged_amount DECIMAL(10,2),
insurance_paid_amount DECIMAL(10,2),
patient_paid_amount DECIMAL(10,2),
adjustment_amount DECIMAL(10,2),
outstanding_amount DECIMAL(10,2),
claim_processing_days INT,
billing_count INT DEFAULT 1,
claim_approved_flag BOOLEAN,
payment_complete_flag BOOLEAN,
-- Timestamps
created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
-- Foreign Keys
FOREIGN KEY (service_date_key) REFERENCES dim_date(date_key),
FOREIGN KEY (billing_date_key) REFERENCES dim_date(date_key),
FOREIGN KEY (patient_key) REFERENCES dim_patient(patient_key),
FOREIGN KEY (doctor_key) REFERENCES dim_doctor(doctor_key),
FOREIGN KEY (clinic_key) REFERENCES dim_clinic(clinic_key),
FOREIGN KEY (treatment_key) REFERENCES dim_treatment(treatment_key),
FOREIGN KEY (insurance_key) REFERENCES dim_insurance(insurance_key)
);



-- Fact Patient Satisfaction
CREATE TABLE fact_patient_satisfaction (
    satisfaction_key INT AUTO_INCREMENT PRIMARY KEY,
    -- Dimension Keys
    survey_date_key BIGINT,
    service_date_key BIGINT,
    patient_key INT,
    doctor_key INT,
    clinic_key INT,
    treatment_key INT,
    appointment_key INT, -- Reference to fact_appointments
    -- Natural Keys
    survey_id INT,
    -- Measures
    overall_satisfaction_score TINYINT,
    doctor_rating TINYINT,
    facility_rating TINYINT,
    wait_time_rating TINYINT,
    recommendation_likelihood TINYINT,
    survey_count INT DEFAULT 1,
    -- Timestamps
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Foreign Keys
    FOREIGN KEY (survey_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (service_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (patient_key) REFERENCES dim_patient(patient_key),
    FOREIGN KEY (doctor_key) REFERENCES dim_doctor(doctor_key),
    FOREIGN KEY (clinic_key) REFERENCES dim_clinic(clinic_key),
    FOREIGN KEY (treatment_key) REFERENCES dim_treatment(treatment_key)
);


