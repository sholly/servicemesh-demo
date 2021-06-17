#!/bin/sh

while :
do

	curl http://istio-ingressgateway-istio-system.apps.ocp4.lab.unixnerd.org/leaf1
	echo
	sleep 1
done
