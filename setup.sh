#!/bin/bash

CLUSTER_NAME=ext

echo ======================
echo === Create Cluster ===
echo ======================

k3d cluster delete $CLUSTER_NAME
k3d cluster create --no-lb --update-default-kubeconfig=false --agents 2 --wait $CLUSTER_NAME
export KUBECONFIG=$(k3d kubeconfig write $CLUSTER_NAME)
kubectl cluster-info

echo ======================
echo === Download Istio ===
echo ======================
ISTIO_VERSION=1.6.8
if [ ! -d istio-$ISTIO_VERSION ]; then
  curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
fi
export PATH=$PWD/istio-$ISTIO_VERSION/bin:$PATH
istioctl operator init
kubectl create ns istio-system
kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: istocontrolplane
spec:
  profile: demo
  values:
    pilot:
      jwksResolverExtraRootCA: |
        -----BEGIN CERTIFICATE-----
        MIIC7TCCAdWgAwIBAgIBATANBgkqhkiG9w0BAQsFADAmMSQwIgYDVQQDDBtpbmdy
        ZXNzLW9wZXJhdG9yQDE2MDA0MzkxODMwHhcNMjAwOTE4MTQyNjIyWhcNMjIwOTE4
        MTQyNjIzWjAmMSQwIgYDVQQDDBtpbmdyZXNzLW9wZXJhdG9yQDE2MDA0MzkxODMw
        ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDjSWDynSYxJym0Qi/mM66B
        fDIY5cFoEEDiczLUqNlOgEdfjLrn8okTu9FiT350Pl7A078rOz7r2JxqVQVpVDDk
        L2M5fsGw1I4v27oLdQEU+KOdTascnheDDCPLv3l2tNacTXbLbWtrYa7itGOjZDqu
        jPNM48IFKcyGKnhs14SI11UBY/h8CZBQ6NJkP6zIeWD0pelkjvp8uj9LLUejDVDz
        zy3Y3lri6vYyXzPvo/pVMPJerZ5rnI9/tWSJie5jYyIE9J3eccCpleF5lyjwEelF
        zHkK4t3MTwORCsTr+dG7GXTaUtcQ4A7jMExD6yctXtLPEJGJ+18oxCWZzNG+jERJ
        AgMBAAGjJjAkMA4GA1UdDwEB/wQEAwICpDASBgNVHRMBAf8ECDAGAQH/AgEAMA0G
        CSqGSIb3DQEBCwUAA4IBAQA8cO1DXsSzUHEi2bv2VfYiX4Jc3Wh4BDpubncCj930
        Umv4WaMdxAnxyRhSyJnXTGEOorSNUATMXgnhHdpQIYPmseZ37fQON1/8N6Nn8kFB
        oNxPH7+J6KZ5i/BKtEvgbd4PADdqsxz/cvFfKySFgZLunFvNlr3eDbRC/sPkE6XM
        cmI72IvUVWlDdPOitGEJQT3AT52GEHUg18dWKpw1nQfynRa1X53KBLCuW21Jv0og
        M+RKbpdSVsxcN+U7XQOYg9JgoUWkyGpaJ4aHXMz5M6rwz0hUkqwgFHFBHEf4hQBV
        CC0v4+hF7niShAjBtGms0fgFsMlp3RYCoEMQ53zNyGz2
        -----END CERTIFICATE-----
EOF
kubectl label namespace default istio-injection=enabled

while [[ $(kubectl -n istio-system get pods -l app=istiod -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for Istiod" && sleep 10; done




echo =======================
echo === Deploy BookInfo ===
echo =======================
kubectl apply -f istio-$ISTIO_VERSION/samples/bookinfo/platform/kube/bookinfo.yaml

echo =======================
echo === Deploy Curl     ===
echo =======================
kubectl apply -f curl.yaml

echo ======================
echo ===    Done        ===
echo ======================
echo To conenct to the cluster run:
echo export KUBECONFIG=$(k3d kubeconfig write $CLUSTER_NAME)
echo
