-- =============================================
-- cleaning data
-- =============================================

-- ================
-- patient table
-- ================

create database cleaned_hosp;
 use cleaned_hosp;
 
 create table cl_patients(
patient_id VARCHAR(10) ,
first_name VARCHAR(50) ,
last_name VARCHAR(50) ,
date_of_birth Date ,
gender VARCHAR(10) ,
phone_number VARCHAR(15),
email VARCHAR(100),
address_line1 VARCHAR(100),
address_line2 VARCHAR(100),
city VARCHAR(50),
zip_code VARCHAR(10),
registration_date Date ,
primary_insurance VARCHAR(50),
secondary_insurance VARCHAR(50),
patient_status VARCHAR(10) DEFAULT 'ACTIVE',
emergency_contact VARCHAR(100)
);

INSERT INTO cl_patients (
    patient_id,
    first_name,
    last_name,
    date_of_birth,
    gender,
    phone_number,
    email,
    address_line1,
    address_line2,
    city,
    zip_code,
    registration_date,
    primary_insurance,
    secondary_insurance,
    patient_status,
    emergency_contact
)
SELECT 
    patient_id,

    -- First name cleanup
    LOWER(
        COALESCE(
            NULLIF(TRIM(first_name), ''), 
            SUBSTRING_INDEX(SUBSTRING_INDEX(email, '@', 1), '.', 1)
        )
    ) AS first_name,

    -- Last name cleanup
    LOWER(
        COALESCE(
            NULLIF(TRIM(last_name), ''), 
            SUBSTRING_INDEX(SUBSTRING_INDEX(email, '@', 1), '.', -1)
        )
    ) AS last_name,

    -- Date of birth cleanup (only valid dates)
    CAST(STR_TO_DATE(NULLIF(TRIM(date_of_birth),'') , '%m/%d/%Y') AS DATE) AS date_of_birth,

    -- Gender cleanup
    CASE 
        WHEN gender IN ('f', 'F', 'female', 'Female') THEN 'Female'
        WHEN gender IN ('m', 'M', 'male', 'Male') THEN 'Male'
        ELSE 'n/a'
    END AS gender,

    -- Phone number cleanup
    CONCAT('+20', TRIM(phone_number)) AS phone_number,

    -- Email cleanup
  CONCAT(
    LOWER(
      COALESCE(
        NULLIF(TRIM(first_name), ''), 
        SUBSTRING_INDEX(SUBSTRING_INDEX(email, '@', 1), '.', 1)
      )
    ),
    '.',
    LOWER(
      COALESCE(
        NULLIF(TRIM(last_name), ''), 
        SUBSTRING_INDEX(SUBSTRING_INDEX(email, '@', 1), '.', -1)
      )
    ),
    '@gmail.com'
  ) AS email,

    address_line1,
    address_line2,
    city,
    zip_code,

    -- Registration date cleanup
    CAST(
        STR_TO_DATE( NULLIF(TRIM(registration_date), '') , '%m/%d/%Y') AS DATE) AS registration_date,

    TRIM(primary_insurance) AS primary_insurance,
    TRIM(secondary_insurance) AS secondary_insurance,
    TRIM(patient_status) AS patient_status,
    emergency_contact
FROM (
    SELECT ps.*,
           ROW_NUMBER() OVER (
               PARTITION BY patient_id 
               ORDER BY CAST(
        STR_TO_DATE( NULLIF(TRIM(registration_date), '') , '%m/%d/%Y') AS DATE)
                DESC
           ) AS rn
    FROM hospital_staging.patients ps
    WHERE patient_id IS NOT NULL AND patient_id <> ''
) t
WHERE rn = 1;

select * from cl_patients;


SELECT* FROM cl_patients
WHERE patient_id IN (
    SELECT patient_id
    FROM (
        SELECT patient_id,
               ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY registration_date DESC) AS rn
        FROM cl_patients
    ) t
    WHERE rn > 1
);


-- check for null or spaces 
-- first name 
SELECT *
FROM cl_patients
WHERE first_name != TRIM(first_name) OR first_name= NULL OR first_name= '';

SELECT *
FROM cl_patients
WHERE last_name != TRIM(last_name) OR last_name= NULL OR last_name= ''; 

SELECT *
FROM cl_patients
WHERE phone_number != TRIM(phone_number) OR phone_number= NULL OR phone_number= ''; 

SELECT *
FROM cl_patients
WHERE address_line1 != TRIM(address_line1) OR address_line1= NULL OR address_line1= ''; 

SELECT *
FROM cl_patients
WHERE address_line2 != TRIM(address_line2) OR address_line2= NULL OR address_line2= ' '; 

SELECT *
FROM cl_patients
WHERE zip_code != TRIM(zip_code) OR zip_code= NULL OR zip_code= ' '; 

SELECT *
FROM cl_patients
WHERE emergency_contact != TRIM(emergency_contact) OR emergency_contact= NULL OR emergency_contact= ' '; 


-- check emails 
SELECT 
    patient_id,
    first_name,
    last_name,
    email
FROM cl_patients
WHERE TRIM(LOWER(email)) NOT LIKE CONCAT(LOWER(TRIM(first_name)), '.', LOWER(TRIM(last_name)), '@gmail.com')
AND first_name != ''
AND last_name != '';


-- check gender
select distinct gender from cl_patients;

-- check  primary_insurance
select distinct  primary_insurance from cl_patients;

-- check secondary_insurance
select distinct secondary_insurance from cl_patients;

-- CHECK patients_ states
select distinct patient_status from cl_patients;


-- ===================================
-- clinics
-- ========================

-- ========================================
-- data cleaning 
-- ========================================
-- clinics
use cleaned_hosp;
create table cl_clinics(
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


insert into cl_clinics(
clinic_code ,
clinic_name  ,
address ,
city ,
phone ,
manager_name ,
capacity_rooms ,
operating_hours ,
clinic_type 
)
select 
clinic_code,
clinic_name,
address,
TRIM(city) AS city,
concat('+20', phone) as phone ,
manager_name ,
capacity_rooms ,
  CONCAT(
    DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(operating_hours, '-', 1), '%H:%i'), '%h:%i %p'),
    ' - ',
    DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(operating_hours, '-', -1), '%H:%i'), '%h:%i %p')
  ) AS operating_hours
 ,
TRIM(clinic_type) as clinic_type

FROM (
		select PS.*, 
					row_number() over(partition by clinic_code order by clinic_code) as rn
                    from hospital_staging.clinics ps
                    where clinic_code is not null and clinic_code !=''
) t
where rn = 1;


-- check duplicates
select * from cl_clinics 
where clinic_code IN ( select clinic_code from 
				(select clinic_code , 
                row_number() over(partition by clinic_code order by clinic_code) AS rn 
                from cl_clinics ) t
            where rn > 1 );    


-- check nulls , spaces , blank

select * from cl_clinics 
where clinic_name != Trim(clinic_name) or
		clinic_name = '' or
        clinic_name = null;
        
select * from cl_clinics 
where address != Trim(address) or
		address  = '' or
        address  = null;
        
select * from cl_clinics 
where city != Trim(city) or
		city = '' or
        city = null;
        
select * from cl_clinics  
where phone != Trim(phone) or
		phone = '' or
        phone = null;
        
select * from cl_clinics 
where manager_name != Trim(manager_name) or
		manager_name = '' or
        manager_name = null;
        
select * from cl_clinics 
where capacity_rooms != Trim(capacity_rooms) or
		capacity_rooms = '' or
        capacity_rooms = null;
        
select * from cl_clinics 
where clinic_type != Trim(clinic_type) or
		clinic_type = '' or
        clinic_type = null;

select * from cl_clinics ;


-- ===================================
-- service_codes
-- ===================================

use cleaned_hosp;

create table cl_service_codes(
service_code VARCHAR(20),
service_description VARCHAR(200),
service_category VARCHAR(50),
base_cost DECIMAL(10,2),
duration_minutes INT,
department VARCHAR(50)
);

insert into cl_service_codes(
service_code ,
service_description ,
service_category ,
base_cost ,
duration_minutes ,
department 
)
select 
service_code ,
service_description ,
TRIM(service_category) as service_category,
base_cost ,
duration_minutes ,
department 
from (
select ps.* ,
			row_number() over(partition by service_code order by service_code) as rn 
            from hospital_staging.service_codes ps
            where service_code is not null and service_code != '') t
            where rn = 1;
            
            
            
-- check duplicates
select * from cl_service_codes
where service_code in ( select service_code from
					(select service_code , row_number() over(partition by service_code order by service_code) as rn
                    from cl_service_codes) t
                    where rn > 1 );

-- check nulls & spaces & blank

select * from cl_service_codes
where service_description != trim(service_description) or
service_description = '' or
service_description = null;

select * from cl_service_codes
where service_category != trim(service_category) or
service_category = '' or
service_category = null;

select * from cl_service_codes
where base_cost != trim(base_cost) or
base_cost = '' or
base_cost = null;

select * from cl_service_codes
where duration_minutes != trim(duration_minutes) or
duration_minutes = '' or
duration_minutes = null;

select * from cl_service_codes
where department != trim(department) or
department = '' or
department = null;



-- ===============
-- patient_surveys
-- ==============
use cleaned_hosp;

create table cl_patient_surveys(
survey_id INT ,
patient_id VARCHAR(10), 
appointment_id INT, 
survey_date VARCHAR(20),
service_date VARCHAR(20),
doctor_id VARCHAR(10), 
clinic_id VARCHAR(5), 
overall_satisfaction TINYINT ,
doctor_rating TINYINT,
facility_rating TINYINT ,
wait_time_rating TINYINT ,
recommendation_likelihood TINYINT ,
comments TEXT,
survey_method VARCHAR(20)
);

insert into cl_patient_surveys(
survey_id ,
patient_id , 
appointment_id , 
survey_date ,
service_date ,
doctor_id ,
clinic_id ,
overall_satisfaction ,
doctor_rating ,
facility_rating ,
wait_time_rating ,
recommendation_likelihood ,
comments ,
survey_method )

select 
survey_id,
patient_id , 
appointment_id , 
cast(str_to_date(NULLIF(TRIM(survey_date) , '') , '%m/%d/%Y') as Date) as survey_date ,
cast(str_to_date(NULLIF(TRIM(service_date) , '') , '%m/%d/%Y') as Date) as service_date ,
doctor_id ,
clinic_id ,
case when overall_satisfaction > 10 then 10 else  overall_satisfaction end as overall_satisfaction,
case when doctor_rating > 10 then 10 else doctor_rating  end as doctor_rating,
case when facility_rating > 10 then 10 else facility_rating  end as facility_rating,
wait_time_rating ,
recommendation_likelihood ,
comments ,
survey_method 

from (
		select ps.* , 
					row_number() over(partition by survey_id order by survey_id) as rn
                    from hospital_staging.patient_surveys ps
                    where survey_id is not null and survey_id != ''
                    ) t
			where rn = 1;
            
            
-- check duplicates
select * from cl_patient_surveys
where survey_id in ( select survey_id from
						(select survey_id, row_number() over(partition by survey_id order by survey_date) as rn
                        from cl_patient_surveys
                        ) t 
			where rn > 1);
            
-- check null & spaces & blank

select * from cl_patient_surveys
where patient_id != Trim(patient_id) or 
patient_id = null or
patient_id = '';

select * from cl_patient_surveys
where appointment_id != Trim(appointment_id) or 
appointment_id = null or
appointment_id = '';

select * from cl_patient_surveys
where doctor_id != Trim(doctor_id) or 
doctor_id = null or
doctor_id = '';

select * from cl_patient_surveys
where clinic_id != Trim(clinic_id) or 
clinic_id = null or
clinic_id = '';

select * from cl_patient_surveys
where overall_satisfaction < 0 or overall_satisfaction  > 10;

select * from cl_patient_surveys
where doctor_rating < 0 or doctor_rating  > 10;

select * from cl_patient_surveys
where facility_rating < 0 or facility_rating  > 10;

select * from cl_patient_surveys
where wait_time_rating < 0 or wait_time_rating > 10;

select * from cl_patient_surveys
where recommendation_likelihood < 0 or recommendation_likelihood > 10;

select * from cl_patient_surveys
where 
comments = null or
comments = '';

select * from cl_patient_surveys
where survey_method != TRIM(survey_method) or
comments = null or
comments = '';


-- ================
-- medical history
-- =================

use cleaned_hosp;

create table cl_medical_history(
history_id INT ,
patient_id VARCHAR(10),
condition_code VARCHAR(10),
condition_name VARCHAR(200),
diagnosis_date Date ,
severity VARCHAR(20) ,
chronic_flag VARCHAR(10),
notes TEXT,
doctor_id VARCHAR(10)
);
insert into cl_medical_history(
history_id ,
patient_id ,
condition_code ,
condition_name ,
diagnosis_date ,
severity ,
chronic_flag ,
notes ,
doctor_id 
)

select 
history_id,
patient_id,
condition_code,
TRIM(condition_name) as condition_name,
cast(str_to_date(NULLIF(TRIM(diagnosis_date), ''), '%m/%d/%Y') as Date ) as diagnosis_date,
TRIM(severity) as severity,
case 
	when chronic_flag in ('Y' , 'y' , 'yes' , 'Yes') then 'Yes' 
    when chronic_flag in ('N' , 'n' , 'no' , 'No') then 'No' 
 end as chronic_flag ,
 notes ,
doctor_id 

from (
		select ps.*,
					row_number() 
                    over(partition by history_id order by cast(str_to_date(NULLIF(TRIM(diagnosis_date), ''), '%m/%d/%Y') as Date )) as rn
                    from hospital_staging.medical_history ps
                    where history_id is not null and history_id != ''
                    )t
				where rn = 1;


select * from cl_medical_history;

-- check duplicate
select * from cl_medical_history
where history_id in( select history_id from(
								select history_id,
									row_number() over(partition by history_id order by diagnosis_date) as rn
                                    from cl_medical_history) t
						where rn > 1);
-- check nulls & spaces & blank
select * from cl_medical_history
where patient_id != trim(patient_id) or
patient_id = '' or
patient_id = null;

select * from cl_medical_history
where condition_code != trim(condition_code) or
condition_code = '' or
condition_code = null;

select * from cl_medical_history
where condition_name != trim(condition_name) or
condition_name = '' or
condition_name = null;

select * from cl_medical_history
where severity != trim(severity) or
severity = '' or
severity = null;

select distinct chronic_flag from cl_medical_history;

select * from cl_medical_history
where notes != trim(notes) or
notes = '' or
notes = null;

select * from cl_medical_history
where doctor_id != trim(doctor_id) or
doctor_id = '' or
doctor_id = null;


-- ===================
-- insurance_companies
-- ===================
 use cleaned_hosp;
 
 create table cl_insurance_companies(
 company_id INT ,
company_name VARCHAR(100) ,
company_type VARCHAR(30),
contact_info VARCHAR(200),
payment_terms_days INT
 );
 
 insert into cl_insurance_companies(
company_id ,
company_name ,
company_type ,
contact_info ,
payment_terms_days 
 )
 
 select 
 company_id ,
 company_name,
 trim(company_type) AS company_type,
 concat('+20' , contact_info),
 payment_terms_days 
 FROM hospital_staging.insurance_companies;


-- ==================
-- doctors
-- ==================

use cleaned_hosp;

create table cl_doctors(
doctor_code VARCHAR(10) ,
doctor_name VARCHAR(100) ,
specialization VARCHAR(50),
department VARCHAR(50),
hire_date date,
phone VARCHAR(15),
email VARCHAR(100),
status VARCHAR(10) DEFAULT 'ACTIVE',
primary_clinic VARCHAR(5)
);

INSERT INTO cl_doctors(
    doctor_code,
    doctor_name,
    specialization,
    department,
    hire_date,
    phone,
    email,
    status,
    primary_clinic
)
SELECT 
    doctor_code,
    CASE 
        WHEN doctor_name IS NULL OR TRIM(doctor_name) = '' 
             OR LENGTH(TRIM(doctor_name)) - LENGTH(REPLACE(TRIM(doctor_name), ' ', '')) = 0
        THEN CONCAT(
                -- first name
                UPPER(LEFT(COALESCE(SUBSTRING_INDEX(SUBSTRING_INDEX(email, '@', 1), '.', 1), ''), 1)),
                LOWER(SUBSTRING(COALESCE(SUBSTRING_INDEX(SUBSTRING_INDEX(email, '@', 1), '.', 1), ''), 2)),
                ' ',
                -- last name
                UPPER(LEFT(COALESCE(SUBSTRING_INDEX(SUBSTRING_INDEX(email, '@', 1), '.', -1), ''), 1)),
                LOWER(SUBSTRING(COALESCE(SUBSTRING_INDEX(SUBSTRING_INDEX(email, '@', 1), '.', -1), ''), 2))
             )
        ELSE doctor_name
    END AS doctor_name,
    TRIM(specialization) AS specialization,
    TRIM(department) AS department,
    CAST(STR_TO_DATE(NULLIF(TRIM(hire_date), ''), '%m/%d/%Y') AS DATE) AS hire_date,
    CONCAT('+20', phone),
    email,
    TRIM(status) AS status,
    primary_clinic
FROM hospital_staging.doctors;

select * from cl_doctors;

-- check if name( first last)
select * from  cl_doctors
where TRIM(doctor_name) not like '% %' or TRIM(doctor_name)= '' or TRIM(doctor_name)= null;
                    
-- check null & spaces & blank
select * from  cl_doctors
where specialization != TRIM(specialization)  or TRIM(specialization)= '' or TRIM(specialization)= null;

select * from  cl_doctors
where department != TRIM(department) or TRIM(department)= '' or TRIM(department)= null;

select * from  cl_doctors
where phone != TRIM(phone)  or TRIM(phone)= '' or TRIM(phone)= null;

select * from  cl_doctors
where email != TRIM(email)  or TRIM(email)= '' or TRIM(email)= null;

select * from  cl_doctors
where status != TRIM(status)  or TRIM(status)= '' or TRIM(status)= null;

select * from  cl_doctors
where primary_clinic != TRIM(primary_clinic) or TRIM(primary_clinic)= '' or TRIM(primary_clinic)= null;



-- ===============
-- appointments
-- ===============

use cleaned_hosp;

create table cl_appointments(
appt_id INT ,
patient_ref VARCHAR(10) , 
doctor_code VARCHAR(10) ,
clinic_code VARCHAR(5) ,
appt_date Date,
scheduled_start TIME ,
scheduled_end TIME ,
actual_start TIME,
actual_end TIME,
appt_type VARCHAR(20),
appt_status VARCHAR(15),
wait_time_mins INT,
created_by VARCHAR(50)
);

insert into cl_appointments(
appt_id ,
patient_ref,
doctor_code,
clinic_code ,
appt_date ,
scheduled_start ,
scheduled_end ,
actual_start ,
actual_end ,
appt_type ,
appt_status ,
wait_time_mins ,
created_by )

select 
appt_id ,
patient_ref,
doctor_code,
clinic_code ,
cast(str_to_date(nullif(trim(appt_date), ''), '%m/%d/%Y') as Date) as appt_date ,
scheduled_start ,
scheduled_end ,
actual_start ,
actual_end ,
trim(appt_type) as appt_type  ,
trim(appt_status) as appt_status,
wait_time_mins ,
trim(created_by) as created_by
from hospital_staging.appointments;

-- check null & spaces & blank
select * from cl_appointments
where appt_type != TRIM(appt_type)  or 
TRIM(appt_type)= '' or 
TRIM(appt_type)= null;

select * from cl_appointments
where appt_status != TRIM(appt_status)  or 
TRIM(appt_status)= '' or 
TRIM(appt_status)= null;

select * from cl_appointments
where created_by != TRIM(created_by)  or 
TRIM(created_by)= '' or 
TRIM(created_by)= null;




-- ==========================
-- `billing_transactions`
-- ==========================

use cleaned_hosp;
create table cl_billing_transactions(
transaction_id INT ,
patient_number VARCHAR(15) , 
doctor_ref VARCHAR(15) , 
appointment_ref INT, 
service_date date,
service_code VARCHAR(20),
service_description VARCHAR(200),
charged_amount DECIMAL(10,2),
insurance_company VARCHAR(100),
insurance_plan VARCHAR(50),
claim_number VARCHAR(30),
claim_submitted_date date,
claim_status VARCHAR(20),
insurance_paid DECIMAL(10,2),
patient_paid DECIMAL(10,2) ,
adjustment_amount DECIMAL(10,2) ,
outstanding_balance DECIMAL(10,2),
billing_date DATETIME DEFAULT CURRENT_TIMESTAMP,
payment_date VARCHAR(20)
);

insert into cl_billing_transactions(
transaction_id ,
patient_number ,
doctor_ref,
appointment_ref ,
service_date ,
service_code ,
service_description ,
charged_amount ,
insurance_company ,
insurance_plan ,
claim_number ,
claim_submitted_date ,
claim_status ,
insurance_paid ,
patient_paid ,
adjustment_amount ,
outstanding_balance ,
billing_date ,
payment_date 
)
select 
transaction_id ,
patient_number ,
doctor_ref,
appointment_ref ,
cast(str_to_date(nullif(trim(service_date),''), '%m/%d/%Y') as Date ) as service_date ,
service_code ,
trim(service_description) as  service_description,
charged_amount ,
trim(insurance_company) as insurance_company ,
trim(insurance_plan) as insurance_plan ,
claim_number ,
cast(str_to_date(nullif(trim(claim_submitted_date) , ''), '%m/%d/%Y') as Date) as  claim_submitted_date ,
trim(claim_status) as claim_status ,
insurance_paid ,
patient_paid ,
adjustment_amount ,
outstanding_balance ,
billing_date ,
payment_date 
from 
	(select ps.*,
		row_number() over(partition by transaction_id order by cast(str_to_date(nullif(trim(service_date),''), '%m/%d/%Y') as Date ) ) as rn
        from hospital_staging.billing_transactions ps
        where transaction_id is not null and transaction_id != ''
        ) t
        where rn = 1;
        
 
 
 select * from cl_billing_transactions;
-- check dup
select * from cl_billing_transactions
where transaction_id in ( select transaction_id from(
							select transaction_id , row_number() over(partition by transaction_id order by service_date desc) as rn
                            from cl_billing_transactions) t
					where rn > 1);
                    
-- check for nulls & spaces & blank
select * from cl_billing_transactions
where appointment_ref != TRIM(appointment_ref)  or 
TRIM(appointment_ref)= '' or 
TRIM(appointment_ref)= null;

select * from cl_billing_transactions
where service_code != TRIM(service_code)  or 
TRIM(service_code)= '' or 
TRIM(service_code)= null;

select * from cl_billing_transactions
where service_description != TRIM(service_description)  or 
TRIM(service_description)= '' or 
TRIM(service_description)= null;

select * from cl_billing_transactions
where charged_amount != TRIM(charged_amount)  or 
TRIM(charged_amount)= '' or 
TRIM(charged_amount)= null or
charged_amount < 0;

select * from cl_billing_transactions
where insurance_company != TRIM(insurance_company)  or 
TRIM(insurance_company)= '' or 
TRIM(insurance_company)= null;

select * from cl_billing_transactions
where insurance_plan != TRIM(insurance_plan)  or 
TRIM(insurance_plan)= '' or 
TRIM(insurance_plan)= null;

select * from cl_billing_transactions
where claim_number != TRIM(claim_number)  or 
TRIM(claim_number)= '' or 
TRIM(claim_number)= null;

select * from cl_billing_transactions
where claim_status != TRIM(claim_status)  or 
TRIM(claim_status)= '' or 
TRIM(claim_status)= null;

select * from cl_billing_transactions
where insurance_paid != TRIM(insurance_paid)  or 
TRIM(insurance_paid)= '' or 
TRIM(insurance_paid)= null or
insurance_paid < 0;

select * from cl_billing_transactions
where patient_paid != TRIM(patient_paid)  or 
TRIM(patient_paid)= '' or 
TRIM(patient_paid)= null or
patient_paid < 0;

select * from cl_billing_transactions
where adjustment_amount != TRIM(adjustment_amount)  or 
TRIM(adjustment_amount)= '' or 
TRIM(adjustment_amount)= null or
adjustment_amount < 0;

select * from cl_billing_transactions
where outstanding_balance != TRIM(outstanding_balance)  or 
TRIM(outstanding_balance)= '' or 
TRIM(outstanding_balance)= null or
outstanding_balance < 0;

