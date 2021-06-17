#!/bin/sh 
while :
do
        oc get pods -o name |  xargs -L 1 oc logs --tail 1 -c leaf1
	sleep 1
done
