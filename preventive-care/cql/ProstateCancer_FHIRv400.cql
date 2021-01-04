// # Introduction

// The Preventive Care logic library supports decision-making on preventive care screening for Prostate Cancer.

library ProstateCancer_FHIRv400 version '1.0.0'

// # Data model #

using FHIR version '4.0.1'

// # Referenced libraries #

// The FHIRHelpers library provides common functions for simplifying interaction w/ the FHIR R4 data model.
include FHIRHelpers version '4.0.1' called FHIRHelpers
// The CDS Connect Commons for FHIRv400 library provides functions representing commonly used CDS logic and patterns.
include CDS_Connect_Commons_for_FHIRv400 version '1.0.2' called C3F
// The CDS_Reporting library provides common functions for summarizing and reporting clinical data
include CDS_Reporting_FHIRv400 version '1.0.0' called RPT
// The PreventiveCareConcepts library provides terminology concepts used to identify data elements throughout the artifact.
include PreventiveCareConcepts version '1.0.0' called PCC
// The PreventiveCareData library provides common data retrieval logic for preventive care guidelines.
include PreventiveCareData_FHIRv400 version '1.0.0' called Data

// # CDS logic #

context Patient

/* Prostate cancer screening logic */

define "Has prostate cancer Hx":
  exists( "Prostate cancer conditions" )

define "Prostate cancer conditions":
  Data."All active conditions" C
    where C.code ~ PCC."Prostate cancer"

define "Has family history of prostate cancer":
  /* exists([FamilyMemberHistory.condition.code: PCC."Prostate cancer"]) */
  exists([Condition: PCC."Family history of prostate cancer"])

define "PSA Observations":
  C3F.Verified([Observation: PCC."Prostate Specific Antigen Test"])

define "Last PSA":
  C3F.MostRecent("PSA Observations")

define "Last PSA value":
  C3F.QuantityValue("Last PSA")

define "Last PSA date":
  C3F.FindDate("Last PSA")

define "Has PSA test":
  exists("PSA Observations")

define "No PSA test results":
  not exists("PSA Observations")

define "Has PSA within one year":
  exists(C3F.ObservationLookBack("PSA Observations", 1 year))

define "Has high PSA value":
  exists("PSA Observations" C
    where C3F.QuantityValue(C).value > 4.0)

define "Last PSA value is high":
  "Last PSA value" > 4.0

// # Text Variables #

define "PC Status":
  if "Has prostate cancer Hx"
    then Data."Patient PCP name" + ' says that you have a history of prostate cancer'
  else if "Has high PSA value"
    then 'you said that you have a history of high PSA value (PSA value higher than 4.0)'
  else
    null

define "MI PSA Date 1":
  if "Has PSA within one year"
    then Data."Patient PCP name" + '\'s record states that you last had a PSA test on ' + ToString("Last PSA date") + '.  You may be up-to-date with your PSA test.'
  else if "Has PSA test"
    then Data."Patient PCP name" + '\'s record states that you last had a PSA test on ' + ToString("Last PSA date") + '.  You may be due for another PSA test.'
  else Data."Patient PCP name" + ' does not have a record of when your last PSA was.'

// # PSA risk statements #

// TODO handle unknown FH. Research negation of conditions and unknown.
define "PSA risk statement 1":
  if Data."Race is African American" and "Has family history of prostate cancer"
    then 'You are African American and have a family history of prostate cancer.  This places you at higher risk for prostate cancer.'
  else if not Data."Race is African American" and "Has family history of prostate cancer"
    then 'You have a family history of prostate cancer.  This places you at higher risk for prostate cancer.'
  else if Data."Race is African American" and not "Has family history of prostate cancer"
    then 'You are African American.  This places you at higher risk for prostate cancer.'
  else if Data."Race is African American"
    then 'You are African American.  This places you at higher risk for prostate cancer.  You said you are unsure if you have a family history of prostate cancer.  If you do, this also places you at higher risk for prostate cancer.'
  else
    'You said you are unsure if you have a family history of prostate cancer.  If you do, this places you at higher risk for prostate cancer.'

// TODO handle unknown FH. Research negation of conditions and unknown.
define "PSA risk statement 2":
  if Data."Race is African American" and "Has family history of prostate cancer"
    then 'are African American and have a family history of prostate cancer'
  else if not Data."Race is African American" and "Has family history of prostate cancer"
    then 'have a family history of prostate cancer'
  else if Data."Race is African American" and not "Has family history of prostate cancer"
    then 'are African American'
  else if Data."Race is African American"
    then 'are African American and may have a family history of prostate cancer'
  else
    'may have a family history of prostate cancer'

// # Patient text blocks #

define "Need PSA statement":
  Data."Patient PCP name" + '\'s record says you last had a PSA test on ' + ToString("Last PSA date")
