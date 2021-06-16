Service Mesh Demo
## Basic Demo

create project servicemesh-basicdeploy

oc create -f 1_basicdeploy/deployment

jaeger tracing not working

open kiali 

run gentraffic12 to see flow conductor -> leaf1 -> leaf2
run gentraffic21 to see flow conductor -> leaf2 -> leaf1

## Routing Traffic based on Headers

oc new-project servicemesh-headers

oc create -f 2_routing_headers/deployment

run gentraffic.sh to see traffic split between services


Now we split into subsets, v10 and v11
Apply the 2_routing_headers/deployment/destination-rule.yaml 

Route all traffic to v10. 
Apply virtual-service-subset-v10.yaml

Note how all traffic is routed to v10 of the service.

Now apply virtual-service-with-header-subsets.yaml

run curl-no-headers.sh, this gives us v11
run curl-with-headers, this will give us v10

