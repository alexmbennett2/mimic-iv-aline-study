-- ------------------------------------------------------------------
-- Title: Extract height and weight for BMI
-- Description: This query gets the first weight and height for a single stay.
-- It extracts data from the chartevents table.
-- ------------------------------------------------------------------

WITH ht AS
(
  SELECT 
    c.subject_id, c.icustay_id, c.charttime,
    -- Ensure that all heights are in centimeters, and fix data as needed
    CASE
        -- ignoring neonates, no anchor_age available
        WHEN (c.valuenum * 2.54) > 120
         AND (c.valuenum * 2.54) < 230
          THEN c.valuenum * 2.54
        -- set bad data to NULL
        ELSE NULL
    END AS height
    , ROW_NUMBER() OVER (PARTITION BY icustay_id ORDER BY charttime) AS rn
  FROM `physionet-data.mimiciii_clinical.chartevents` c
  INNER JOIN `physionet-data.mimiciii_clinical.patients` pt
    ON c.subject_id = pt.subject_id
  WHERE c.valuenum IS NOT NULL
  AND c.valuenum != 0
  AND c.itemid IN
  (
      226707 -- Height (measured in inches)
    -- note we intentionally ignore the below ITEMID in metavision
    -- these are duplicate data in a different unit
    -- , 226730 -- Height (cm)
  )
)
, wt AS
(
    SELECT
        c.icustay_id
      , c.charttime
      -- TODO: eliminate obvious outliers if there is a reasonable weight
      , c.valuenum as weight
      , ROW_NUMBER() OVER (PARTITION BY icustay_id ORDER BY charttime) AS rn
    FROM `physionet-data.mimiciii_clinical.chartevents` c
    WHERE c.valuenum IS NOT NULL
      AND c.itemid = 226512 -- Admit Wt
      AND c.icustay_id IS NOT NULL
      AND c.valuenum > 0
)
select
    co.icustay_id
    , case
        when ht.height is not null and wt.weight is not null
            then (wt.weight / (ht.height/100*ht.height/100))
        else null
    end as BMI
    , ht.height
    , wt.weight
from aline.cohort co
left join ht
  on co.icustay_id = ht.icustay_id
  AND ht.rn = 1
left join wt
  on co.icustay_id = wt.icustay_id
  AND wt.rn = 1
