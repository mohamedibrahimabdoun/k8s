
* policy file for auditing which collects all messages of metadata level.

```

root@master:/home/mohamed/cks/auditing# cd /etc/kubernetes/
root@master:/etc/kubernetes# mkdir audit
root@master:/etc/kubernetes# ls
admin.conf  audit  controller-manager.conf  kubelet.conf  manifests  pki  scheduler.conf


root@master:/etc/kubernetes# cat audit/policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  - level: Metadata
```

* Sample Kube-apiserver manafist file

```
root@master:/etc/kubernetes/audit# cat /etc/kubernetes/manifests/kube-apiserver.yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 10.0.0.2:6443
  creationTimestamp: null
  labels:
    component: kube-apiserver
    tier: control-plane
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-apiserver
    - --advertise-address=10.0.0.2
    - --allow-privileged=true
    - --authorization-mode=Node,RBAC
    - --client-ca-file=/etc/kubernetes/pki/ca.crt
    - --enable-admission-plugins=NodeRestriction,PodSecurityPolicy
    - --enable-bootstrap-token-auth=true
    - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
    - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
    - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
    - --etcd-servers=https://127.0.0.1:2379
    - --insecure-port=0
    - --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
    - --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
    - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
    - --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt
    - --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key
    - --requestheader-allowed-names=front-proxy-client
    - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
    - --requestheader-extra-headers-prefix=X-Remote-Extra-
    - --requestheader-group-headers=X-Remote-Group
    - --requestheader-username-headers=X-Remote-User
    - --secure-port=6443
    - --service-account-key-file=/etc/kubernetes/pki/sa.pub
    - --service-cluster-ip-range=10.96.0.0/12
    - --tls-cert-file=/etc/kubernetes/pki/apiserver.crt
    - --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
    - --profiling=false
    ### Enable Auditing
    - --audit-policy-file=/etc/kubernetes/audit/policy.yaml
    - --audit-log-path=/etc/kubernetes/audit/logs/audit.log
    - --audit-log-maxsize=500
    - --audit-log-maxbackup=5
    ######
    #- --kubelet-certificate-authority=/etc/kubernetes/pki/ca.crt
    image: k8s.gcr.io/kube-apiserver:v1.19.0
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 10.0.0.2
        path: /livez
        port: 6443
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    name: kube-apiserver
    readinessProbe:
      failureThreshold: 3
      httpGet:
        host: 10.0.0.2
        path: /readyz
        port: 6443
        scheme: HTTPS
      periodSeconds: 1
      timeoutSeconds: 15
    resources:
      requests:
        cpu: 250m
    startupProbe:
      failureThreshold: 24
      httpGet:
        host: 10.0.0.2
        path: /livez
        port: 6443
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    volumeMounts:
    - mountPath: /etc/ssl/certs
      name: ca-certs
      readOnly: true
    - mountPath: /etc/ca-certificates
      name: etc-ca-certificates
      readOnly: true
    - mountPath: /etc/kubernetes/pki
      name: k8s-certs
      readOnly: true
    - mountPath: /usr/local/share/ca-certificates
      name: usr-local-share-ca-certificates
      readOnly: true
    - mountPath: /usr/share/ca-certificates
      name: usr-share-ca-certificates
      readOnly: true
    ### Add mount for Auditing
    - mountPath: /etc/kubernetes/audit
      name: audit
  hostNetwork: true
  priorityClassName: system-node-critical
  volumes:
  ### Add Volumen for Auditing
  - hostPath:
      path: /etc/kubernetes/audit
      type: DirectoryOrCreate
    name: audit
  - hostPath:
      path: /etc/ssl/certs
      type: DirectoryOrCreate
    name: ca-certs
  - hostPath:
      path: /etc/ca-certificates
      type: DirectoryOrCreate
    name: etc-ca-certificates
  - hostPath:
      path: /etc/kubernetes/pki
      type: DirectoryOrCreate
    name: k8s-certs
  - hostPath:
      path: /usr/local/share/ca-certificates
      type: DirectoryOrCreate
    name: usr-local-share-ca-certificates
  - hostPath:
      path: /usr/share/ca-certificates
      type: DirectoryOrCreate
    name: usr-share-ca-certificates
``` 



* Moderate policy:

```
apiVersion: audit.k8s.io/v1 
kind: Policy
omitStages:
  - "RequestReceived"
rules:
  - level: RequestResponse
    resources:
    - group: ""
      resources: ["pods"]
  - level: Metadata
    resources:
    - group: ""
      resources: ["pods/log", "pods/status"]
  - level: Metadata
    userGroups: ["system:authenticated"]
    nonResourceURLs:
    - "/api*" 
    - "/version"
  - level: Request
    resources:
    - group: "" 
      resources: ["configmaps"]
    namespaces: ["kube-system"]
  - level: Metadata
    resources:
    - group: "" 
      resources: ["secrets", "configmaps"]
    omitStages:
      - "RequestReceived"
```


* policy not that noisy

```
apiVersion: audit.k8s.io/v1
kind: Policy
rules:

# log no "read" actions
- level: None
  verbs: ["get", "watch", "list"]

# log nothing regarding events
- level: None
  resources:
  - group: "" # core
    resources: ["events"]

# log nothing coming from some components
- level: None
  users:
  - "system:kube-scheduler"
  - "system:kube-proxy"
  - "system:apiserver"
  - "system:kube-controller-manager"
  - "system:serviceaccount:gatekeeper-system:gatekeeper-admin"

# log nothing coming from some groups
- level: None
  userGroups: ["system:nodes"]

# for everything else log on response level
- level: RequestResponse
```