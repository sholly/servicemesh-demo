#!/bin/sh

while: 
do
   curl -H "end-user: redhat" http://istio-ingressgateway-istio-system.apps.ocp4.lab.unixnerd.org/leaf1
   sleep 1
done
