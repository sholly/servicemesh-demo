# Service Mesh Demo

This is a demo of most of the major features of Openshift Service Mesh.  
We use several different microservices to explore the features of service mesh: 

1.  https://github.com/sholly/servicemesh-conductor
2.  https://github.com/sholly/servicemesh-leaf1
3.  https://github.com/sholly/servicemesh-leaf2
4.  https://github.com/sholly/vertx-greet

Conductor acts as an extremely simple API gateway.  It has endpoints to call itself only, 

'/callleaf12' to call conductor -> leaf1 -> leaf2

and 
'/callleaf21' to call conductor -> leaf2 -> leaf1

Leaf1 and leaf2 are similar in that they have standalone endpoints, as well as endpoints for calling each other, to 
simulate traffice flow. 

It is advised to create a separate project for each section and add it to the Service mesh Member Roll.

When done with a section, delete the project, then delete that project from the Service Mesh Member Roll.

Adding projects to the Service Mesh Member Roll: 

In the openshift console, select the project where Service Mesh is installed.  This should be 'istio-system' unless it 
was installed elsewhere. Then select 'Operators -> Installed Operators'.  Click on Red Hat Openshift Service Mesh.
Click on Service Mesh Member Roll, then click on the instance. Edit the instance yaml, it should look similar to this: 

```yaml
spec:
  members:
    - servicemesh-argocd-demo
```
## 1: Basic Demo

This is a basic Service Mesh deployment.   
create the project servicemesh-basicdeploy, then add the 'servicemesh-basicdeploy' project to the Service Mesh Member Roll. 


`oc create -f 1_basicdeploy/deployment`

Open the kiali route so we can monitor the traffic.  In the 'istio-system' project in the web console, navigate to 
Networking -> Routes, then find and click on the Kiali URL.   

When the pods are ready:

Run gentraffic12.sh  to see traffic flow conductor to leaf1 to leaf2. 
Run gentraffic21 to see flow from conductor to leaf2 to leaf1.


## 2: Routing Traffic based on Headers


Create the project 'servicemesh-headers', and add it to the Service Mesh Member Roll

Create the initial deployment from 2_routing_headers/deployment/application.yaml

`oc create -f 2_routing_headers/deployment/application.yaml`

Then create the destionationRule: 
`oc create -f 2_routing_headers/deployment/destination-rule.yaml`

Run ./gentraffic.sh, and the traffic should be split between v10 and v11 of the service. 

Now apply virtual-service-with-header-subsets.yaml. 
`oc apply -f 2_routing_headers/deployment/virtual-service-with-header-subsets.yaml`

This will route traffic based on whether we see a header.  

Run 'curl-with-header.sh'.  This sets the 'end-user:redhat' header, and routes traffic to v10
Running 'curl-without-header' will route all traffic to v11. 

## 3: Canary releases with Service Mesh

Create project servicemesh-canaryrelease and add it to the Service mesh member roll.

`oc apply -f application.yaml`

`oc apply -f destination-rule-v10v11v12.yaml`

Run gentraffic.sh. We have v11, v12, v13 versions defined, we should see an even split between v10, v11, and v12. 

Now lets perform our 'canary release'. 

Apply virtualservice-v10-80-v11-20.yaml.  This will route 80% of the traffic to v10, and 20% to v12. 

Run gentraffic again to see the updated traffic. 


Apply virtualservice-v10-45-v11-45-v12-10.yaml.  This does 45% -> v10, 45% -> v11, and 10% -> v12.  

run gentraffic again, observe the traffic split.  


## 4: Mirror releases

Create project and app

`oc new-project servicemesh-mirror`

`oc apply -f deployments/application.yaml`

When app is deployed, 
run ./gentraffic.sh in on terminal window. 

run ./watchlogs.sh  in another terminal window. 


Note how traffic is going to v10 only

now apply destination rule and virtual service

```shell
oc apply -f deployment/destination-rule-v10-v11.yaml 
oc apply -f deployment/virtualservice-mirror.yaml
```

Keep watching both terminals.  Note carefully how even though we only v10 responding to traffic, it is in reality also mirroring
the traffic to v11 as well!

## 5: Errors and Delays

Create a project, add it to the Service Mesh Member Roll, and create the application:

`oc new-project servicemesh-errorsdelays`

`oc apply -f deployment/application.yaml`

Run ./gentraffic.sh to see normal traffic.

Now update the VirtualService to inject faults:

`oc replace -f deployment/virtualservice-error.yaml`

Run ./gentraffic.sh, note that ~50% of the calls will fail. 

Update the VirtualService to inject delays:

`oc replace -f deployment/virtualservice-delay.yaml`

Now, ~40% of the calls will be delayed by ~800ms.


### Timeouts
create the servicemesh-resilience project, add it to the Service Mesh member roll, and deploy the application. 
`oc apply -f deployment-timeout/application.yaml`

Run response-times.sh, observe the normal traffic flow

Now, let's set a 2 second delay on leaf2:

`oc apply -f deployment-timeout/vs-leaf2-delay.yaml`

run the response-times.sh, note we've introduced approximately a 2 second delay

Set timeout on leaf1.  The timeout is less than the delay in leaf2, so the call should fail. 
`oc apply -f deployment/vs-timeout-leaf1.yaml`

Run response-times.sh note the call failure
remove timeout 
`oc apply -f deployment/vs-removedelay-leaf1.yaml`

Run response-times.sh again.  

### Retries

## 7. Circuit Breaker

Create the project servicemesh-circuitbreak, add to the Service Mesh Member Roll, and deploy the application. 

`oc apply -f deployment/application.yaml`

This is the vertx-greet svc, which will only allow 2 connections per second.  

run the parallel.sh script , note how we receive a 503 error after 1-2 calls.  

Add a connection pool to reduce connections allowed to service. 

`oc apply -f deployment/dr-connection-pool.yaml`

Run parallel again, note the upstream connection errors. 

Create v2 deployment, which does not have connection limits, and has a message denoting that it is v2. 

`oc create -f deployment/deployment-v2.yaml`

run parallel again, verify the v2 pod is accepting traffic. 


Reconfigure the destination rule as a circuit breaker: 
`oc apply -f deployment/dr-outlier-detection.yaml`

Now run sequential, and verify that v1 is evicted, while v2 still accepts traffic.  

Wait ten seconds, and run ./sequential.sh again.  Note that v1 is allowed to accept traffic again, if only for a short 
period. 

## 8. Security - mTLS

For this demo, you will need the istioctl client.  My cluster is using Service mesh 2.0, which uses Istio 1.6.  Make
sure to download istioctl v1.6.  


Create the project  servicemesh-mtls, and add it to Service Mesh Member Roll. 


Deploy the conductor, leaf1, leaf2 applications.

`oc apply -f deployment/application.yaml`

Before applying the PeerAuthentication and DestinationRule, check that the mTLS policy is set to PERMISSIVE.  Note that 
in Service mesh 2.0, istioctl does not give us pod names that have mTLS policy attached. 

`istioctl x authz check $CONDUCTOR_POD_NAME`

Apply the PeerAuthentication security policy:
`oc apply -f peerauthentication.yaml`


Apply the destinationRule applying TLS:
`oc apply -f destinationrule.yaml`

Create service accounts for the apps, and attach them to the deployments: 
```shell
oc create serviceaccount conductor
oc create serviceaccount leaf1
oc create serviceaccount leaf2
oc set serviceaccount deployment conductor conductor
oc set serviceaccount deployment leaf1 leaf1
oc set serviceaccount deployment leaf2 leaf2
```
or run ./create_serviceaccounts.sh


Check the status of TLS on the pods: 

`istioctl x authz check $CONDUCTOR_POD_NAME`

We should now see 'STRICT' mTLS policy applied. 

##9 Service to Service Authorization

Create two projects: 
servicemesh-authc
servicemesh-curl

Add both projects to the Service Mesh Member Roll. 

Create application:
The 9_RBAC/application.yaml includes a destination rule and peerauthentication to apply strict mTLS. 
`
oc apply -f deployments/application.yaml`

switch to the servicemesh-curl project.. 

oc apply -f deployments/sleep.yml

Now, check that we can talk to the conductor pod across namespaces: 

Run `oc exec $(oc get pods -o name -n servicemesh-curl) -- curl -s conductor.servicemesh-authc.svc.cluster.local:8080/callleaf12`

We should see a successful call to the conductor application. 

Apply conductor-policy.yaml. 
`oc apply -f deployment/conductor-policy.yaml`

After 20-40 seconds, this should restrict traffic to the conductor application to ONLY the istio-ingressgateway.  

Run `oc exec $(oc get pods -o name -n servicemesh-curl) -- curl -s conductor.servicemesh-authc.svc.cluster.local:8080/callleaf12`
We should now get access denied.  


Apply the curl conductor policy, allowing access from the 'servicemesh-curl' namespace. 
WAIT 20-30 seconds before checking access again: 

oc exec $(oc get pods -o name -n servicemesh-sleep) -- curl -s conductor.servicemesh-authc.svc.cluster.local:8080/callleaf12

We should now be allowed to call conductor from the servicemesh-curl namespace again. 