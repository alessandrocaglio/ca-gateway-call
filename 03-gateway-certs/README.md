# Create Custom certificates for Istio Gateway 

```
export DOMAIN_NAME=apps.cluster-wj7ht.wj7ht.sandbox1785.opentlc.com
export APP_NAME=cp
export ISTIO_SYSTEM_NS=ossm-istio-system

openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=$DOMAIN_NAME Inc./CN=$DOMAIN_NAME' -keyout $DOMAIN_NAME.key -out $DOMAIN_NAME.crt
openssl req -out $APP_NAME.$DOMAIN_NAME.csr -newkey rsa:2048 -nodes -keyout $APP_NAME.$DOMAIN_NAME.key -subj "/CN=$APP_NAME.$DOMAIN_NAME/O=$APP_NAME from $DOMAIN_NAME"
openssl x509 -req -days 365 -CA $DOMAIN_NAME.crt -CAkey $DOMAIN_NAME.key -set_serial 0 -in $APP_NAME.$DOMAIN_NAME.csr -out $APP_NAME.$DOMAIN_NAME.crt

oc create secret tls $APP_NAME-certs -n $ISTIO_SYSTEM_NS --key $APP_NAME.$DOMAIN_NAME.key --cert $APP_NAME.$DOMAIN_NAME.crt -o yaml --dry-run=client >$APP_NAME-certs.yaml
```