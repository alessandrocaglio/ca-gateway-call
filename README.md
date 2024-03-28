# Gateway example

## Prerequisite
* Service Mesh Operators installed (jaeger, kiali, servicemesh)
* oc command line tool
* OCP cluster
* User with cluster-admin rights

## Instructions
Clone this repo

Edit the env.sample file and rename it as .env

### Login to OCP
```
source ./.env

oc login -u $OCP_USER -p $OCP_PASSWORD $OCP_API_URL
```
or
```
oc login --token=$OCP_TOKEN --server=$OCP_API_URL
```

### Create a Demo control plane
```
oc new-project ossm-demo

oc apply -f 01-controlplane/01-controlplane.yaml
oc apply -f 01-controlplane/02-memberroll.yaml
```

Wait for all the pods to be up and running

Kiali URL: https://kiali-ossm-demo.$DOMAIN_NAME/

### Create custom TLS certs for the custom gateway
Create a custom self-signed certificate for the ingress gateway. Cd into the `03-gateway-certs` directory (ensure you have set the correct env variables)
```
cd 03-gateway-certs
./create-certs.sh
```

Create the TLS secret in the control plane namespace
```
oc apply -f ./$APP_NAME-certs.yaml -n ossm-demo
```

Go back to the repo root dir
```
cd ..
```

### Create a custom gateway (and route) in the control plane
Examine the files and ensure the variable substitution worked

```
cat 04-gateway/01-gateway-route.yaml | envsubst | less
```

Create the gateway and the route
```
cat 04-gateway/01-gateway-route.yaml | envsubst | oc apply -f-
```

### Deploy 3 instances of an example application
```
export APP_INSTANCE=1
oc create ns ossm-demo-hello-$APP_INSTANCE
oc label ns ossm-demo-hello-$APP_INSTANCE servicemesh=ossm-demo
oc project ossm-demo-hello-$APP_INSTANCE
oc apply -n ossm-demo-hello-$APP_INSTANCE -f 10-hello-app/01-hello.yaml
cat 10-hello-app/02-virtual-service.yaml | envsubst | less
cat 10-hello-app/02-virtual-service.yaml | envsubst | oc apply -n ossm-demo-hello-$APP_INSTANCE -f-
```

Wait for the pod to start and test it and look at Kiali
```
curl -iks https://$APP_NAME.$DOMAIN_NAME/hello-$APP_INSTANCE/hello
```

Deploy another instance on a separate namespace
```
export APP_INSTANCE=2
oc create ns ossm-demo-hello-$APP_INSTANCE
oc label ns ossm-demo-hello-$APP_INSTANCE servicemesh=ossm-demo
oc project ossm-demo-hello-$APP_INSTANCE
oc apply -n ossm-demo-hello-$APP_INSTANCE -f 10-hello-app/01-hello.yaml
cat 10-hello-app/02-virtual-service.yaml | envsubst | oc apply -n ossm-demo-hello-$APP_INSTANCE -f-
```

Wait for the pod to start and test it and look at Kiali
```
curl -iks https://$APP_NAME.$DOMAIN_NAME/hello-$APP_INSTANCE/hello
```

Deploy another instance on a separate namespace
```
export APP_INSTANCE=3
oc create ns ossm-demo-hello-$APP_INSTANCE
oc label ns ossm-demo-hello-$APP_INSTANCE servicemesh=ossm-demo
oc project ossm-demo-hello-$APP_INSTANCE
oc apply -n ossm-demo-hello-$APP_INSTANCE -f 10-hello-app/01-hello.yaml
cat 10-hello-app/02-virtual-service.yaml | envsubst | oc apply -n ossm-demo-hello-$APP_INSTANCE -f-
```

Wait for the pod to start and test it and look at Kiali
```
curl -iks https://$APP_NAME.$DOMAIN_NAME/hello-$APP_INSTANCE/hello
```

### Test all
```
curl -iks https://$APP_NAME.$DOMAIN_NAME/hello-1/hello
curl -iks https://$APP_NAME.$DOMAIN_NAME/hello-2/hello
curl -iks https://$APP_NAME.$DOMAIN_NAME/hello-3/hello
```

### Extra - Istio Policy
Example policy to deny all and open only to the gateway

Apply deny all policy
```
export APP_INSTANCE=3
oc apply -n ossm-demo-hello-$APP_INSTANCE -f 50-istio-policy/01-deny-all.yaml 
```

Test it
```
curl -iks https://$APP_NAME.$DOMAIN_NAME/hello-3/hello
```

Apply allow traffic from the gateway
```
export APP_INSTANCE=3
oc apply -n ossm-demo-hello-$APP_INSTANCE -f 50-istio-policy/02-allow-from-gw.yaml 
```

Test it again (this time it should work) 
```
curl -iks https://$APP_NAME.$DOMAIN_NAME/hello-3/hello
```

Test it from inside another container in another namespace
You shuold be allowed from hello-1 to call hello-2 but not hello-3
```
oc project ossm-demo-hello-1
POD_NAME=$(oc get pod -l app=hello -o jsonpath="{.items[0].metadata.name}")
oc rsh $POD_NAME curl http://hello.ossm-demo-hello-3.svc.cluster.local:8080/hello
oc rsh $POD_NAME curl http://hello.ossm-demo-hello-2.svc.cluster.local:8080/hello
```

## Clean up
Delete hello namespaces
```
oc delete ns ossm-demo-hello-3
oc delete ns ossm-demo-hello-2
oc delete ns ossm-demo-hello-1
```

Delete MemberRoll and ControlPlane
```
oc delete -n ossm-demo ServiceMeshMemberRoll default
oc delete -n ossm-demo ServiceMeshControlPlane ossm-demo-sm
```

Delete ControlPlane Namespace
```
oc delete ns ossm-demo
```






## Appendix
To install the Service Mesh operators have a look at `00-subscriptions` directory
