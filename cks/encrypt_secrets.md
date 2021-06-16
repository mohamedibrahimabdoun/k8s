
# View secret in etcd

* create secret:
```
root@master:/home/mohamed/cks/encrypt_secrets# kubectl create secret generic sec01 -n default --from-literal=somekey=findme
secret/sec01 created

root@master:/home/mohamed/cks/encrypt_secrets# kubectl get secret sec01
NAME    TYPE     DATA   AGE
sec01   Opaque   1      35s


```

* get etcd certs from kube-apiserver yaml (kubeadm only)

```
root@master:/home/mohamed/cks/encrypt_secrets# sudo grep etcd /etc/kubernetes/manifests/kube-apiserver.yaml
    - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
    - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
    - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
    - --etcd-servers=https://127.0.0.1:2379



kubectl -n kube-system exec -it etcd-master -- sh -c \
"ETCDCTL_API=3;ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt ;
ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt ; ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key; etcdctl --endpoints=https://127.0.0.1:2379 get /registry/secrets/default/sec01"

OR


kubectl -n kube-system exec -it etcd-master -- sh -c \
> "ETCDCTL_API=3;
> etcdctl --endpoints=https://127.0.0.1:2379 --cacert="/etc/kubernetes/pki/etcd/ca.crt" --cert="/etc/kubernetes/pki/etcd/server.crt" --key="/etc/kubernetes/pki/etcd/server.key" get /registry/secrets/default/sec01"
/registry/secrets/default/sec01
k8s


v1Secret�
�
sec01default"*$d0432846-e10d-4ce5-b558-21bca68f6dc12�ͥ�z�b
kubectl-createUpdatev�ͥ�FieldsV1:0
.{"f:data":{".":{},"f:somekey":{}},"f:type":{}}
somekeyfindmeOpaque"



```

# Encrypt All secrets using aesgcm providor:


```
root@master:/etc/kubernetes/etcd# head -c 32 /dev/urandom | base64
fKiMVhYJ0/GgAQTMLZc7uSWbGE7idvk6PlteraedJuk=


root@master:/etc/kubernetes/etcd# cat encryptionconfig.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
    - secrets
    providers:
    - aesgcm:
        keys:
        - name: key1
          secret: fKiMVhYJ0/GgAQTMLZc7uSWbGE7idvk6PlteraedJuk=
    - identity: {}


root@master:/var/log/pods# cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep -i -A3 etcd
    - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
    - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
    - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
    - --etcd-servers=https://127.0.0.1:2379
    - --insecure-port=0
    - --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
    - --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
--
    ###### etcd encryption providor
    - --encryption-provider-config=/etc/kubernetes/etcd/encryptionconfig.yaml
    #- --kubelet-certificate-authority=/etc/kubernetes/pki/ca.crt
    image: k8s.gcr.io/kube-apiserver:v1.19.0
    imagePullPolicy: IfNotPresent
--
    - mountPath: /etc/kubernetes/etcd
      name: etcd
  hostNetwork: true
  priorityClassName: system-node-critical
  volumes:
--
      path: /etc/kubernetes/etcd
      type: DirectoryOrCreate
    name: etcd
  - hostPath:
      path: /etc/kubernetes/audit
      type: DirectoryOrCreate

```


* verify encrption is working by creating another secret:

```
root@master:/var/log/pods# kubectl create secret generic sec02 -n default --from-literal=anotherkey=hidden
secret/sec02 created
root@master:/var/log/pods# kubectl get secret sec02
NAME    TYPE     DATA   AGE
sec02   Opaque   1      12s
root@master:/var/log/pods#


kubectl -n kube-system exec -it etcd-master -- sh -c \
"ETCDCTL_API=3;
etcdctl --endpoints=https://127.0.0.1:2379 --cacert="/etc/kubernetes/pki/etcd/ca.crt" --cert="/etc/kubernetes/pki/etcd/server.crt" --key="/etc/kubernetes/pki/etcd/server.key" get /registry/secrets/default/sec02"

root@master:/var/log/pods# kubectl -n kube-system exec -it etcd-master -- sh -c \
> "ETCDCTL_API=3;
> etcdctl --endpoints=https://127.0.0.1:2379 --cacert="/etc/kubernetes/pki/etcd/ca.crt" --cert="/etc/kubernetes/pki/etcd/server.crt" --key="/etc/kubernetes/pki/etcd/server.key" get /registry/secrets/default/sec02"
/registry/secrets/default/sec02
k8s:enc:aesgcm:v1:key1:��,�9l�"�
                                _{$�t��!S(��t�n��"dϷJ���DR~]�Iy��*�5�6�b"3�P�Lw�ĩvj
�uV���7�!��;�x����ßш���B��ϭ�,)��K                                                  �b��p����䱜q��Ie��
                                 �T�=k��t�Ji;_a����s�v,�/��K��?�}�j#9���B2�C��9킿��7�_������_=�[o�|�v�$ �d�)���q�^�)Y�.#��ax��#��	(�L�T�D��*�,��
root@master:/var/log/pods#

```

* Ensure all secrets are encrypted
```
root@master:/var/log/pods# kubectl get secrets --all-namespaces -o json | kubectl replace -f -
secret/default-token-stpbm replaced
secret/my-sa-token-8zf5c replaced
secret/sec01 replaced
secret/sec02 replaced
secret/default-token-s2gtq replaced
secret/default-token-xxtvb replaced
secret/attachdetach-controller-token-zvsf4 replaced
secret/bootstrap-signer-token-vcrbn replaced
secret/bootstrap-token-4dd1ox replaced
secret/calico-kube-controllers-token-dgvl2 replaced
secret/calico-node-token-nzkv4 replaced
secret/certificate-controller-token-hrhp7 replaced
secret/clusterrole-aggregation-controller-token-tkxd9 replaced
secret/coredns-token-f7nvn replaced
secret/cronjob-controller-token-mx594 replaced
secret/daemon-set-controller-token-7rdlb replaced
secret/default-token-mfd5z replaced
secret/deployment-controller-token-zcjjj replaced
secret/disruption-controller-token-jhcwg replaced
secret/endpoint-controller-token-wptk5 replaced
secret/endpointslice-controller-token-pndkc replaced
secret/endpointslicemirroring-controller-token-bxzmh replaced
secret/expand-controller-token-nzm89 replaced
secret/generic-garbage-collector-token-z7lwz replaced
secret/horizontal-pod-autoscaler-token-s2hsg replaced
secret/job-controller-token-dcpg6 replaced
secret/kube-proxy-token-4n98g replaced
secret/namespace-controller-token-vqdwv replaced
secret/node-controller-token-rvbdz replaced
secret/persistent-volume-binder-token-fxptt replaced
secret/pod-garbage-collector-token-xzxnv replaced
secret/pv-protection-controller-token-hp5qg replaced
secret/pvc-protection-controller-token-rl87z replaced
secret/replicaset-controller-token-z9t78 replaced
secret/replication-controller-token-6m7nk replaced
secret/resourcequota-controller-token-2j4qr replaced
secret/service-account-controller-token-rtbsh replaced
secret/service-controller-token-mjj5q replaced
secret/statefulset-controller-token-jt2fv replaced
secret/token-cleaner-token-nzw7b replaced
secret/ttl-controller-token-8sprm replaced
secret/default-token-ptfsq replaced
root@master:/var/log/pods#


* Check if the old secret sec01 is encrypted now:

kubectl -n kube-system exec -it etcd-master -- sh -c \
"ETCDCTL_API=3;
etcdctl --endpoints=https://127.0.0.1:2379 --cacert="/etc/kubernetes/pki/etcd/ca.crt" --cert="/etc/kubernetes/pki/etcd/server.crt" --key="/etc/kubernetes/pki/etcd/server.key" get /registry/secrets/default/sec01"


root@master:/var/log/pods# kubectl -n kube-system exec -it etcd-master -- sh -c \
> "ETCDCTL_API=3;
> etcdctl --endpoints=https://127.0.0.1:2379 --cacert="/etc/kubernetes/pki/etcd/ca.crt" --cert="/etc/kubernetes/pki/etcd/server.crt" --key="/etc/kubernetes/pki/etcd/server.key" get /registry/secrets/default/sec01"
/registry/secrets/default/sec01
k8s:enc:aesgcm:v1:key1:(ժZq��kV�>�p��Z���y�!6g���c0��|$�@x#x��&D���Ny4~o/|&n�[IV�[߹7��F�Ǘ����w�����h����؅�U�L��J6D����@,-v��/��(�`�=��b(�:�LA�W6�L�:��Z�,�5
                                                                                                                                                           "�>���4�6��ۚ@��qI��s�v��٫qLI�X@��C��A34�+��
�͵B�� �pE�4ւs���@a�S�e�=��
root@master:/var/log/pods#
```


