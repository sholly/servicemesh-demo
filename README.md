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

## Canary releases with Service Mesh

Create project servicemesh-canaryrelease

apply the application.yaml

apply the destination-rule-v10v11.yaml

Run gentraffic. We have v11, v12, v13 versions defined, but destination-rule-v10v11.yaml only routes 
traffic to v11 and v12

Now lets perform our 'canary release'.   

Apply virtualservice-v10-80-v11-20.yaml

run gentraffic again.  It is hard to see, but approximately 80% traffic goes to v11, and 20% goes to v12.

Now lets route traffic to v12 as well.  

Apply destination-rule-v10v11v12.yaml.

Apply virtualservice-v10-45-v11-45-v12-10.yaml.

run gentraffic again. 

Now we should have 45% v11, 45% v12, and 10% v3

Let's say there is a problem with both v11 and v12, 

`oc edit vs/leaf1-vs`

Change the routing to 100% v11.

Run gentraffic again, note that 100% of traffic is going to v11 now. 
