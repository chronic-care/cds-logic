#!/bin/bash

# PUT a specifiec list of new or updated resources to a FHIR endpoint
# . load-all.sh https://api-v8-r4.hspconsortium.org/CarePlanningR4/open

. ../put-resource.sh $1 Library library-fhir-helpers library-fhir-helpers
. ../put-resource.sh $1 Library library-commons library-commons
. ../put-resource.sh $1 Library library-cbp library-cbp
. ../put-resource.sh $1 Library library-goal-management library-goal-management

. ../put-resource.sh $1 PlanDefinition goal-management goal-management
