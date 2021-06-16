# CREATE RUNTIME CLASS:
-----------------------

* Create runtime class:

```
mohamed@master:~/cks/runtime$ cat runtime_class.yaml
apiVersion: node.k8s.io/v1beta1 # for 1.21 node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc

mohamed@master:~/cks/runtime$ kubectl -f runtime_class.yaml create
runtimeclass.node.k8s.io/gvisor created

kubectl run gvisor-pod --image=nginx --dry-run=client -oyaml > gvisor-pod.yaml


mohamed@master:~/cks/runtime$ cat gvisor-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: gvisor-pod
  name: gvisor-pod
spec:
  runtimeClassName: gvisor
  containers:
  - image: nginx
    name: gvisor-pod
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}



mohamed@master:~/cks/runtime$ k -f gvisor-pod.yaml create
pod/gvisor-pod created

mohamed@master:~/cks/runtime$  k get po -o wide
NAME         READY   STATUS              RESTARTS   AGE   IP               NODE     NOMINATED NODE   READINESS GATES
gvisor-pod   0/1     ContainerCreating   0          42s   <none>           worker   <none>           <none>
nginx2       1/1     Running             0          64m   192.168.171.84   worker   <none>           <none>
pod          1/1     Running             0          40m   192.168.171.85   worker   <none>           <none>

# pod will be created but it will not run because node worker doesn't have runsc runtime

mohamed@master:~/cks/runtime$ k describe pod gvisor-pod
Name:         gvisor-pod
Namespace:    default
Priority:     0
Node:         worker/10.0.0.3
Start Time:   Mon, 17 May 2021 06:14:47 +0000
Labels:       run=gvisor-pod
Annotations:  <none>
Status:       Pending
IP:
IPs:          <none>
Containers:
  gvisor-pod:
    Container ID:
    Image:          nginx
    Image ID:
    Port:           <none>
    Host Port:      <none>
    State:          Waiting
      Reason:       ContainerCreating
    Ready:          False
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-xlfvf (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             False
  ContainersReady   False
  PodScheduled      True
Volumes:
  default-token-xlfvf:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-xlfvf
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                 node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason                  Age               From               Message
  ----     ------                  ----              ----               -------
  Normal   Scheduled               19s               default-scheduler  Successfully assigned default/gvisor-pod to worker
  Warning  FailedCreatePodSandBox  7s (x2 over 19s)  kubelet, worker    Failed to create pod sandbox: rpc error: code = Unknown desc = RuntimeHandler "runsc" not supported
mohamed@master:~/cks/runtime$
```