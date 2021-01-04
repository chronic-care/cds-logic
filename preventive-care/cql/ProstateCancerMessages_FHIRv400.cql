// # Introduction

// The Preventive Care logic library supports decision-making on preventive care screening for Prostate Cancer.

library ProstateCancerMessages_FHIRv400 version '1.0.0'

// # Data model #

using FHIR version '4.0.1'

// # Referenced libraries #

// The PreventiveCareData library provides common data retrieval logic for preventive care guidelines.
include PreventiveCareData_FHIRv400 version '1.0.0' called Data
// The ProstateCancer library provides common data retrieval logic for preventive care guidelines.
include ProstateCancer_FHIRv400 version '1.0.0' called PC

// # CDS logic #

context Patient


// # Next Steps #

define "Next Step 1":
  'Talk with ' + Data."Patient PCP name" + ' about whether you need another PSA test now.'

define "Next Step 4":
  'Learn about PSA testing and think about whether you want another test after ' + ToString(PC."Last PSA date" + 2 years)

// # Text Variables #

define "PC Status":
  if PC."Has prostate cancer Hx"
    then Data."Patient PCP name" + ' says that you have a history of prostate cancer'
  else if PC."Has high PSA value"
    then 'you said that you have a history of high PSA value (PSA value higher than 4.0)'
  else
    null

define "MI PSA Date 1":
  if PC."Has PSA within one year"
    then Data."Patient PCP name" + '\'s record states that you last had a PSA test on ' + ToString(PC."Last PSA date") + '.  You may be up-to-date with your PSA test.'
  else if PC."Has PSA test"
    then Data."Patient PCP name" + '\'s record states that you last had a PSA test on ' + ToString(PC."Last PSA date") + '.  You may be due for another PSA test.'
  else Data."Patient PCP name" + ' does not have a record of when your last PSA was.'

define "PSA value 1":
  'Your last PSA value was ' + ToString(PC."Last PSA value".value) + '. Generally, a PSA below 4 is considered good. Higher values may be, OK if they are not increasing over time.'

// # PSA risk statements #

// TODO handle unknown FH. Research negation of conditions and unknown.
define "PSA risk statement 1":
  if Data."Race is African American" and PC."Has family history of prostate cancer"
    then 'You are African American and have a family history of prostate cancer.  This places you at higher risk for prostate cancer.'
  else if not Data."Race is African American" and PC."Has family history of prostate cancer"
    then 'You have a family history of prostate cancer.  This places you at higher risk for prostate cancer.'
  else if Data."Race is African American" and not PC."Has family history of prostate cancer"
    then 'You are African American.  This places you at higher risk for prostate cancer.'
  else if Data."Race is African American"
    then 'You are African American.  This places you at higher risk for prostate cancer.  You said you are unsure if you have a family history of prostate cancer.  If you do, this also places you at higher risk for prostate cancer.'
  else
    'You said you are unsure if you have a family history of prostate cancer.  If you do, this places you at higher risk for prostate cancer.'

// TODO handle unknown FH. Research negation of conditions and unknown.
define "PSA risk statement 2":
  if Data."Race is African American" and PC."Has family history of prostate cancer"
    then 'are African American and have a family history of prostate cancer'
  else if not Data."Race is African American" and PC."Has family history of prostate cancer"
    then 'have a family history of prostate cancer'
  else if Data."Race is African American" and not PC."Has family history of prostate cancer"
    then 'are African American'
  else if Data."Race is African American"
    then 'are African American and may have a family history of prostate cancer'
  else
    'may have a family history of prostate cancer'

// # Patient text blocks #

define "Need PSA statement":
  Data."Patient PCP name" + '\'s record says you last had a PSA test on ' + ToString(PC."Last PSA date")
