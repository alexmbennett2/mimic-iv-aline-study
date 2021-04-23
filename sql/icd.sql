-- Extract data which is based on ICD-9 codes
WITH dx AS
(
  SELECT hadm_id, TRIM(icd9_code) AS icd_code
  FROM `physionet-data.mimiciii_clinical.diagnoses_icd`
)
, icd9 AS
(
  select
  hadm_id
  , max(case when icd_code in
  (  '03642','07422','09320','09321','09322','09323','09324','09884'
    ,'11281','11504','11514','11594'
    ,'3911', '4210', '4211', '4219'
    ,'42490','42491','42499'
  ) then 1 else 0 end) as endocarditis

  -- chf
  , max(case when icd_code in
  (  '39891','40201','40291','40491','40413'
    ,'40493','4280','4281','42820','42821'
    ,'42822','42823','42830','42831','42832'
    ,'42833','42840','42841','42842','42843'
    ,'4289','428','4282','4283','4284'
  ) then 1 else 0 end) as chf

  -- atrial fibrilliation or atrial flutter
  , max(case when icd_code like '4273%' then 1 else 0 end) as afib

  -- renal
  , max(case when icd_code like '585%' then 1 else 0 end) as renal

  -- liver
  , max(case when icd_code like '571%' then 1 else 0 end) as liver

  -- copd
  , max(case when icd_code in
  (  '4660','490','4910','4911','49120'
    ,'49121','4918','4919','4920','4928'
    ,'494','4940','4941','496') then 1 else 0 end) as copd

  -- coronary artery disease
  , max(case when icd_code like '414%' then 1 else 0 end) as cad

  -- stroke
  , max(case when icd_code like '430%'
      or icd_code like '431%'
      or icd_code like '432%'
      or icd_code like '433%'
      or icd_code like '434%'
       then 1 else 0 end) as stroke

  -- malignancy, includes remissions
  , max(case when icd_code between '140' and '239' then 1 else 0 end) as malignancy

  -- resp failure
  , max(case when icd_code like '518%' then 1 else 0 end) as respfail

  -- ARDS
  , max(case when icd_code = '51882' or icd_code = '5185' then 1 else 0 end) as ards

  -- pneumonia
  , max(case when icd_code between '486' and '48881'
      or icd_code between '480' and '48099'
      or icd_code between '482' and '48299'
      or icd_code between '506' and '5078'
        then 1 else 0 end) as pneumonia
  from dx
  group by hadm_id
)

SELECT
  co.hadm_id
  -- merge icd-9 and icd-10 codes
  , COALESCE(icd9.endocarditis, 0) AS endocarditis
  , COALESCE(icd9.chf, 0) AS chf
  , COALESCE(icd9.afib, 0) AS afib
  , COALESCE(icd9.renal, 0) AS renal
  , COALESCE(icd9.liver, 0) AS liver
  , COALESCE(icd9.copd, 0) AS copd
  , COALESCE(icd9.cad, 0) AS cad
  , COALESCE(icd9.stroke, 0) AS stroke
  , COALESCE(icd9.malignancy, 0) AS malignancy
  , COALESCE(icd9.respfail, 0) AS respfail
  , COALESCE(icd9.ards, 0) AS ards
  , COALESCE(icd9.pneumonia, 0) AS pneumonia
FROM aline.cohort co
LEFT JOIN icd9
  ON co.hadm_id = icd9.hadm_id
