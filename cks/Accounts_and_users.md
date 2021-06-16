
# intro
   *  Service Account : managed by the k8s api 
   *  Normal User: 
   		- it is assumed that a cluster-independent service manage normal users.
   		- authenticated using client certificate
   		- Certificate signed by the cluster's CA
   		- username under common name e.g /Cn=jane
   	* openssl -> Key -> CSR -> CertificatSigningRequest -> [K8s API] -> Cert -> Download Cert -> user CRT + Key to access the cluster
   	* If a certificate leaked there is no way to invalidate a certificate but you can revoke permission from that specific user


# Create CSR:

* generate private key:
```
root@master:/home/mohamed/cks/RBAC# openssl genrsa -out jane.key 2048
Generating RSA private key, 2048 bit long modulus (2 primes)
......................+++++
...........+++++
e is 65537 (0x010001)
```

* create CSR , you can leave all field to default EXCEPT Common Name it MUST be set to jane
```
root@master:/home/mohamed/cks/RBAC# openssl req -new -key jane.key -out jane.csr
Can't load /root/.rnd into RNG
140207680344512:error:2406F079:random number generator:RAND_load_file:Cannot open file:../crypto/rand/randfile.c:88:Filename=/root/.rnd
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:
State or Province Name (full name) [Some-State]:
Locality Name (eg, city) []:
Organization Name (eg, company) [Internet Widgits Pty Ltd]:
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:jane
Email Address []:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
```

* create CertificateSigningRequest with base64 jane.csr
```
CERT_BASE64=$(cat jane.csr | base64 -w 0)

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: jane
spec:
  groups:
  - system:authenticated
  request: $CERT_BASE64
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF

root@master:/home/mohamed/cks/RBAC# k get csr
NAME        AGE   SIGNERNAME                                    REQUESTOR                 CONDITION
csr-k7dwl   59m   kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:c56hfa   Approved,Issued
jane        3s    kubernetes.io/kube-apiserver-client           kubernetes-admin          Pending
root@master:/home/mohamed/cks/RBAC#

root@master:/home/mohamed/cks/RBAC# k certificate  approve jane
certificatesigningrequest.certificates.k8s.io/jane approved

root@master:/home/mohamed/cks/RBAC# k get csr
NAME        AGE   SIGNERNAME                                    REQUESTOR                 CONDITION
csr-k7dwl   60m   kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:c56hfa   Approved,Issued
jane        64s   kubernetes.io/kube-apiserver-client           kubernetes-admin          Approved,Issued


root@master:/home/mohamed/cks/RBAC# k get csr jane -o json | jq -r .status.certificate | base64 -d > jane.crt
root@master:/home/mohamed/cks/RBAC# ll jane.crt
-rw-r--r-- 1 root root 1180 May 19 08:24 jane.crt

root@master:/home/mohamed/cks/RBAC# k config set-credentials jane --client-key=jane.key --client-certificate=jane.crt
User "jane" set.
root@master:/home/mohamed/cks/RBAC# k config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://10.0.0.2:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: jane
  user:
    client-certificate: /home/mohamed/cks/RBAC/jane.crt
    client-key: /home/mohamed/cks/RBAC/jane.key
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED


 * to add the cert values to kubeconfig use --embed-certs option

 * create context to connect to cluster
 root@master:/home/mohamed/cks/RBAC# k config set-context jane --cluster=kubernetes --user=jane
Context "jane" created.
root@master:/home/mohamed/cks/RBAC# k config get-contexts
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
          jane                          kubernetes   jane
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin
root@master:/home/mohamed/cks/RBAC# k config use-context jane
Switched to context "jane".
root@master:/home/mohamed/cks/RBAC# k config get-contexts
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         jane                          kubernetes   jane
          kubernetes-admin@kubernetes   kubernetes   kubernetes-admin
root@master:/home/mohamed/cks/RBAC# k get pod
Error from server (Forbidden): pods is forbidden: User "jane" cannot list resource "pods" in API group "" in the namespace "default"

* user jane doesn't have permission to list pod in the cluster that's why we got this error msg
```



