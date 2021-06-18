#!/bin/sh
oc create serviceaccount conductor
oc create serviceaccount leaf1
oc create serviceaccount leaf2
oc set serviceaccount deployment conductor conductor
oc set serviceaccount deployment leaf1 leaf1
oc set serviceaccount deployment leaf2 leaf2

