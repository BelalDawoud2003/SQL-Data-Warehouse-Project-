-- ======================================================================
-- ======================================================================
-- staging area
-- ======================================================================
-- ======================================================================

create database hospital_staging;

create table hospital_staging.patients like healthcare_pms.patients;
create table hospital_staging.medical_history like healthcare_pms.medical_history;
create table hospital_staging.patient_surveys like healthcare_surveys.patient_surveys;
create table hospital_staging.billing_transactions like healthcare_billing.billing_transactions;
create table hospital_staging.insurance_companies like healthcare_billing.insurance_companies;
create table hospital_staging.service_codes like healthcare_billing.service_codes;
create table hospital_staging.appointments like healthcare_appointments.appointments;
create table hospital_staging.clinics like healthcare_appointments.clinics;
create table hospital_staging.doctors like healthcare_appointments.doctors;

insert into hospital_staging.patients select * from healthcare_pms.patients;
insert into hospital_staging.medical_history select * from healthcare_pms.medical_history;
insert into hospital_staging.patient_surveys select * from healthcare_surveys.patient_surveys;
insert into hospital_staging.billing_transactions select * from healthcare_billing.billing_transactions;
insert into hospital_staging.insurance_companies select * from healthcare_billing.insurance_companies;
insert into hospital_staging.service_codes select * from healthcare_billing.service_codes;
insert into hospital_staging.appointments select * from healthcare_appointments.appointments;
insert into hospital_staging.clinics select * from healthcare_appointments.clinics;
insert into hospital_staging.doctors select * from healthcare_appointments.doctors;


select * from hospital_staging.patients;
select * from hospital_staging.medical_history;
 select * from  hospital_staging.patient_surveys;
select * from hospital_staging.billing_transactions;
select * from  hospital_staging.insurance_companies;
select * from  hospital_staging.service_codes;
select * from  hospital_staging.appointments;
select * from  hospital_staging.clinics;
select * from   hospital_staging.doctors;