Open Policy Agent:
=================

* Documenation Link: https://www.openpolicyagent.org/docs/latest/kubernetes-primer/
* Rego Palyground : https://play.openpolicyagent.org/


INSTALLATION :
-------------

* Install GateKeeper:

```
mohamed@master:~$ source <(kubectl completion bash)

hamed@master:~$ kubectl create -f https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/course-content/opa/gatekeeper.yaml
namespace/gatekeeper-system created
Warning: apiextensions.k8s.io/v1beta1 CustomResourceDefinition is deprecated in v1.16+, unavailable in v1.22+; use apiextensions.k8s.io/v1 CustomResourceDefinition
customresourcedefinition.apiextensions.k8s.io/configs.config.gatekeeper.sh created
customresourcedefinition.apiextensions.k8s.io/constraintpodstatuses.status.gatekeeper.sh created
customresourcedefinition.apiextensions.k8s.io/constrainttemplatepodstatuses.status.gatekeeper.sh created
customresourcedefinition.apiextensions.k8s.io/constrainttemplates.templates.gatekeeper.sh created
serviceaccount/gatekeeper-admin created
role.rbac.authorization.k8s.io/gatekeeper-manager-role created
clusterrole.rbac.authorization.k8s.io/gatekeeper-manager-role created
rolebinding.rbac.authorization.k8s.io/gatekeeper-manager-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/gatekeeper-manager-rolebinding created
secret/gatekeeper-webhook-server-cert created
service/gatekeeper-webhook-service created
deployment.apps/gatekeeper-audit created
deployment.apps/gatekeeper-controller-manager created
Warning: admissionregistration.k8s.io/v1beta1 ValidatingWebhookConfiguration is deprecated in v1.16+, unavailable in v1.22+; use admissionregistration.k8s.io/v1 ValidatingWebhookConfiguration
validatingwebhookconfiguration.admissionregistration.k8s.io/gatekeeper-validating-webhook-configuration created
```
* Validate gatekeeper-system namspace has been created
```
mohamed@master:~$ kubectl get namespaces
NAME                STATUS   AGE
default             Active   37d
dev-ns              Active   37d
gatekeeper-system   Active   13s
kube-node-lease     Active   37d
kube-public         Active   37d
kube-system         Active   37d
prod-a              Active   37d
prod-b              Active   37d
```

* Check gatekeeper-system  objects:
```
mohamed@master:~$ kubectl get -n gatekeeper-system pod,svc
NAME                                                 READY   STATUS    RESTARTS   AGE
pod/gatekeeper-audit-65f658df68-4nnck                1/1     Running   0          75s
pod/gatekeeper-controller-manager-5fb6c9ff69-46nkw   1/1     Running   0          75s

NAME                                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/gatekeeper-webhook-service   ClusterIP   10.103.3.140   <none>        443/TCP   76s
mohamed@master:~$
```


CREATE DENY ALL POLICY:
-----------------------

```
mohamed@master:~$ kubectl get crd
NAME                                                  CREATED AT
bgpconfigurations.crd.projectcalico.org               2021-04-09T23:04:25Z
bgppeers.crd.projectcalico.org                        2021-04-09T23:04:25Z
blockaffinities.crd.projectcalico.org                 2021-04-09T23:04:26Z
clusterinformations.crd.projectcalico.org             2021-04-09T23:04:26Z
configs.config.gatekeeper.sh                          2021-05-17T04:18:33Z
constraintpodstatuses.status.gatekeeper.sh            2021-05-17T04:18:33Z
constrainttemplatepodstatuses.status.gatekeeper.sh    2021-05-17T04:18:33Z
constrainttemplates.templates.gatekeeper.sh           2021-05-17T04:18:33Z
felixconfigurations.crd.projectcalico.org             2021-04-09T23:04:26Z
globalnetworkpolicies.crd.projectcalico.org           2021-04-09T23:04:26Z
globalnetworksets.crd.projectcalico.org               2021-04-09T23:04:26Z
hostendpoints.crd.projectcalico.org                   2021-04-09T23:04:26Z
ipamblocks.crd.projectcalico.org                      2021-04-09T23:04:26Z
ipamconfigs.crd.projectcalico.org                     2021-04-09T23:04:26Z
ipamhandles.crd.projectcalico.org                     2021-04-09T23:04:26Z
ippools.crd.projectcalico.org                         2021-04-09T23:04:26Z
kubecontrollersconfigurations.crd.projectcalico.org   2021-04-09T23:04:26Z
networkpolicies.crd.projectcalico.org                 2021-04-09T23:04:26Z
networksets.crd.projectcalico.org                     2021-04-09T23:04:27Z
```
* Check existing contraintTemplates: 
```
mohamed@master:~$ kubectl get constrainttemplates
No resources found
mohamed@master:~$
```


* https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/course-content/opa/deny-all/alwaysdeny_template.yaml
```
mohamed@master:~/cks$ cat always_deny_template.yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8salwaysdeny
spec:
  crd:
    spec:
      names:
        kind: K8sAlwaysDeny
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          properties:
            message:
              type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8salwaysdeny

        violation[{"msg": msg}] {
          1 > 0
          msg := input.parameters.message
        }
```
```
mohamed@master:~/cks$ kubectl -f always_deny_template.yaml create
constrainttemplate.templates.gatekeeper.sh/k8salwaysdeny created

mohamed@master:~/cks$ kubectl get ConstraintTemplate
NAME            AGE
k8salwaysdeny   58s
```

*  Create  Template:
https://raw.githubusercontent.com/mohamedibrahimabdoun/cks-course-environment/master/course-content/opa/deny-all/all_pod_always_deny.yaml 
```
mohamed@master:~/cks$ cat all_pod_always_deny.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAlwaysDeny
metadata:
  name: pod-always-deny
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    message: "ACCESS DENIED!"

mohamed@master:~/cks$ kubectl -f  all_pod_always_deny.yaml  create
k8salwaysdeny.constraints.gatekeeper.sh/pod-always-deny created
```
* check K8sAlwaysDeny :
```
mohamed@master:~/cks$ kubectl get k8salwaysdeny
NAME              AGE
pod-always-deny   112s
mohamed@master:~/cks$
```

* Create test pod , it should fail:
```
mohamed@master:~/cks$ kubectl run nginx --image=nginx
Error from server ([denied by pod-always-deny] ACCESS DENIED!): admission webhook "validation.gatekeeper.sh" denied the request: [denied by pod-always-deny] ACCESS DENIED!
```

## Notice `Total Violations:  13` which represnts the pods that is violating pod-always-deny contraints. exiting pods will still be running until te restarted then the policy will take affect.Newly create pods will not admitted.

```
mohamed@master:~/cks$ kubectl describe k8salwaysdeny
Name:         pod-always-deny
Namespace:
Labels:       <none>
Annotations:  <none>
API Version:  constraints.gatekeeper.sh/v1beta1
Kind:         K8sAlwaysDeny
Metadata:
  Creation Timestamp:  2021-05-17T04:41:01Z
  Generation:          1
  Managed Fields:
    API Version:  constraints.gatekeeper.sh/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:spec:
        .:
        f:match:
          .:
          f:kinds:
        f:parameters:
          .:
          f:message:
    Manager:      kubectl-create
    Operation:    Update
    Time:         2021-05-17T04:41:01Z
    API Version:  constraints.gatekeeper.sh/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:status:
        .:
        f:auditTimestamp:
        f:byPod:
        f:totalViolations:
        f:violations:
    Manager:         gatekeeper
    Operation:       Update
    Time:            2021-05-17T04:43:09Z
  Resource Version:  49336
  Self Link:         /apis/constraints.gatekeeper.sh/v1beta1/k8salwaysdeny/pod-always-deny
  UID:               b2b67045-64e8-4817-8928-56274a9763a0
Spec:
  Match:
    Kinds:
      API Groups:

      Kinds:
        Pod
  Parameters:
    Message:  ACCESS DENIED!
Status:
  Audit Timestamp:  2021-05-17T04:43:06Z
  By Pod:
    Constraint UID:       b2b67045-64e8-4817-8928-56274a9763a0
    Enforced:             true
    Id:                   gatekeeper-audit-65f658df68-4nnck
    Observed Generation:  1
    Operations:
      audit
      status
    Constraint UID:       b2b67045-64e8-4817-8928-56274a9763a0
    Enforced:             true
    Id:                   gatekeeper-controller-manager-5fb6c9ff69-46nkw
    Observed Generation:  1
    Operations:
      webhook
  Total Violations:  13
  Violations:
    Enforcement Action:  deny
    Kind:                Pod
    Message:             ACCESS DENIED!
    Name:                gatekeeper-audit-65f658df68-4nnck
    Namespace:           gatekeeper-system
    Enforcement Action:  deny
    Kind:                Pod
    Message:             ACCESS DENIED!
    Name:                gatekeeper-controller-manager-5fb6c9ff69-46nkw
    Namespace:           gatekeeper-system
    Enforcement Action:  deny
    Kind:                Pod
    Message:             ACCESS DENIED!
    Name:                calico-kube-controllers-69496d8b75-kz8hf
    Namespace:           kube-system
    Enforcement Action:  deny
    Kind:                Pod
    Message:             ACCESS DENIED!
    Name:                calico-node-jm7n7
    Namespace:           kube-system
    Enforcement Action:  deny
    Kind:                Pod
    Message:             ACCESS DENIED!
    Name:                calico-node-xvv8k
    Namespace:           kube-system
    Enforcement Action:  deny
    Kind:                Pod
    Message:             ACCESS DENIED!
    Name:                coredns-f9fd979d6-fdsr4
    Namespace:           kube-system
    Enforcement Action:  deny
    Kind:                Pod
    Message:             ACCESS DENIED!
    Name:                coredns-f9fd979d6-zgxs9
    Namespace:           kube-system
    Enforcement Action:  deny
    Kind:                Pod
    Message:             ACCESS DENIED!
    Name:                etcd-master
    Namespace:           kube-system
    Enforcement Action:  deny
    Kind:                Pod
    Message:             ACCESS DENIED!
    Name:                kube-apiserver-master
    Namespace:           kube-system
    Enforcement Action:  deny
    Kind:                Pod
    Message:             ACCESS DENIED!
    Name:                kube-controller-manager-master
    Namespace:           kube-system
    Enforcement Action:  deny
    Kind:                Pod
    Message:             ACCESS DENIED!
    Name:                kube-proxy-ftj92
    Namespace:           kube-system
    Enforcement Action:  deny
    Kind:                Pod
    Message:             ACCESS DENIED!
    Name:                kube-proxy-q2r6d
    Namespace:           kube-system
    Enforcement Action:  deny
    Kind:                Pod
    Message:             ACCESS DENIED!
    Name:                kube-scheduler-master
    Namespace:           kube-system
Events:                  <none>
mohamed@master:~/cks$
```

* Allow all pod to be created again:
```
mohamed@master:~/cks$ cat always_deny_template.yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8salwaysdeny
spec:
  crd:
    spec:
      names:
        kind: K8sAlwaysDeny
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          properties:
            message:
              type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8salwaysdeny

        violation[{"msg": msg}] {
          1 > 0 # true
          1 > 2 # <- add This condition will return false which will make the template not throughing any violation
          msg := input.parameters.message
        }
 ```
 * replace the old template and validate by creating test pod:

 ```
 mohamed@master:~/cks$ kubectl -f always_deny_template.yaml  replace
constrainttemplate.templates.gatekeeper.sh/k8salwaysdeny replaced

mohamed@master:~/cks$ kubectl run nginx2 --image=nginx
pod/nginx2 created
mohamed@master:~/cks$

mohamed@master:~/cks$ kubectl describe k8salwaysdeny.constraints.gatekeeper.sh  | grep "Total Violations"
  Total Violations:  0

```
* Clean up :
```
mohamed@master:~/cks$ kubectl -f always_deny_template.yaml delete
constrainttemplate.templates.gatekeeper.sh "k8salwaysdeny" deleted
```

# CREATE POLICY TO ENFORCE CERTAIN LABEL ON NEWLY CREATED PODs/NAMESPACES:
----------------------------

* Examples from https://github.com/killer-sh/cks-course-environment/tree/master/course-content/opa/namespace-labels 
* create the template that accepts a list of labels and validate if the objects has the required labels:
```
mohamed@master:~/cks/opa/deny_namespaces$ cat template.yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          properties:
            labels:
              type: array
              items: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels

        violation[{"msg": msg, "details": {"missing_labels": missing}}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("you must provide labels: %v", [missing])
        }
 ```

 ```
 mohamed@master:~/cks/opa/deny_namespaces$ kubectl -f template.yaml create
constrainttemplate.templates.gatekeeper.sh/k8srequiredlabels created

mohamed@master:~/cks/opa/deny_namespaces$ kubectl get constrainttemplate
NAME                AGE
k8srequiredlabels   74s

```

* create contraints that requires pods to have certains label(s), in this example all pods must have "cks" label:

```
mohamed@master:~/cks/opa/deny_namespaces$ cat pod_contraints.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: pod-must-have-cks
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    labels: ["cks"]
mohamed@master:~/cks/opa/deny_namespaces$ kubectl -f pod_contraints.yaml create
k8srequiredlabels.constraints.gatekeeper.sh/pod-must-have-cks created
mohamed@master:~/cks/opa/deny_namespaces$ kubectl get k8srequiredlabels
NAME                AGE
pod-must-have-cks   12s

##creating pod without a label
mohamed@master:~/cks/opa/deny_namespaces$ kubectl run pod --image=httpd
Error from server ([denied by pod-must-have-cks] you must provide labels: {"cks"}): admission webhook "validation.gatekeeper.sh" denied the request: [denied by pod-must-have-cks] you must provide labels: {"cks"}

## pod with cks label
mohamed@master:~/cks/opa/deny_namespaces$ kubectl run pod --image=httpd --labels=cks=true
pod/pod created
```

* Create contraint that requires all namespaces must have label cks:

```
mohamed@master:~/cks/opa/deny_namespaces$ cat ns_contraint.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: ns-must-have-cks
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Namespace"]
  parameters:
    labels: ["cks"]


mohamed@master:~/cks/opa/deny_namespaces$ kubectl -f  ns_contraint.yaml  create
k8srequiredlabels.constraints.gatekeeper.sh/ns-must-have-cks created

mohamed@master:~/cks/opa/deny_namespaces$ kubectl get K8sRequiredLabels
NAME                AGE
ns-must-have-cks    21s
pod-must-have-cks   4m55s

mohamed@master:~/cks/opa/deny_namespaces$ cat ns.yaml
apiVersion: v1
kind: Namespace
metadata:
  creationTimestamp: null
  name: test
  labels:
    cks: value
spec: {}
status: {}


mohamed@master:~/cks/opa/deny_namespaces$ kubectl -f ns.yaml create
namespace/test created

 ```


 * Cleanup 
 ```
mohamed@master:~/cks/opa/deny_namespaces$ kubectl -f template.yaml delete
constrainttemplate.templates.gatekeeper.sh "k8srequiredlabels" deleted
mohamed@master:~/cks/opa/deny_namespaces$
 ```




