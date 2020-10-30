# Ext Auth

Simple script to install k3d and istio

## Prequisites

- k3d v3+
- helm v3+

## Usage

    ./setup.sh

It'll generally be faster to stop and start the cluster rather than tear it down and rebuild it. So 

    k3d stop --name ext
    k3d start --name ext

## Connect to cluster

    export KUBECONFIG=$(k3d kubeconfig write ext)

## All env

    export KUBECONFIG=$(k3d kubeconfig write ext)
