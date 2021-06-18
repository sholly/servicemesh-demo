Service Mesh Demo
## 1: Basic Demo

create project servicemesh-basicdeploy

oc create -f 1_basicdeploy/deployment

jaeger tracing not working

open kiali 

run gentraffic12 to see flow conductor -> leaf1 -> leaf2
run gentraffic21 to see flow conductor -> leaf2 -> leaf1

## 2: Routing Traffic based on Headers

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

## 3: Canary releases with Service Mesh

Create project servicemesh-canaryrelease

`oc apply -f application.yaml`

`oc apply -f destination-rule-v10v11.yaml`

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

## 4: Mirror releases

Create project and app

`oc new-project servicemesh-mirror`

`oc apply -f deployments/application.yaml`

When app is deployed, 
run ./gentraffic in on term
run ./watchlogs in other


Note how traffic is going to v10 only

now apply destination rule and virtual service

```shell
oc apply -f deployment/destination-rule-v10-v11.yaml 
oc apply -f deployment/virtualservice-mirror.yaml
```

Keep watching 

## 5: Errors and Delays

Create a project and application:

`oc new-project servicemesh-errorsdelays`

`oc apply -f deployment/application.yaml`

Run ./gentraffic.sh to see normal traffic.

Now edit the VirtualService to inject faults:

`oc replace -f deployment/virtualservice-error.yaml`

Run ./gentraffic.sh, note that ~50% of the calls will fail. 

Edit the VirtualService to inject delays:

`oc replace -f deployment/virtualservice-delay.yaml`

Now, ~40% of the calls will be delayed by ~800ms.

## 6. Resilience

### Timeouts
create servicemesh-resilience project

add to servicemesh

deploy application 
`oc apply -f deployment-timeout/application.yaml`

run response-times.sh, observe normal flow

Set 2s delay on leaf2

`oc apply -f deployment-timeout/vs-leaf2-delay.yaml`

run response-times.sh, observe 2s delay

Set timeout on leaf1, rerun response-times, observe the error
`oc apply -f deployment/vs-timeout-leaf1.yaml`

remove timeout 
`oc apply -f deployment/vs-removedelay-leaf1.yaml`

### Retries

Update the application such that leaf2 times out with 500's 90% of the time: 
`oc apply -f deployment-retry/application.yaml`

## 7. Circuit Breaker

create project servicemesh-circuitbreak

oc apply -f deployment/application.yaml

This is the vertx-greet svc, which will only allow 2 connections per second.  

run parallel script , note how we receive 503 after 1-2 calls.  

Add a connection pool to reduce connections allowed to service. 

`oc apply -f deployment/dr-connection-pool.yaml`

Run parallel again, note upstream connection errors. 

Create v2 deployment, which does not have connection limits.

`oc create -f deployment/deployment-v2.yaml`

run parallel again, verify v2 pod. 


Reconfigure the destination rule as a circuit breaker: 
`oc apply -f deployment/dr-outlier-detection.yaml`

Now run sequential, verify that v1 drops out. 


