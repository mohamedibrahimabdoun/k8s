

* Create a new PSP which prevents creating privileged pods and disallows pods which run as root

```
root@master:/home/mohamed/cks/psp# cat psp.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: my-psp
spec:
 allowPrivilegeEscalation: false
  privileged: false  # Don't allow privileged pods!
  # The rest fills in some required fields.
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  runAsUser:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  volumes:
  - '*'


 root@master:/home/mohamed/cks/psp# kubectl create -f psp.yaml
podsecuritypolicy.policy/my-psp created

root@master:/home/mohamed/cks/psp# kubectl get psp
NAME     PRIV    CAPS   SELINUX    RUNASUSER   FSGROUP    SUPGROUP   READONLYROOTFS   VOLUMES
my-psp   false          RunAsAny   RunAsAny    RunAsAny   RunAsAny   false            *

```
* testing psp on pods & deployment:
```
root@master:/home/mohamed/cks/psp# kubectl create deploy nginx --image=nginx
deployment.apps/nginx created

root@master:/home/mohamed/cks/psp# kubectl get deploy
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   0/1     0            0           7s

root@master:/home/mohamed/cks/psp# kubectl run nginx-pod --image=nginx
pod/nginx-pod created

root@master:/home/mohamed/cks/psp# kubectl get pod
NAME        READY   STATUS    RESTARTS   AGE
nginx-pod   1/1     Running   0          6s

```
* if we create a pod it will run but deployment won't.This is becuase the pod run as admin user ,even though deployment is created by admin it will be executed by default service account let's enabled that

```
root@master:/home/mohamed/cks/psp# kubectl create role psp-access --verb=use --resource=podsecuritypolicy
role.rbac.authorization.k8s.io/psp-access created

root@master:/home/mohamed/cks/psp# kubectl create rolebinding psp-access --role=psp-access --serviceaccount=default:default
rolebinding.rbac.authorization.k8s.io/psp-access created
root@master:/home/mohamed/cks/psp#


root@master:/home/mohamed/cks/psp# kubectl delete deploy nginx
deployment.apps "nginx" deleted
root@master:/home/mohamed/cks/psp# kubectl create deploy nginx --image=nginx
deployment.apps/nginx created
root@master:/home/mohamed/cks/psp# kubectl get deploy
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   1/1     1            1           7s

```

* example:

```
root@master:/home/mohamed/cks/psp# cat priv-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: priv-pod
  name: priv-pod
spec:
  containers:
  - image: busybox
    name: priv-pod
    securityContext:
      allowPrivilegeEscalation: true
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}


root@master:/home/mohamed/cks/psp# kubectl create -f priv-pod.yaml
Error from server (Forbidden): error when creating "priv-pod.yaml": pods "priv-pod" is forbidden: PodSecurityPolicy: unable to admit pod: [spec.containers[0].securityContext.allowPrivilegeEscalation: Invalid value: true: Allowing privilege escalation for containers is not allowed]

```

* edit priv-pod.yaml and change allowPrivilegeEscalation to false then try to create the pod

```
root@master:/home/mohamed/cks/psp# kubectl create -f priv-pod.yaml
pod/priv-pod created
root@master:/home/mohamed/cks/psp# kubectl get pod
NAME       READY   STATUS      RESTARTS   AGE
priv-pod   0/1     Completed   1          6s
root@master:/home/mohamed/cks/psp#
```

