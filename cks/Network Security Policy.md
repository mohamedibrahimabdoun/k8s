

* all_pods.yaml create 3 pods in 3 different namespaces
```
root@master:/home/mohamed/cks/networksecuritypolicy# cat all_pods.yaml
---
apiVersion: v1
kind: Namespace
metadata:
  creationTimestamp: null
  name: dev-ns
spec: {}
status: {}
---
apiVersion: v1
kind: Namespace
metadata:
  creationTimestamp: null
  name: prod-a
spec: {}
status: {}
---
apiVersion: v1
kind: Namespace
metadata:
  creationTimestamp: null
  name: prod-b
spec: {}
status: {}
---
apiVersion: v1
kind: Pod
metadata:
  name: devapp
  namespace: dev-ns
  labels:
    app: devapp
    user: bob
spec:
  containers:
  - name: ubuntu
    image: ubuntu:latest
    command: ["/bin/sleep", "3650d"]
    imagePullPolicy: IfNotPresent
  restartPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: prod-a
  labels:
    app: front
    user: tim
spec:
  containers:
  - name: frontend
    image: nginx
    imagePullPolicy: IfNotPresent
  restartPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  name: backend
  namespace: prod-b
  labels:
    app: back
    user: tim
spec:
  containers:
  - name: backend
    image: nginx
    imagePullPolicy: IfNotPresent
  restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: devapp
    user: bob
  name: devapp
  namespace: dev-ns
spec:
  ports:
  - port: 80
    name: web
    protocol: TCP
    targetPort: 80
  - port: 22
    name: ssh
    protocol: TCP
    targetPort: 22
  selector:
    app: devapp
    user: bob
  sessionAffinity: None
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: front
    user: tim
  name: frontend
  namespace: prod-a
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: front
    user: tim
  sessionAffinity: None
  type: NodePort
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: back
    user: tim
  name: backend
  namespace: prod-b
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: back
    user: tim
  sessionAffinity: None
  type: ClusterIP


root@master:/home/mohamed/cks/networksecuritypolicy# kubectl -f all_pods.yaml create
namespace/dev-ns created
namespace/prod-a created
namespace/prod-b created
pod/devapp created
pod/frontend created
pod/backend created
service/devapp created
service/frontend created
service/backend created

root@master:/home/mohamed/cks/networksecuritypolicy# kubectl get pods,svc -A  | grep -v kube-system
NAMESPACE     NAME                                           READY   STATUS    RESTARTS   AGE
dev-ns        pod/devapp                                     1/1     Running   0          8m34s
prod-a        pod/frontend                                   1/1     Running   0          8m34s
prod-b        pod/backend                                    1/1     Running   0          8m34s

NAMESPACE     NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                  AGE
default       service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP                  4d21h
dev-ns        service/devapp       ClusterIP   10.111.234.67   <none>        80/TCP,22/TCP            8m34s
prod-a        service/frontend     NodePort    10.100.13.34    <none>        80:30586/TCP             8m34s
prod-b        service/backend      ClusterIP   10.103.93.45    <none>        80/TCP                   8m34s

```

* On devapp install network utilities, and determine default access between pods in different namespaces

```
$ apt-get update ; DEBIAN_FRONTEND=noninteractive apt-get install iputils-ping netcat ssh curl iproute2 -y
####
root@devapp:/# curl frontend.prod-a.svc.cluster.local
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>

```

* validate devapp container has access to outside world
```
root@devapp:/#  ping -c3 www.google.com
PING www.google.com (74.125.142.106) 56(84) bytes of data.
64 bytes from ie-in-f106.1e100.net (74.125.142.106): icmp_seq=1 ttl=114 time=0.936 ms
64 bytes from ie-in-f106.1e100.net (74.125.142.106): icmp_seq=2 ttl=114 time=1.14 ms
```

* Test access from outside the cluster to frontend pod using the nodeport service
```
✘ mohamed@Mohameds-MacBook-Pro  ~  curl http://34.83.45.155:30586
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```


* create Policy to deny all traffic to prod-a
```
root@master:/home/mohamed/cks/networksecuritypolicy# cat deny_all_prd_a.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress
  namespace: prod-a
spec:
  podSelector: {}
  policyTypes:
  - Ingress
root@master:/home/mohamed/cks/networksecuritypolicy# kubectl -f deny_all_prd_a.yaml create
networkpolicy.networking.k8s.io/deny-ingress created


root@master:/home/mohamed/cks/networksecuritypolicy# kubectl get networkpolicy -n prod-a
NAME           POD-SELECTOR   AGE
deny-ingress   <none>         2m37s

root@master:/home/mohamed/cks/networksecuritypolicy# kubectl describe  networkpolicy -n prod-a
Name:         deny-ingress
Namespace:    prod-a
Created on:   2021-05-24 04:46:23 +0000 UTC
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Allowing ingress traffic:
    <none> (Selected pods are isolated for ingress connectivity)
  Not affecting egress traffic
  Policy Types: Ingress

```

* test access from devapp, notice you cannot access frontend pod but you can access backend pod

```
root@master:/home/mohamed/cks/networksecuritypolicy# kubectl -n dev-ns exec -it devapp -- bash

root@devapp:/# curl frontend.prod-a.svc.cluster.local
^C
root@devapp:/# curl backend.prod-b.svc.cluster.local
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
root@devapp:/#

```

* from frontend pod you should be able to communicate with backend pod

```
root@master:/home/mohamed/cks/networksecuritypolicy# kubectl -n prod-a exec -it frontend -- bash
root@frontend:/# curl backend.prod-b.svc.cluster.local
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>

```

* Test backend and test access to frontend, which should fail
```
root@master:/home/mohamed/cks/networksecuritypolicy# kubectl -n prod-b exec -it backend -- bash
root@backend:/# curl frontend.prod-a.svc.cluster.local
^C
root@backend:/#
```

# Create a new network policy to allow ingress access for pods with a label of app: front, but no other pods

```
root@master:/home/mohamed/cks/networksecuritypolicy# kubectl run another-pod -n prod-a --image=nginx -l app=front
pod/another-pod created

root@master:/home/mohamed/cks/networksecuritypolicy# kubectl get pod -n prod-a --show-labels
NAME          READY   STATUS    RESTARTS   AGE   LABELS
another-pod   1/1     Running   0          22s   app=front
frontend      1/1     Running   0          44m   app=front,user=tim

# before applyig the policy

root@master:/home/mohamed/cks/networksecuritypolicy# kubectl exec -it -n prod-a another-pod -- bash
root@another-pod:/#  curl frontend.prod-a.svc.cluster.local
^C
root@another-pod:/# exit



root@master:/home/mohamed/cks/networksecuritypolicy# kubectl -f allow_app_front_only.yaml replace
networkpolicy.networking.k8s.io/app-front-only replaced

root@master:/home/mohamed/cks/networksecuritypolicy# cat allow_app_front_only.yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: app-front-only
  namespace: prod-a
spec:
  podSelector:
    matchLabels:
      app: front
  policyTypes:
  - Ingress
  ingress:
  - {}


root@master:/home/mohamed/cks/networksecuritypolicy# kubectl exec -it -n prod-a another-pod -- bash
root@another-pod:/#  curl frontend.prod-a.svc.cluster.local
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>

```

* Cleanup

```
root@master:/home/mohamed/cks/networksecuritypolicy# kubectl delete pod,svc,networkpolicy  -n prod-a --all
pod "another-pod" deleted
pod "frontend" deleted
service "frontend" deleted
networkpolicy.networking.k8s.io "app-front-only" deleted
networkpolicy.networking.k8s.io "deny-ingress" deleted
root@master:/home/mohamed/cks/networksecuritypolicy# kubectl delete pod,svc,networkpolicy  -n prod-b --all
pod "backend" deleted
service "backend" deleted
```