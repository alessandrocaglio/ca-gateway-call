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

oc login -u $USER -p $PASSWORD $API_URL
```

### Create a Demo control plane
```
oc new-project ossm-demo

oc apply -f 01-controlplane/01-controlplane.yaml
oc apply -f 01-controlplane/02-memberroll.yaml
```

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
oc create ns ossm-demo-hello-1 --labels=servicemesh=ossm-demo
oc project ossm-demo-hello-1
oc apply -n ossm-demo-hello-1 -f 10-hello-app/01-hello.yaml
APP_INSTANCE=1 cat 10-hello-app/02-virtual-service.yaml | envsubst | less
APP_INSTANCE=1 cat 10-hello-app/02-virtual-service.yaml | envsubst | oc apply -n ossm-demo-hello-$APP_INSTANCE -f-

oc create ns ossm-demo-hello-2 --labels=servicemesh=ossm-demo
oc project ossm-demo-hello-2
oc apply -n ossm-demo-hello-2 -f 10-hello-app/01-hello.yaml
APP_INSTANCE=2 cat 10-hello-app/02-virtual-service.yaml | envsubst | oc apply -n ossm-demo-hello-$APP_INSTANCE -f-

oc create ns ossm-demo-hello-3 --labels=servicemesh=ossm-demo
oc project ossm-demo-hello-3
oc apply -n ossm-demo-hello-3 -f 10-hello-app/01-hello.yaml
APP_INSTANCE=3 cat 10-hello-app/02-virtual-service.yaml | envsubst | oc apply -n ossm-demo-hello-$APP_INSTANCE -f-
```

### Test it
```
curl -iks https://$APP_NAME.$DOMAIN/hello-1/hello
curl -iks https://$APP_NAME.$DOMAIN/hello-2/hello
curl -iks https://$APP_NAME.$DOMAIN/hello-3/hello
```
