
* Create a file called `demo-profile.yaml` with the following contents: 
```
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: demo-installation
spec:
  profile: demo
```


* more Operator configurations:
```angular2html
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    base:
      enabled: true
    egressGateways:
    - enabled: false
      name: istio-egressgateway
    ingressGateways:
    - enabled: true
      name: istio-ingressgateway
    pilot:
      enabled: true
  hub: docker.io/istio
  profile: default
  tag: 1.22.1
  values:
    defaultRevision: ""
    gateways:
      istio-egressgateway: {}
      istio-ingressgateway: {}
    global:
      configValidation: true
      istioNamespace: istio-system
```

### * Helm installation
```angular2html
kubectl create namespace istio-system
kubectl create namespace istio-gateway

helm install istio-base istio/base -n istio-system  --version 1.21.0
helm install istiod istio/istiod -n istio-system --version 1.21.0
helm install istio-ingressgateway istio/gateway -n istio-gateway --version 1.21.0


```
