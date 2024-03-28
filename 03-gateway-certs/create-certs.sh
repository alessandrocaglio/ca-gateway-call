#!/bin/sh

if [ -z "${DOMAIN_NAME}" ]; then
  echo "DOMAIN_NAME env variable not set"
  exit 1
fi

if [ -z "${APP_NAME}" ]; then
  echo "DOMAIN_NAME env variable not set"
  exit 1
fi

if [ -z "${ISTIO_SYSTEM_NS}" ]; then
  echo "DOMAIN_NAME env variable not set"
  exit 1
fi

echo "DOMAIN_NAME: $DOMAIN_NAME"
echo "APP_NAME: $DOMAIN_NAME"
echo "ISTIO_SYSTEM_NS: $DOMAIN_NAME"

openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=$DOMAIN_NAME Inc./CN=$DOMAIN_NAME' -keyout $DOMAIN_NAME.key -out $DOMAIN_NAME.crt
openssl req -out $APP_NAME.$DOMAIN_NAME.csr -newkey rsa:2048 -nodes -keyout $APP_NAME.$DOMAIN_NAME.key -subj "/CN=$APP_NAME.$DOMAIN_NAME/O=$APP_NAME from $DOMAIN_NAME"
openssl x509 -req -days 365 -CA $DOMAIN_NAME.crt -CAkey $DOMAIN_NAME.key -set_serial 0 -in $APP_NAME.$DOMAIN_NAME.csr -out $APP_NAME.$DOMAIN_NAME.crt

oc create secret tls $APP_NAME-certs -n $ISTIO_SYSTEM_NS --key $APP_NAME.$DOMAIN_NAME.key --cert $APP_NAME.$DOMAIN_NAME.crt -o yaml --dry-run=client >$APP_NAME-certs.yaml

echo "Created $APP_NAME-certs.yaml with self-signed custom cert for $APP_NAME.$DOMAIN_NAME"