#! /bin/sh
# Utility script for executing the same command in multiple parallel threads.

THREADS=${2:-20}

echo
for i in $(seq 1 $THREADS); do 
    eval "curl -w \"%{http_code}\n\" http://istio-ingressgateway-istio-system.apps.ocp4.lab.unixnerd.org/" &
done; 
wait
