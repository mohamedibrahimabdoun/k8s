# Service Account:
------------------

* create serviceAccount using Commandline:

```
root@master:/home/mohamed# kubectl create sa my-sa
serviceaccount/my-sa created
```

* Create pod uses my-sa service account

```
root@master:/home/mohamed# cat my-sa-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: my-sa-pod
  name: my-sa-pod
spec:
  serviceAccountName: my-sa
  containers:
  - image: nginx
    name: my-sa-pod
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}


root@master:/home/mohamed# kubectl create -f my-sa-pod.yaml
pod/my-sa-pod created


root@master:/home/mohamed# kubectl exec -it my-sa-pod  bash
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
root@my-sa-pod:/# mount | grep token
root@my-sa-pod:/# mount | grep sec
tmpfs on /run/secrets/kubernetes.io/serviceaccount type tmpfs (ro,relatime)


root@my-sa-pod:/run/secrets/kubernetes.io/serviceaccount# ls -lrt
total 0
lrwxrwxrwx 1 root root 12 May 22 05:49 token -> ..data/token
lrwxrwxrwx 1 root root 16 May 22 05:49 namespace -> ..data/namespace
lrwxrwxrwx 1 root root 13 May 22 05:49 ca.crt -> ..data/ca.crt


root@my-sa-pod:/run/secrets/kubernetes.io/serviceaccount# curl https://kubernetes -k
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {

  },
  "status": "Failure",
  "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
  "reason": "Forbidden",
  "details": {

  },
  "code": 403
}



root@my-sa-pod:/run/secrets/kubernetes.io/serviceaccount# TOKEN=$(cat /run/secrets/kubernetes.io/serviceaccount/token)
root@my-sa-pod:/run/secrets/kubernetes.io/serviceaccount# curl https://kubernetes -k -H "Authorization: Bearer $TOKEN"
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {

  },
  "status": "Failure",
  "message": "forbidden: User \"system:serviceaccount:default:my-sa\" cannot get path \"/\"",
  "reason": "Forbidden",
  "details": {

  },
  "code": 403
}root@my-sa-pod:/run/secrets/kubernetes.io/serviceaccount#
```

* grant permissions to my-sa to list pods:

```
root@master:/home/mohamed# cat my-sa-rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  creationTimestamp: null
  name: my-sa-clusterrole
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- apiGroup: ""
  kind: ServiceAccount
  name: my-sa
  namespace: default


root@master:/home/mohamed# kubectl create -f my-sa-rolebinding.yaml
clusterrolebinding.rbac.authorization.k8s.io/my-sa-clusterrole created


root@my-sa-pod:/# curl https://kubernetes/api/v1/pods  -k -H "Authorization: Bearer $TOKEN" | more
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0{
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": {
    "selfLink": "/api/v1/pods",
    "resourceVersion": "23664"
  },
  "items": [
    {
      "metadata": {
        "name": "my-sa-pod",
        "namespace": "default",
        "selfLink": "/api/v1/namespaces/default/pods/my-sa-pod",
        "uid": "b6248ff9-69f7-45c9-936e-90ff2af28317",
        "resourceVersion": "23460",
        "creationTimestamp": "2021-05-22T06:17:56Z",
        "labels": {
          "run": "my-sa-pod"
        },
        "annotations": {
          "cni.projectcalico.org/podIP": "192.168.171.72/32",
          "cni.projectcalico.org/podIPs": "192.168.171.72/32"
        },
        "managedFields": [
          {
            "manager": "kubectl-create",
            "operation": "Update",
            "apiVersion": "v1",
            "time": "2021-05-22T06:17:56Z",
            "fieldsType": "FieldsV1",
            "fieldsV1": {"f:metadata":{"f:labels":{".":{},"f:run":{}}},"f:spec":{"f:containers":{"k:{\"name\":\"my-sa-pod\"}":{".":{},"f:image":{},"f:imagePullPolicy":{},"f:name":{},"f:resources":{},"f:terminationMessagePath":{},"f:termin
ationMessagePolicy":{}}},"f:dnsPolicy":{},"f:enableServiceLinks":{},"f:restartPolicy":{},"f:schedulerName":{},"f:securityContext":{},"f:serviceAccount":{},"f:serviceAccountName":{},"f:terminationGracePeriodSeconds":{}}}
          },
          {
            "manager": "calico",
            "operation": "Update",
            "apiVersion": "v1",
            "time": "2021-05-22T06:17:57Z",
            "fieldsType": "FieldsV1",
            "fieldsV1": {"f:metadata":{"f:annotations":{".":{},"f:cni.projectcalico.org/podIP":{},"f:cni.projectcalico.org/podIPs":{}}}}
          },
```


#Disabling ServiceAccount mounting

https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
* On serviceAccount Level
```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: build-robot
automountServiceAccountToken: false
...

```

* On Pod level:
```
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  serviceAccountName: build-robot
  automountServiceAccountToken: false
  ...
```