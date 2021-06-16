# Role and Rolebindings (command-line)

```
k create ns red
k create ns blue

k -n red create role secret-manager --verb=get --resource=secrets
k -n red create rolebinding secret-manager --role=secret-manager --user=jane
k -n blue create role secret-manager --verb=get --verb=list --resource=secrets
k -n blue create rolebinding secret-manager --role=secret-manager --user=jane


# check permissions
k -n red auth can-i -h
k -n red auth can-i create pods --as jane # no
k -n red auth can-i get secrets --as jane # yes
k -n red auth can-i list secrets --as jane # no

k -n blue auth can-i list secrets --as jane # yes
k -n blue auth can-i get secrets --as jane # yes

k -n default auth can-i get secrets --as jane #no
```
# Role and Rolebindings (using YAML):

* Create role to get,watch and delete pods and secrets in prod-2 namespace

```
root@master:/home/mohamed/cks/RBAC# kubectl create namespace prod-2
namespace/prod-2 created

```

```
root@master:/home/mohamed/cks/RBAC# cat limitedrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: prod-2
  name: limitedrole
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "delete"]
```

* Verify the role created

```
root@master:/home/mohamed/cks/RBAC# k get role -n prod-2
NAME          CREATED AT
limitedrole   2021-05-19T07:46:24Z

root@master:/home/mohamed/cks/RBAC# k describe role limitedrole -n prod-2
Name:         limitedrole
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  pods       []                 []              [get watch delete]
```

* Bind the role to the user alex in the same namespace

```
root@master:/home/mohamed/cks/RBAC# cat limitedrolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: manage-pods
  namespace: prod-2
subjects:
- kind: User
  name: alex
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: limitedrole
  apiGroup: rbac.authorization.k8s.io

root@master:/home/mohamed/cks/RBAC# k -f limitedrolebinding.yaml create
rolebinding.rbac.authorization.k8s.io/manage-pods created

root@master:/home/mohamed/cks/RBAC# k get rolebindings -n prod-2
NAME          ROLE               AGE
manage-pods   Role/limitedrole   14s

root@master:/home/mohamed/cks/RBAC# k describe rolebinding manage-pods -n prod-2
Name:         manage-pods
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  Role
  Name:  limitedrole
Subjects:
  Kind  Name  Namespace
  ----  ----  ---------
  User  alex
```


* check Alex's permissions:
```
root@master:/home/mohamed/cks/RBAC# k -n prod-2 auth can-i create pod --as alex
no
root@master:/home/mohamed/cks/RBAC# k -n prod-2 auth can-i get pod --as alex
yes
root@master:/home/mohamed/cks/RBAC# k -n prod-2 auth can-i watch pod --as alex
yes
root@master:/home/mohamed/cks/RBAC# k -n prod-2 auth can-i list  pod --as alex
no
root@master:/home/mohamed/cks/RBAC#
```


# ClusterRole and ClsuterRoleBinding:

```
k create clusterrole deploy-deleter --verb=delete --resource=deployment

k create clusterrolebinding deploy-deleter --clusterrole=deploy-deleter --user=jane

k -n red create rolebinding deploy-deleter --clusterrole=deploy-deleter --user=jim


# test jane
k auth can-i delete deploy --as jane # yes
k auth can-i delete deploy --as jane -n red # yes
k auth can-i delete deploy --as jane -n blue # yes
k auth can-i delete deploy --as jane -A # yes
k auth can-i create deploy --as jane --all-namespaces # no



# test jim
k auth can-i delete deploy --as jim # no
k auth can-i delete deploy --as jim -A # no
k auth can-i delete deploy --as jim -n red # yes
k auth can-i delete deploy --as jim -n blue # no

```
