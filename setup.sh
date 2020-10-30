#!/bin/bash

CLUSTER_NAME=ext

echo ======================
echo === Create Cluster ===
echo ======================

k3d cluster delete $CLUSTER_NAME
k3d cluster create --no-lb --update-default-kubeconfig=false --wait $CLUSTER_NAME
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
  name: example-istiocontrolplane
spec:
  profile: demo
EOF
kubectl label namespace default istio-injection=enabled

echo =======================
echo === Deploy BookInfo ===
echo =======================
kubectl apply -f istio-$ISTIO_VERSION/samples/bookinfo/platform/kube/bookinfo.yaml

echo ======================
echo ===    Done        ===
echo ======================
echo To conenct to the cluster run:
echo export KUBECONFIG=$(k3d kubeconfig write $CLUSTER_NAME)
echo
