#!/bin/bash

# PUT a new or updated resource to a FHIR endpoint

# arg1 = server endpoint URL
# arg2 = resource type
# arg3 = resource id
# arg4 = file name (without .json suffix)

# . put-resource.sh https://api-v8-r4.hspconsortium.org/CarePlanningR4/open PlanDefinition cc-cpg-plan-ckd plandefinition-ckd-risk-screening

echo
curl $1/$2/$3 -H 'Content-type: application/fhir+json' -H 'Accept: application/fhir+json' --upload-file $4.json
