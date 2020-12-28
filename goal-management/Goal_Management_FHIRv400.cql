// # Introduction

// The Goal Management logic library supports decision-making on achievement of health goals.

library Goal_Management_FHIRv400 version '1.0.0'

// # Data model #

using FHIR version '4.0.0'

// # Referenced libraries #

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



// ## Individual codes ##

// list individual codes from code systems used directly in the CQL logic. Individual codes are used when there is
// a single code from a particular vocabulary standard used to represent a clinical concept. It is considered
// best-practice not to create value sets containing a single code.

code "Body weight code": '29463-7' from "LOINC" display 'Body weight'
code "Body height code": '8302-2' from "LOINC" display 'Body height'
code "Blood pressure code": '55284-4' from "LOINC" display 'Blood pressure systolic and diastolic'


// # CDS logic #

context Patient

// ## Re-usable functions ##

// The summary logic contains many constructs that are needed throughout the logic. Where possible, these constructs
// have been developed as re-usable functions that can be invoked wherever they are needed.

// Returns the first-found display text for a CodeableConcept, looking first at the `text` attribute, then the
// `display` on each `coding` until it finds a non-null value.
// @param c - a FHIR CodeableConcept to get text from
// @returns {System.String} the display text or null if none is found

define function ConceptText(c FHIR.CodeableConcept):
  Coalesce(c.text.value, Coalesce((c.coding) c2 return c2.display.value))

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
  else if (q.comparator is not null) then q.comparator.value + ' ' + ToString(q.value.value) + ' ' + q.unit.value
  else if (q.unit is not null and q.unit.value != '{score}') then ToString(q.value.value) + ' ' + q.unit.value
  else if (q.code is not null and q.code.value != '{score}') then ToString(q.value.value) + ' ' + q.code.value
  else ToString(q.value.value)

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

// Returns a text representation of a Condition's onset, whether represented as a dateTime, Period, Quantity (Age),
// Range (Age), or string.
// @param c - a FHIR Condition to get the text representation of the onset from
// @returns {System.String} the text representation of the Condition's onset
define function Onset(c FHIR.Condition):
  Coalesce( List{
    DateTimeText(c.onset as FHIR.dateTime),
    QuantityText(c.onset as FHIR.Age),
    PeriodObject(c.onset as FHIR.Period),
    RangeObject(c.onset as FHIR.Range),
    (c.onset as FHIR.string).value
  })

// Goal Management logic

define BodyWeightObservations:
  C3F.Verified(C3F.ObservationLookBack([Observation: "Body weight code"], 52 weeks))

define MostRecentBodyWeight:
  C3F.MostRecent(BodyWeightObservations)

define "Last Body Weight Quantity":
  "MostRecentBodyWeight" Result
    return ToQuantity(Result.value as Quantity)

define BodyHeightObservations:
  C3F.Verified(C3F.ObservationLookBack([Observation: "Body height code"], 52 weeks))

define MostRecentBodyHeight:
  C3F.MostRecent(BodyHeightObservations)

define "Last Body Height Quantity":
  "MostRecentBodyHeight" Result
    return ToQuantity(Result.value as Quantity)

define "Needs Body Weight or Height":
	MostRecentBodyWeight is null or MostRecentBodyHeight is null

define "Weight Metric":
  "Last Body Weight Quantity" qty
		return ToMetric(qty)

define "Height Metric":
  "Last Body Height Quantity" qty
		return ToMetric(qty)

define "BMI":
	System.Quantity { value: "Weight Metric".value / "Height Metric".value ^ 2, unit: 'kg/m2' }

define "Is Overweight or Obese":
	"Is Overweight" or "Is Obese"

define "Is Overweight":
	"BMI".value >= 25

define "Is Obese":
	"BMI".value >= 30

// CDS Hook dynamic values

define NeedsWeightHeightTitle: 'Missing Weight or Height'

define NeedsWeightHeightDetail: 'Please enter current body weight and height.'

define NeedsWeightHeightSeverity: 'info'

define OverweightSeverity: if "Is Obese" then 'warning' else 'info'

define OverweightTitle: 'Patient BMI'

define OverweightDetail:
	"BMI" bmi
		return if "Is Overweight or Obese" then 'Your BMI of ' + ToString(Round(bmi.value)) + ' indicates that you are overweight, time to get back on track with exercise and diet!'
			else 'Congratulations, your weight is normal!'

// Conversion functions

define function ToQuantity(quantity FHIR.Quantity):
	System.Quantity {
    	value: quantity.value.value,
      	unit: quantity.unit.value
    }

define function ToMetric(qty System.Quantity):
	case when qty.unit = 'lb' then
		System.Quantity { value: qty.value * 0.454, unit: 'kg' }
	when qty.unit = 'in' then
		System.Quantity { value: qty.value * 0.0254, unit: 'm' }
	else
		qty
	end
