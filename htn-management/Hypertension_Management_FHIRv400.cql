// # Introduction

// The Hypertension Management logic library supports decision-making on diagnosing and managing Hypertension treatment.

library Hypertension_Management_FHIRv400 version '1.0.0'

// # Data model #

using FHIR version '4.0.0'

// # Referenced libraries #

// Library excerpts from eCQM measure expressions for high blood pressure
include ControllingHighBloodPressure_FHIRv400 version '1.0.0' called CBP
// The CDS Connect Commons for FHIRv400 library provides functions representing commonly used CDS logic and patterns.
include CDS_Connect_Commons_for_FHIRv400 version '1.0.1' called C3F
// The FHIRHelpers library provides common functions for simplifying interaction w/ the FHIR R4 data model.
include FHIRHelpers version '4.0.0' called FHIRHelpers

// # Value sets and codes #

// ## Code Systems ##

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMED-CT": 'http://snomed.info/sct'

// ## Value sets ##

// Value sets not available in VSAC, included via expanded FHIR ValueSet resources

// [See value set in VSAC](https://vsac.nlm.nih.gov/valueset/2.16.840.1.113883.3.526.2.39/expansion)
valueset "ACE Inhibitor or ARB or ARNI": '2.16.840.1.113883.3.526.2.39'

// [See value set in VSAC](https://vsac.nlm.nih.gov/valueset/2.16.840.1.113883.3.464.1003.104.12.1016/expansion)
valueset "Hypertension": '2.16.840.1.113883.3.464.1003.104.12.1016'

// [See value set in VSAC](https://vsac.nlm.nih.gov/valueset/2.16.840.1.113762.1.4.1222.159/expansion)
valueset "Chronic Kidney Disease All Stages": '2.16.840.1.113762.1.4.1222.159'


// ## Individual codes ##

// list individual codes from code systems used directly in the CQL logic. Individual codes are used when there is
// a single code from a particular vocabulary standard used to represent a clinical concept. It is considered
// best-practice not to create value sets containing a single code.

code "Blood pressure": '85354-9' from "LOINC" display 'Blood pressure systolic and diastolic'
code "Systolic blood pressure": '8480-6' from "LOINC" display 'Systolic blood pressure'
code "Diastolic blood pressure": '8462-4' from "LOINC" display 'Diastolic blood pressure'

// # Parameters #

// The InclusionMedicationsLookbackPeriod allows CDS implementors to specify how far the inclusion logic should look
// back for qualifying active medications. By default, the inclusion logic will look back 180 days.
parameter InclusionMedicationsLookbackPeriod default 90 days

// # CDS logic #

context Patient

// Hypertension Management logic

define "Has CKD diagnosis":
  exists( "Chronic Kidney Disease Conditions" )

define "Has Hypertension diagnosis":
  exists( "Hypertension Conditions" )

define "Hypertension Conditions":
  C3F.Confirmed(C3F.ActiveOrRecurring([Condition: "Hypertension"]))

define "Chronic Kidney Disease Conditions":
  C3F.Confirmed(C3F.ActiveOrRecurring([Condition: "Chronic Kidney Disease All Stages"]))

define "Has Uncontrolled Hypertension":
  CBP."Has Systolic Blood Pressure Greater Than 140"
  or CBP."Has Diastolic Blood Pressure Greater Than 90"

define "Has Suspected Hypertension":
  "Has Uncontrolled Hypertension"
  and not "Has Hypertension diagnosis"


// Determines if the patient has any record of Antihypertensive medications in the lookback period
//       - Medication Request within lookback period (currently 90 days)
define "Has Recent Antihypertensive Medication":
exists(C3F.ActiveCompletedOrStoppedMedicationRequest(C3F.MedicationRequestLookBack(
  [MedicationRequest: "ACE Inhibitor or ARB or ARNI"],
  InclusionMedicationsLookbackPeriod)
))

define "Recommend Antihypertensive Medication":
  "Has Uncontrolled Hypertension"
  and not "Has Recent Antihypertensive Medication"


// CDS Hook dynamic values

define SuspectedHypertensionTitle: 'Suspected Hypertension'

define SuspectedHypertensionDetail: 'This patient may have undiagnosed hypertension'

define SuspectedHypertensionSeverity: 'warning'

define UncontrolledHypertensionTitle: 'Has Uncontrolled Hypertension'

define UncontrolledHypertensionDetail: 'This patient has uncontrolled hypertension'

define UncontrolledHypertensionSeverity: 'warning'

define RecommendAntihypertensiveTitle: 'Recommend ACE Inhibitor or ARB'

define RecommendAntihypertensiveDetail: 'Recommend ordering ACE Inhibitor or ARB for this patient.'

define RecommendAntihypertensiveSeverity: 'info'
