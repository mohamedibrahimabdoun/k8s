#!/bin/sh


set -e


echo 'Installing kubernetes-dashboard'
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update
helm install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --namespace kube-system --set fullnameOverride="dashboard"



echo 'Installing metrics-server ...'
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm helm repo update
helm upgrade --install metrics-server metrics-server/metrics-server --namespace kube-system --set fullnameOverride="metrics" --set args="{--logtostderr,--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP\,ExternalIP\,Hostname}"



kubectl get apiservice v1beta1.metrics.k8s.io
sudo apt-get install jq -y
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes" | jq

echo 'Installing prometheus-operator ...'
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus --set alertmanager.enabled=false --set pushgateway.enabled=false --set server.persistentVolume.enabled=false --namespace monitoring --create-namespace



kubectl -n monitoring get pods
kubectl -n monitoring get svc


echo 'Installing MetalLB for external IPs'
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
kubectl apply -f /vagrant/MetalLB-IPAdressPool.yaml

echo 'Installing bookinfo app .. '
kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml


echo 'Installing istio pre-requists'
kubectl create clusterrolebinding istio-system-cluster-role-binding --clusterrole=cluster-admin --serviceaccount=istio-system:default


echo 'Installing Istio ..'
#curl -L -s https://api.github.com/repos/istio/istio/releases | grep tag_name

export ISTIO_VERSION=$(curl -L -s https://api.github.com/repos/istio/istio/releases/latest | grep tag_name | sed "s/ *\"tag_name\": *\"\\(.*\\)\",*/\\1/")
echo $ISTIO_VERSION

kubectl create namespace istio-system
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

helm install istio-base istio/base -n istio-system --set defaultRevision=default
helm ls -n istio-system
helm install istiod istio/istiod -n istio-system --wait
helm ls -n istio-system
helm status istiod -n istio-system

kubectl get deployments -n istio-system --output wide

echo 'Install an ingress gateway for istio'
kubectl create namespace istio-ingress
helm install istio-ingress istio/gateway -n istio-ingress --wait
