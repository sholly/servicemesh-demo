#!/bin/sh

for i in `seq 1 50`:
do
	 curl http://istio-ingressgateway-istio-system.apps.ocp4.lab.unixnerd.org/leaf1
	 echo ""
 done
