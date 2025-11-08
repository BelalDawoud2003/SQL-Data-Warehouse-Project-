
CREATE DATABASE healthcare_pms;
USE healthcare_pms;

-- Patients Master Table
CREATE TABLE patients (
patient_id VARCHAR(10),
first_name VARCHAR(50) ,
last_name VARCHAR(50) ,
date_of_birth VARCHAR(100) ,
gender VARCHAR(50),
phone_number VARCHAR(15),
email VARCHAR(100),
address_line1 VARCHAR(100),
address_line2 VARCHAR(100),
city VARCHAR(50),
zip_code VARCHAR(10),
registration_date VARCHAR(100),
primary_insurance VARCHAR(50),
secondary_insurance VARCHAR(50),
patient_status VARCHAR(10) ,
emergency_contact VARCHAR(100)
);


-- Medical History Table
CREATE TABLE medical_history (
history_id INT ,
patient_id VARCHAR(10),
condition_code VARCHAR(10),
condition_name VARCHAR(200),
diagnosis_date VARCHAR(100),
severity VARCHAR(20) ,
chronic_flag VARCHAR(20) ,
notes TEXT,
doctor_id VARCHAR(10)
);

-- SOURCE SYSTEM 2: Appointment Management System (AMS)
-- Database: healthcare_appointments
-- ========================================

CREATE DATABASE healthcare_appointments;
USE healthcare_appointments;

-- Clinics Master Table
CREATE TABLE clinics (
clinic_code VARCHAR(5) ,
clinic_name VARCHAR(100) ,
address VARCHAR(200),
city VARCHAR(50),
phone VARCHAR(15),
manager_name VARCHAR(100),
capacity_rooms INT,
operating_hours VARCHAR(50),
clinic_type VARCHAR(30)
);


-- Doctors Master Table
CREATE TABLE doctors (
doctor_code VARCHAR(10) ,
doctor_name VARCHAR(100) ,
specialization VARCHAR(50),
department VARCHAR(50),
hire_date varchar(50),
phone VARCHAR(15),
email VARCHAR(100),
status VARCHAR(10) DEFAULT 'ACTIVE',
primary_clinic VARCHAR(5)
);


-- Appointments Transactional Table
CREATE TABLE appointments (
appt_id INT ,
patient_ref VARCHAR(10) , 
doctor_code VARCHAR(10) ,
clinic_code VARCHAR(5) ,
appt_date varchar(50),
scheduled_start TIME ,
scheduled_end TIME ,
actual_start TIME,
actual_end TIME,
appt_type VARCHAR(20),
appt_status VARCHAR(15),
wait_time_mins INT,
created_by VARCHAR(50)
);

-- SOURCE SYSTEM 3: Billing System (BS)
-- Database: healthcare_billing
-- ========================================

CREATE DATABASE healthcare_billing;
USE healthcare_billing;

-- Insurance Companies Master
CREATE TABLE insurance_companies (
company_id INT ,
company_name VARCHAR(100) ,
company_type VARCHAR(30),
contact_info VARCHAR(200),
payment_terms_days INT
);

-- Treatment/Service Codes Master
CREATE TABLE service_codes (
service_code VARCHAR(20),
service_description VARCHAR(200),
service_category VARCHAR(50),
base_cost DECIMAL(10,2),
duration_minutes INT,
department VARCHAR(50)
);


-- Billing Transactions
CREATE TABLE billing_transactions (
transaction_id INT ,
patient_number VARCHAR(15) , -- Maps to PMS patient_id (inconsistent format!)
doctor_ref VARCHAR(15) , -- Maps to AMS doctor_code
appointment_ref INT, -- Maps to AMS appt_id
service_date VARCHAR(20),
service_code VARCHAR(20),
service_description VARCHAR(200),
charged_amount DECIMAL(10,2),
insurance_company VARCHAR(100), -- Company name, not ID!
insurance_plan VARCHAR(50),
claim_number VARCHAR(30),
claim_submitted_date VARCHAR(20),
claim_status VARCHAR(20),
insurance_paid DECIMAL(10,2),
patient_paid DECIMAL(10,2) ,
adjustment_amount DECIMAL(10,2) ,
outstanding_balance DECIMAL(10,2),
billing_date DATETIME DEFAULT CURRENT_TIMESTAMP,
payment_date VARCHAR(20)

);

-- SOURCE SYSTEM 4: Patient Satisfaction System
-- Database: healthcare_surveys
-- ========================================

CREATE DATABASE healthcare_surveys;
USE healthcare_surveys;

-- Patient Satisfaction Surveys
CREATE TABLE patient_surveys (
survey_id INT ,
patient_id VARCHAR(10), -- Maps to PMS patient_id
appointment_id INT, -- Maps to AMS appt_id
survey_date VARCHAR(20),
service_date VARCHAR(20),
doctor_id VARCHAR(10), -- Maps to AMS doctor_code
clinic_id VARCHAR(5), -- Maps to AMS clinic_code
overall_satisfaction TINYINT ,
doctor_rating TINYINT,
facility_rating TINYINT ,
wait_time_rating TINYINT ,
recommendation_likelihood TINYINT ,
comments TEXT,
survey_method VARCHAR(20) -- EMAIL, PHONE, SMS, IN_PERSON
);

