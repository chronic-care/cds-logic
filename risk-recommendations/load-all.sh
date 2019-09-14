#!/bin/bash

# PUT a specifiec list of new or updated resources to a FHIR endpoint
# . load-all.sh https://api-v8-r4.hspconsortium.org/CarePlanningR4/open

. ./put-resource.sh $1 Library ckd-risk-recommendations library-ckd-risk-recommendations
. ./put-resource.sh $1 PlanDefinition ckd-risk-screening plandefinition-ckd-risk-screening

. ./put-resource.sh $1 ActivityDefinition ckd-risk-referral-nephrology activitydefinition-ckd-risk-referral-nephrology
. ./put-resource.sh $1 ActivityDefinition ckd-risk-renal-lab-order activitydefinition-ckd-risk-renal-lab-order

. ./put-resource.sh $1 ValueSet ckd-valueset-creatinine valueset-ckd-valueset-creatinine
. ./put-resource.sh $1 ValueSet ckd-valueset-egfr valueset-ckd-valueset-egfr
. ./put-resource.sh $1 ValueSet ckd-valueset-uacr valueset-ckd-valueset-uacr

. ../load-bundle.sh $1 bundle-ckd-valuesets-expanded.json
