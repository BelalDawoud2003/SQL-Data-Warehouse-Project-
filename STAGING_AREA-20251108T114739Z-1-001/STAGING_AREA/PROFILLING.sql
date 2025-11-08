-- ======================================================================
-- ======================================================================
-- profilling
-- ======================================================================
-- ======================================================================
-- ==============
-- patients table 
-- ==============
use hospital_staging;

select * from hospital_staging.patients;
DESC patients;

SELECT* FROM patients
WHERE patient_id IN (
    SELECT patient_id
    FROM (
        SELECT patient_id,
               ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY registration_date DESC) AS rn
        FROM patients
    ) t
    WHERE rn > 1
);


-- check for null or spaces 
-- first name 
SELECT *
FROM patients
WHERE first_name != TRIM(first_name) OR first_name= NULL OR first_name= '';

SELECT *
FROM patients
WHERE last_name != TRIM(last_name) OR last_name= NULL OR last_name= ''; 

SELECT *
FROM patients
WHERE phone_number != TRIM(phone_number) OR phone_number= NULL OR phone_number= ''; 

SELECT *
FROM patients
WHERE address_line1 != TRIM(address_line1) OR address_line1= NULL OR address_line1= ''; 

SELECT *
FROM patients
WHERE address_line2 != TRIM(address_line2) OR address_line2= NULL OR address_line2= ' '; 

SELECT *
FROM patients
WHERE zip_code != TRIM(zip_code) OR zip_code= NULL OR zip_code= ' '; 

SELECT *
FROM patients
WHERE emergency_contact != TRIM(emergency_contact) OR emergency_contact= NULL OR emergency_contact= ' '; 


-- check emails 
SELECT 
    patient_id,
    first_name,
    last_name,
    email
FROM patients
WHERE TRIM(LOWER(email)) NOT LIKE CONCAT(LOWER(TRIM(first_name)), '.', LOWER(TRIM(last_name)), '@gmail.com')
AND first_name != ''
AND last_name != '';


-- check gender
select distinct gender from patients;

-- check  primary_insurance
select distinct  primary_insurance from patients;

-- check secondary_insurance
select distinct secondary_insurance from patients;

-- CHECK patients_ states
select distinct patient_status from patients;




-- =====================
-- clinics 
-- =====================


use hospital_staging ;

select * from clinics;

-- check duplicates
select * from clinics
where clinic_code IN ( select clinic_code from 
				(select clinic_code , 
                row_number() over(partition by clinic_code order by clinic_code) AS rn 
                from clinics) t
            where rn > 1 );    


-- check nulls , spaces , blank

select * from clinics 
where clinic_name != Trim(clinic_name) or
		clinic_name = '' or
        clinic_name = null;
        
select * from clinics 
where address != Trim(address) or
		address  = '' or
        address  = null;
        
select * from clinics 
where city != Trim(city) or
		city = '' or
        city = null;
        
select * from clinics 
where phone != Trim(phone) or
		phone = '' or
        phone = null;
        
select * from clinics 
where manager_name != Trim(manager_name) or
		manager_name = '' or
        manager_name = null;
        
select * from clinics 
where capacity_rooms != Trim(capacity_rooms) or
		capacity_rooms = '' or
        capacity_rooms = null;
        
select * from clinics 
where clinic_type != Trim(clinic_type) or
		clinic_type = '' or
        clinic_type = null;

-- =================
-- service_codes
-- ==================
use hospital_staging;
select * from service_codes;

-- check duplicates
select * from service_codes
where service_code in ( select service_code from
					(select service_code , row_number() over(partition by service_code order by service_code) as rn
                    from hospital_staging.service_codes) t
                    where rn > 1 );

-- check nulls & spaces & blank

select * from service_codes
where service_description != trim(service_description) or
service_description = '' or
service_description = null;

select * from service_codes
where service_category != trim(service_category) or
service_category = '' or
service_category = null;

select * from service_codes
where base_cost != trim(base_cost) or
base_cost = '' or
base_cost = null;

select * from service_codes
where duration_minutes != trim(duration_minutes) or
duration_minutes = '' or
duration_minutes = null;

select * from service_codes
where department != trim(department) or
department = '' or
department = null;


-- ====================
-- patient surveys
-- ====================

use hospital_staging;

select * from patient_surveys;
desc patient_surveys;

-- check duplicates
select * from patient_surveys
where survey_id in ( select survey_id from
						(select survey_id, row_number() over(partition by survey_id order by survey_date) as rn
                        from patient_surveys 
                        ) t 
			where rn > 1);
            
-- check null & spaces & blank

select * from patient_surveys
where patient_id != Trim(patient_id) or 
patient_id = null or
patient_id = '';

select * from patient_surveys
where appointment_id != Trim(appointment_id) or 
appointment_id = null or
appointment_id = '';

select * from patient_surveys
where doctor_id != Trim(doctor_id) or 
doctor_id = null or
doctor_id = '';

select * from patient_surveys
where clinic_id != Trim(clinic_id) or 
clinic_id = null or
clinic_id = '';

select * from patient_surveys
where overall_satisfaction < 0 or overall_satisfaction  > 10;

select * from patient_surveys
where doctor_rating < 0 or doctor_rating  > 10;

select * from patient_surveys
where facility_rating < 0 or facility_rating  > 10;

select * from patient_surveys
where wait_time_rating < 0 or wait_time_rating > 10;

select * from patient_surveys
where recommendation_likelihood < 0 or recommendation_likelihood > 10;

select * from patient_surveys
where 
comments = null or
comments = '';

select * from patient_surveys
where survey_method != TRIM(survey_method) or
comments = null or
comments = '';



-- ===================
-- medical history
-- ===============
use hospital_staging;
select * from medical_history;

-- check duplicate
select * from medical_history
where history_id in( select history_id from(
								select history_id,
									row_number() over(partition by history_id order by diagnosis_date) as rn
                                    from medical_history) t
						where rn > 1);
                        
-- check nulls & spaces & blank
select * from medical_history
where patient_id != trim(patient_id) or
patient_id = '' or
patient_id = null;

select * from medical_history
where condition_code != trim(condition_code) or
condition_code = '' or
condition_code = null;

select * from medical_history
where condition_name != trim(condition_name) or
condition_name = '' or
condition_name = null;

select * from medical_history
where severity != trim(severity) or
severity = '' or
severity = null;

select distinct chronic_flag from medical_history;

select * from medical_history
where notes != trim(notes) or
notes = '' or
notes = null;

select * from medical_history
where doctor_id != trim(doctor_id) or
doctor_id = '' or
doctor_id = null;


-- ======================
-- insurance_companies
-- ======================
use hospital_staging;

select * from insurance_companies;

-- check duplicates 
 select * from insurance_companies
 where company_id in ( select company_id from (
						select company_id , row_number() over(partition by company_id order by company_id) as rn
                        from insurance_companies) t
				where rn > 1 );
                
-- check nulls , spaces , blank

select * from insurance_companies
where company_name != TRIM(company_name) or 
company_name = '' or 
company_name = null;

select * from insurance_companies
where company_type != TRIM(company_type) or 
company_name = '' or 
company_name = null;

select * from insurance_companies
where payment_terms_days != TRIM(payment_terms_days) or 
payment_terms_days = '' or 
payment_terms_days = null;



-- ==================
-- doctors
-- ====================
use hospital_staging;
select * from doctors;

-- check dup
select * from doctors
where doctor_code in ( select doctor_code from(
							select doctor_code , row_number() over(partition by doctor_code order by hire_date desc) as rn
                            from doctors ) t
					where rn > 1);
                    
                    
-- check if name( first last)
select * from doctors
where TRIM(doctor_name) not like '% %' or TRIM(doctor_name)= '' or TRIM(doctor_name)= null;
                    
-- check null & spaces & blank
select * from doctors
where specialization != TRIM(specialization)  or TRIM(specialization)= '' or TRIM(specialization)= null;

select * from doctors
where department != TRIM(department) or TRIM(department)= '' or TRIM(department)= null;

select * from doctors
where phone != TRIM(phone)  or TRIM(phone)= '' or TRIM(phone)= null;

select * from doctors
where email != TRIM(email)  or TRIM(email)= '' or TRIM(email)= null;

select * from doctors
where status != TRIM(status)  or TRIM(status)= '' or TRIM(status)= null;

select * from doctors
where primary_clinic != TRIM(primary_clinic) or TRIM(primary_clinic)= '' or TRIM(primary_clinic)= null;



-- =======================
-- appointement
-- =======================
use hospital_staging;
select * from appointments;
-- check dup
select * from appointments
where appt_id in ( select appt_id from(
							select appt_id , row_number() over(partition by appt_id order by appt_date desc) as rn
                            from appointments ) t
					where rn > 1);
                    
-- check null & spaces & blank
select * from appointments
where appt_type != TRIM(appt_type)  or 
TRIM(appt_type)= '' or 
TRIM(appt_type)= null;

select * from appointments
where appt_status != TRIM(appt_status)  or 
TRIM(appt_status)= '' or 
TRIM(appt_status)= null;

select * from appointments
where created_by != TRIM(created_by)  or 
TRIM(created_by)= '' or 
TRIM(created_by)= null;



-- ===========================
-- `billing_transactions`
-- ==========================
use hospital_staging;
select * from billing_transactions;

-- check dup
select * from billing_transactions
where transaction_id in ( select transaction_id from(
							select transaction_id , row_number() over(partition by transaction_id order by service_date desc) as rn
                            from billing_transactions) t
					where rn > 1);
                    
-- check for nulls & spaces & blank
select * from billing_transactions
where appointment_ref != TRIM(appointment_ref)  or 
TRIM(appointment_ref)= '' or 
TRIM(appointment_ref)= null;

select * from billing_transactions
where service_code != TRIM(service_code)  or 
TRIM(service_code)= '' or 
TRIM(service_code)= null;

select * from billing_transactions
where service_description != TRIM(service_description)  or 
TRIM(service_description)= '' or 
TRIM(service_description)= null;

select * from billing_transactions
where charged_amount != TRIM(charged_amount)  or 
TRIM(charged_amount)= '' or 
TRIM(charged_amount)= null or
charged_amount < 0;

select * from billing_transactions
where insurance_company != TRIM(insurance_company)  or 
TRIM(insurance_company)= '' or 
TRIM(insurance_company)= null;

select * from billing_transactions
where insurance_plan != TRIM(insurance_plan)  or 
TRIM(insurance_plan)= '' or 
TRIM(insurance_plan)= null;

select * from billing_transactions
where claim_number != TRIM(claim_number)  or 
TRIM(claim_number)= '' or 
TRIM(claim_number)= null;

select * from billing_transactions
where claim_status != TRIM(claim_status)  or 
TRIM(claim_status)= '' or 
TRIM(claim_status)= null;

select * from billing_transactions
where insurance_paid != TRIM(insurance_paid)  or 
TRIM(insurance_paid)= '' or 
TRIM(insurance_paid)= null or
insurance_paid < 0;

select * from billing_transactions
where patient_paid != TRIM(patient_paid)  or 
TRIM(patient_paid)= '' or 
TRIM(patient_paid)= null or
patient_paid < 0;

select * from billing_transactions
where adjustment_amount != TRIM(adjustment_amount)  or 
TRIM(adjustment_amount)= '' or 
TRIM(adjustment_amount)= null or
adjustment_amount < 0;

select * from billing_transactions
where outstanding_balance != TRIM(outstanding_balance)  or 
TRIM(outstanding_balance)= '' or 
TRIM(outstanding_balance)= null or
outstanding_balance < 0;

