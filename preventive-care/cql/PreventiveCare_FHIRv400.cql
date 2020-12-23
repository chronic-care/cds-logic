// # Introduction

// The Preventive Care logic library supports decision-making on preventive care screening.

library PreventiveCare_FHIRv400 version '1.0.0'

// # Data model #

using FHIR version '4.0.1'

// # Referenced libraries #

// The CDS Connect Commons for FHIRv400 library provides functions representing commonly used CDS logic and patterns.
include CDS_Connect_Commons_for_FHIRv400 version '1.0.2' called C3F
// The FHIRHelpers library provides common functions for simplifying interaction w/ the FHIR R4 data model.
include FHIRHelpers version '4.0.1' called FHIRHelpers
// The PreventiveCareConcepts library provides terminology concepts used to identify data elements throughout the artifact.
include PreventiveCareConcepts version '1.0.0' called PCC
// The CDS_Reporting library provides common functions for summarizing and reporting clinical data
include CDS_Reporting_FHIRv400 version '1.0.0' called RPT

// # Parameters #

// The InclusionMedicationsLookbackPeriod allows CDS implementors to specify how far the inclusion logic should look
// back for qualifying active medications. By default, the inclusion logic will look back 180 days.
parameter InclusionMedicationsLookbackPeriod default 90 days

// # CDS logic #

context Patient

// # General definitions based on value sets and codes #

define "Patient Race":
  (flatten (
    Patient.extension Extension
      where Extension.url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race'
        return Extension.extension
  )) E
    where E.url = 'ombCategory'
      or E.url = 'detailed'
    return E.value as Coding

// # Preventive Care logic #

define "Patient is male":
  Patient.gender = 'male'

define "Patient is 55 or older":
  AgeInYears() >= 55

define "Race is African American":
  "Patient Race" contains PCC."Black or African American"

/* Prostate cancer */
define "Has prostate cancer diagnosis":
  exists( "Prostate cancer conditions" )

define "Prostate cancer conditions":
  C3F.Confirmed(C3F.ActiveOrRecurring([Condition: PCC."Prostate cancer"]))

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

define "Has PSA within one year":
  exists(C3F.ObservationLookBack("PSA Observations", 1 year))

// # PSA risk statements #

// TODO handle unknown FH. Research negation of conditions and unknown.
define "PSA risk statement 1":
  if "Race is African American" and "Has family history of prostate cancer"
    then 'You are African American and have a family history of prostate cancer.  This places you at higher risk for prostate cancer.'
  else if not "Race is African American" and "Has family history of prostate cancer"
    then 'You have a family history of prostate cancer.  This places you at higher risk for prostate cancer.'
  else if "Race is African American" and not "Has family history of prostate cancer"
    then 'You are African American.  This places you at higher risk for prostate cancer.'
  else if "Race is African American"
    then 'You are African American.  This places you at higher risk for prostate cancer.  You said you are unsure if you have a family history of prostate cancer.  If you do, this also places you at higher risk for prostate cancer.'
  else if not "Race is African American"
    then 'You said you are unsure if you have a family history of prostate cancer.  If you do, this places you at higher risk for prostate cancer.'
  else
    null

// TODO handle unknown FH. Research negation of conditions and unknown.
define "PSA risk statement 2":
  if "Race is African American" and "Has family history of prostate cancer"
    then 'are African American and have a family history of prostate cancer'
  else if not "Race is African American" and "Has family history of prostate cancer"
    then 'have a family history of prostate cancer'
  else if "Race is African American" and not "Has family history of prostate cancer"
    then 'are African American'
  else if "Race is African American"
    then 'are African American and may have a family history of prostate cancer'
  else if not "Race is African American"
    then 'may have a family history of prostate cancer'
  else
    null

// # Patient text blocks #
