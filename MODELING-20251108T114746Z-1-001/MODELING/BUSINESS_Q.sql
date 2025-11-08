use healthcare_dwh;
--  Q1:Average patient satisfaction per doctor
SELECT 
    d.doctor_name,
    ROUND(AVG(f.Overall_Satisfaction_Score), 2) AS Avg_Satisfaction,
    COUNT(*) AS Surveys
FROM FACT_Patient_Satisfaction f
JOIN DIM_Doctor d ON f.doctor_key = d.Doctor_Key
GROUP BY d.doctor_name
ORDER BY Avg_Satisfaction DESC;

-- Q2:Treatment success rate per department
SELECT 
    t.department,
    COUNT(*) AS Total_Treatments,
    SUM(f.success_flag) AS Successful_Treatments,
    ROUND(SUM(f.success_flag)/COUNT(*)*100, 2) AS Success_Rate_Percent
FROM FACT_Treatments f
JOIN DIM_Treatment t ON f.treatment_key = t.treatment_key
GROUP BY t.department
ORDER BY Success_Rate_Percent DESC;

-- Q3: Revenue per insurance type
SELECT 
    i.insurance_company,
    i.plan_type,
    SUM(f.charged_amount) AS Total_Charged,
    SUM(f.insurance_paid_amount) AS Total_Insurance_Paid,
    SUM(f.patient_paid_amount) AS Total_Patient_Paid
FROM FACT_Billing f
JOIN DIM_Insurance i ON f.Insurance_Key = i.Insurance_Key
GROUP BY i.insurance_company, i.plan_type
ORDER BY Total_Charged DESC;

-- Q4: Average wait time & no-show rate per clinic
SELECT 
    c.clinic_name,
    ROUND(AVG(f.wait_time_minutes), 2) AS Avg_Wait_Time,
    ROUND(SUM(f.no_show_flag)/COUNT(*)*100, 2) AS No_Show_Rate_Percent
FROM FACT_Appointments f
JOIN DIM_Clinic c ON f.clinic_key = c.clinic_key
GROUP BY c.clinic_name
ORDER BY Avg_Wait_Time ASC;

-- Q5: Billing claim approval rate
SELECT 
    c.clinic_name,
    ROUND(SUM(f.claim_approved_flag)/COUNT(*)*100, 2) AS Claim_Approval_Rate,
    ROUND(AVG(f.claim_processing_days), 2) AS Avg_Processing_Days
FROM FACT_Billing f
JOIN DIM_Clinic c ON f.clinic_key = c.clinic_key
GROUP BY c.clinic_name
ORDER BY Claim_Approval_Rate DESC;






