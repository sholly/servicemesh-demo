#! /bin/sh
COMMAND="$1"
SLEEP="${2:-3}"

while :; do 
    curl -w "%{http_code}\n" http://istio-ingressgateway-istio-system.apps.ocp4.lab.unixnerd.org
    sleep 0.$((RANDOM % 3))
done
