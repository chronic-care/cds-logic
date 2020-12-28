library ControllingHighBloodPressure_FHIRv400 version '1.0.0'

/*
	Controlling High Blood Pressure (CBP)

	Adapted from eCQM EXM165
	http://build.fhir.org/ig/cqframework/draft-measures/examples.html
*/

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0'

codesystem "LOINC": 'http://loinc.org'

code "Blood pressure": '85354-9' from "LOINC" display 'blood pressure'
code "Diastolic blood pressure": '8462-4' from "LOINC" display 'Diastolic blood pressure'
code "Systolic blood pressure": '8480-6' from "LOINC" display 'Systolic blood pressure'

// parameter "Measurement Period" Interval<DateTime>
parameter InclusionObservationsLookbackPeriod default 90 days

context Patient

// Common Functions

define function "GetId"(uri String):
	Last(Split(uri, '/'))

define function GetEncounter(reference Reference):
  singleton from ( [Encounter: id in GetId(reference.reference)] )

define function LookBackInterval(LookBack System.Quantity):
	Interval[Now() - LookBack, Now()]

define "Measurement Period":
	LookBackInterval(InclusionObservationsLookbackPeriod)

// Blood Pressure logic

define "Has Diastolic Blood Pressure Greater Than 90":
	"Lowest Diastolic Reading on Most Recent Blood Pressure Day".value > 90

define "Has Systolic Blood Pressure Greater Than 140":
	"Lowest Systolic Reading on Most Recent Blood Pressure Day".value > 140

define "Has Diastolic Blood Pressure Less Than 90":
	"Lowest Diastolic Reading on Most Recent Blood Pressure Day".value < 90

define "Has Systolic Blood Pressure Less Than 140":
	"Lowest Systolic Reading on Most Recent Blood Pressure Day".value < 140

define "Lowest Diastolic Reading on Most Recent Blood Pressure Day":
	Last(
    "Qualifying Diastolic Blood Pressure Reading" DBPReading
		  where DBPReading.effective same day as "Most Recent Blood Pressure Day"
      return singleton from (
        DBPReading.component C
          where C.code ~ ToConcept("Diastolic blood pressure")
          return C.value as Quantity
      )
			/* sort ascending */
			// TODO CQL runtime error on sort, Quantity is not comparable
	)

define "Lowest Systolic Reading on Most Recent Blood Pressure Day":
	Last(
    "Qualifying Systolic Blood Pressure Reading" SBPReading
		  where SBPReading.effective same day as "Most Recent Blood Pressure Day"
      return singleton from (
        SBPReading.component C
          where C.code ~ ToConcept("Systolic blood pressure")
          return C.value as Quantity
      )
      /* sort ascending */
	)

define "Blood Pressure Days":
	( ( "Qualifying Diastolic Blood Pressure Reading" DBPExam
				return date from DBPExam.effective
		)
			intersect ( "Qualifying Systolic Blood Pressure Reading" SBPExam
					return date from SBPExam.effective
			)
	)

define "Most Recent Blood Pressure Day":
	Max("Blood Pressure Days")

define "Qualifying Diastolic Blood Pressure Reading":
	[Observation: "Blood pressure"] BloodPressure
	  where BloodPressure.status in {'final', 'amended'}
      and BloodPressure.effective during "Measurement Period"
      // TODO: Turn this into a value set
	    and not (GetEncounter(BloodPressure.encounter).class.code in { 'EMER', 'IMP', 'ACUTE', 'NONAC', 'PRENC', 'SS' })
      and exists (
        BloodPressure.component DiastolicBP
	        where DiastolicBP.code ~ ToConcept("Diastolic blood pressure")
//            and DiastolicBP.value.unit = 'mm[Hg]'
// TODO: CQL translation error on above: Error:[82:35, 82:38] name cannot be null
      )

define "Qualifying Systolic Blood Pressure Reading":
	[Observation: "Blood pressure"] BloodPressure
	  where BloodPressure.status in {'final', 'amended'}
      and BloodPressure.effective during "Measurement Period"
	    and not (GetEncounter(BloodPressure.encounter).class.code in { 'EMER', 'IMP', 'ACUTE', 'NONAC', 'PRENC', 'SS'})
      and exists (
        BloodPressure.component SystolicBP
	        where SystolicBP.code ~ ToConcept("Systolic blood pressure")
//            and SystolicBP.value.unit = 'mm[Hg]'
      )
