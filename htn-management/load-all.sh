#!/bin/bash

# PUT a specifiec list of new or updated resources to a FHIR endpoint
# . load-all.sh https://api-v8-r4.hspconsortium.org/CarePlanningR4/open

. ./put-resource.sh $1 Library library-fhir-helpers library-fhir-helpers
. ./put-resource.sh $1 Library library-commons library-commons
. ./put-resource.sh $1 Library library-cbp library-cbp
. ./put-resource.sh $1 Library library-htn-management library-htn-management

. ./put-resource.sh $1 PlanDefinition htn-management htn-management
. ./put-resource.sh $1 ActivityDefinition activitydefinition-htn-diagnosis activitydefinition-htn-diagnosis
. ./put-resource.sh $1 ActivityDefinition activitydefinition-htn-medication activitydefinition-htn-medication

. ./put-resource.sh $1 ValueSet 2.16.840.1.113883.3.464.1003.104.12.1016 valueset-2.16.840.1.113883.3.464.1003.104.12.1016
. ./put-resource.sh $1 ValueSet 2.16.840.1.113883.3.526.2.39 valueset-2.16.840.1.113883.3.526.2.39
