// # Introduction

// Shared logic library that supports CDS reporting.

library CDS_Reporting_FHIRv400 version '1.0.0'

// # Data model #

using FHIR version '4.0.1'

// # Referenced libraries #

// The CDS Connect Commons for FHIRv400 library provides functions representing commonly used CDS logic and patterns.
include CDS_Connect_Commons_for_FHIRv400 version '1.0.2' called C3F
// The FHIRHelpers library provides common functions for simplifying interaction w/ the FHIR R4 data model.
include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "Condition Category Codes": 'http://hl7.org/fhir/condition-category' // NOTE: This is the STU3 category, should really be the R4 category, but some systems still return this
//codesystem "Condition Category Codes": 'http://terminology.hl7.org/CodeSystem/condition-category'

code "Encounter Diagnosis code": 'encounter-diagnosis' from "Condition Category Codes" display 'Encounter Diagnosis'

// # CDS logic #

context Patient

// The following condition functions are used here to address the difference in behavior
// between a "problem-list-item" condition and other categories of conditions.
// Specifically, problem-list-items typically have clinicalStatus and verificationStatus
// where encounter-diagnoses in particular would not be expected to have those items
// For the PainManager use case, encounter-diagnoses can be included.
// NOTE: Encounter-diagnoses should be filter by a lookback, but that is not handled by these functions

/**
 * Returns true if the Condition has a category of "encounter-diagnosis"
 */
define function IsEncounterDiagnosis(Condition Condition):
  exists (Condition.category C where C ~ "Encounter Diagnosis code")
    and Condition.recordedDate after Today() - 1 year

/**
 * Conditions that are confirmed. In FHIR R4, this is reflected by verificationStatus: 'confirmed'.
 * @see http://hl7.org/fhir/R4/valueset-condition-ver-status.html
 * @param CondList - a list of Conditions
 * @returns {List<Condition>} a list of confirmed Conditions, or null if null was passed in
 */
define function Confirmed(CondList List<Condition>):
  CondList C where IsEncounterDiagnosis(C) xor C.verificationStatus ~ C3F."Condition Confirmed code"

/**
 * Conditions that are active. In FHIR R4, this is reflected by clinicalStatus: 'active' and the absence of any
 * abatement information (i.e., if it abated, it is no longer active).
 * TODO: Rename to Active once the execution engine supports overloaded functions.
 * @see http://hl7.org/fhir/R4/valueset-condition-clinical.html
 * @param CondList - a list of Conditions
 * @returns {List<Condition>} a list of active Conditions, or null if null was passed in
 */
define function ActiveCondition(CondList List<Condition>):
  CondList C
    where (IsEncounterDiagnosis(C) xor C.clinicalStatus ~ C3F."Condition Active code")
      and C.abatement is null

/**
 * Conditions that are active or recurring. In FHIR R4, this is reflected by clinicalStatus: 'active', 'recurrence', or
 * 'relapse'.  We do not check for null abatement information because it may have dates from when the now recurring
 * condition initially went into remission.
 * @see http://hl7.org/fhir/R4/valueset-condition-clinical.html
 * @param CondList - a list of Conditions
 * @returns {List<Condition>} a list of active or recurring Conditions, or null if null was passed in
 */
define function ActiveOrRecurring(CondList List<Condition>):
  CondList C
    where IsEncounterDiagnosis(C)
      xor (C.clinicalStatus ~ C3F."Condition Active code"
        or C.clinicalStatus ~ C3F."Condition Recurrence code"
        or C.clinicalStatus ~ C3F."Condition Relapse code")

// ## Re-usable functions ##

// The summary logic contains many constructs that are needed throughout the logic. Where possible, these constructs
// have been developed as re-usable functions that can be invoked wherever they are needed.

define function AgeToQuantity(age FHIR.Age):
  if age is null then
    null as System.Quantity
  else
    FHIRHelpers.ToQuantity(age)

define function QuantityToQuantity(quantity FHIR.Quantity):
  if quantity is null then
    null as System.Quantity
  else
    FHIRHelpers.ToQuantity(quantity)

// Returns a text representation of a date using the CQL `ToString` function.
// @param d - a FHIR date to get text for
// @returns {System.String} the text representation of the date
define function DateText(d FHIR.date):
  ToString(d.value)

// Returns a text representation of a dateTime using the CQL `ToString` function.
// @param d - a FHIR dateTime to get text for
// @returns {System.String} the text representation of the dateTime
define function DateTimeText(d FHIR.dateTime):
  ToString(d.value)

// Returns a text representation of an instant using the CQL `ToString` function.
// @param i - a FHIR instant to get text for
// @returns {System.String} the text representation of the instant
define function InstantText(i FHIR.instant):
  ToString(i.value)

// Returns a text representation of a Quantity with the Quantity's value and unit.
// If the unit is {score}, then omit it (as it is not useful to display)
// @param q - a FHIR Quantity to get text for
// @returns {System.String} the text representation of the Quantity
define function QuantityText(q FHIR.Quantity):
  if (q is null) then null
  else if (q.unit is not null and q.unit.value != '{score}') then ToString(q.value.value) + ' ' + q.unit.value
  else if (q.code is not null and q.code.value != '{score}') then ToString(q.value.value) + ' ' + q.code.value
  else ToString(q.value.value)

// Returns a text representation of an MME Quantity with the Quantity's value and unit in as a user-friendly display.
// If the unit is {MME}/d, display it as MME/Day, otherwise, just return the ToString of the given quantity.
// @param quantity - MME as a System Quantity to get text for
// @returns {System.String} a user-friendly text representation of the MME
define function MMEText(quantity System.Quantity):
  if quantity.unit = '{MME}/d' then
    ToString(quantity.value) + ' MME/Day'
  else
    ToString(quantity)

// Returns a tuple containing a Period's start and end as text representations.
// @param p - a FHIR Period to get a tuple for
// @returns {Tuple<Start System.String, End System.String>} the tuple representation of the Period
define function PeriodObject(p FHIR.Period):
  if p is null then null
  else
    {
      Start: DateTimeText(p."start"),
      End: DateTimeText(p."end")
    }

// Returns a tuple containing a Range's low and high as text representations.
// @param r - a FHIR Range to get a tuple for
// @returns {Tuple<Low System.String, High System.String>} the tuple representation of the Range
define function RangeObject(r FHIR.Range):
  if r is null then null
  else
    {
      Low: QuantityText(r.low),
      High: QuantityText(r.high)
    }

// Returns a text representation of a date associated with an Observation, preferring `effectiveDateTime`, then
// `effectivePeriod.start`, then `issued`.
// @param o - a FHIR Observation to get the text date from
// @returns {System.String} the text representation of a relevant date from the Observation
define function ObservationDate(o FHIR.Observation):
  Coalesce(
    DateTimeText(o.effective as FHIR.dateTime),
    InstantText(o.effective as FHIR.instant),
    DateTimeText((o.effective as FHIR.Period)."start"),
    InstantText(o.issued)
  )

// Returns a text representation of a date associated with a MedicationStatement, preferring `effectiveDateTime`, then
// `.start`.
// @param s - a FHIR MedicationStatement to get the text date from
// @returns {System.String} the text representation of a relevant date from the MedicationStatement
define function MedicationStatementDate(s FHIR.MedicationStatement):
  Coalesce(
    DateTimeText(s.effective as FHIR.dateTime),
    DateTimeText((s.effective as FHIR.Period)."start"),
    DateTimeText(s.dateAsserted)
  )

// Returns a text representation of a Condition's onset, whether represented as a dateTime, Period, Quantity (Age),
// Range (Age), or string.
// @param c - a FHIR Condition to get the text representation of the onset from
// @returns {System.String} the text representation of the Condition's onset
define function Onset(c FHIR.Condition):
  Coalesce({
    DateTimeText(c.onset as FHIR.dateTime),
    QuantityText(c.onset as FHIR.Age),
    PeriodObject(c.onset as FHIR.Period),
    RangeObject(c.onset as FHIR.Range),
    (c.onset as FHIR.string).value
  })

// Returns the date of a Condition's onset, whether represented as a dateTime, Period, Quantity (Age),
// Range (Age), or the recordedDate if no onset is available
// @param c - a FHIR Condition to get the text representation of the onset from
// @returns {System.DateTime} the date of the Condition's onset or when it was recorded
define function OnsetOrRecordedDate(c FHIR.Condition):
  Coalesce(
    (c.onset as FHIR.dateTime).value,
    //Patient.birthDate + AgeToQuantity(c.onset),
    (c.onset as FHIR.Period)."start".value,
    //Patient.birthDate + QuantityToQuantity((c.onset as FHIR.Range)."low"),
    c.recordedDate.value
  )

// Returns a text representation of a Condition's abatement, whether represented as a dateTime, Period, Quantity (Age),
// Range (Age), string, or boolean.
// @param c - a FHIR Condition to get the text representation of the abatement from
// @returns {System.String} the text representation of the Condition's abatement
define function Abatement(c FHIR.Condition):
  Coalesce({
    DateTimeText(c.abatement as FHIR.dateTime),
    QuantityText(c.abatement as FHIR.Age),
    PeriodObject(c.abatement as FHIR.Period),
    RangeObject(c.abatement as FHIR.Range),
    (c.abatement as FHIR.string).value
  })
