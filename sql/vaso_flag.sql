-- Create a table which indicates if a patient was ever on a vasopressor
-- during their ICU stay

-- List of vasopressors used:
-- norepinephrine - 221906
-- epinephrine - 221289
-- phenylephrine - 221749
-- vasopressin - 222315
-- dopamine - 221662
-- Isuprel - 227692

with io_mv as
(
  select
    icustay_id, linkorderid, starttime, endtime
  from `physionet-data.mimiciii_clinical.inputevents_mv` io
  -- Subselect the vasopressor ITEMIDs
  where itemid in
  (
  221906 -- norepinephrine
  ,221289 -- epinephrine
  ,221749 -- phenylephrine
  ,222315 -- vasopressin
  ,221662 -- dopamine
  ,227692 -- isuprel
  )
  and rate is not null
  and rate > 0
)
select
  co.subject_id, co.hadm_id, co.icustay_id
  , MAX(CASE
          WHEN io_mv.icustay_id is not null then 1
  else 0 end) as vaso_flag
from `physionet-data.mimiciii_clinical.icustays` co
left join io_mv
  on co.icustay_id = io_mv.icustay_id
group by co.subject_id, co.hadm_id, co.icustay_id
