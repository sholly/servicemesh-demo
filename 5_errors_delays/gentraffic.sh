#!/bin/sh
for i in {1..10};
do
	curl http://istio-ingressgateway-istio-system.apps.ocp4.lab.unixnerd.org/leaf1
	echo
done
