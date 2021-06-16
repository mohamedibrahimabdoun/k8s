
* Install nginx controller

```
root@master:/home/mohamed/cks/ingress# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.40.2/deploy/static/provider/baremetal/deploy.yaml
namespace/ingress-nginx created
serviceaccount/ingress-nginx created
configmap/ingress-nginx-controller created
clusterrole.rbac.authorization.k8s.io/ingress-nginx created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
role.rbac.authorization.k8s.io/ingress-nginx created
rolebinding.rbac.authorization.k8s.io/ingress-nginx created
service/ingress-nginx-controller-admission created
service/ingress-nginx-controller created
deployment.apps/ingress-nginx-controller created
validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created
serviceaccount/ingress-nginx-admission created
clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
role.rbac.authorization.k8s.io/ingress-nginx-admission created
rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
job.batch/ingress-nginx-admission-create created
job.batch/ingress-nginx-admission-patch created


root@master:/home/mohamed/cks/ingress# kubectl get pod,deploy,svc -n ingress-nginx -o wide
NAME                                            READY   STATUS      RESTARTS   AGE   IP               NODE     NOMINATED NODE   READINESS GATES
pod/ingress-nginx-admission-create-k2xkt        0/1     Completed   0          33s   192.168.171.90   worker   <none>           <none>
pod/ingress-nginx-admission-patch-w5zq4         0/1     Completed   0          33s   192.168.171.91   worker   <none>           <none>
pod/ingress-nginx-controller-785557f9c9-6rzrx   0/1     Running     0          33s   192.168.171.92   worker   <none>           <none>

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                                                                                                                SELECTOR
deployment.apps/ingress-nginx-controller   0/1     1            0           33s   controller   k8s.gcr.io/ingress-nginx/controller:v0.40.2@sha256:46ba23c3fbaafd9e5bd01ea85b2f921d9f2217be082580edc22e6c704a83f02f   app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx

NAME                                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE   SELECTOR
service/ingress-nginx-controller             NodePort    10.108.169.210   <none>        80:30796/TCP,443:32584/TCP   34s   app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
service/ingress-nginx-controller-admission   ClusterIP   10.110.3.40      <none>        443/TCP                      34s   app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx

```

* test nginx from outside the cluster
```
 mohamed@Mohameds-MacBook-Pro  ~  curl http://34.83.45.155:30796 -v
*   Trying 34.83.45.155...
* TCP_NODELAY set
* Connected to 34.83.45.155 (34.83.45.155) port 30796 (#0)
> GET / HTTP/1.1
> Host: 34.83.45.155:30796
> User-Agent: curl/7.64.1
> Accept: */*
>
< HTTP/1.1 404 Not Found
< Date: Mon, 24 May 2021 05:43:15 GMT
< Content-Type: text/html
< Content-Length: 146
< Connection: keep-alive
<
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
```

* create pod & service:

```
kubectl run pod --image=httpd

root@master:/home/mohamed/cks/ingress# kubectl expose pod pod --port=80 --name=frontend-svc
service/frontend-svc exposed
root@master:/home/mohamed/cks/ingress# kubectl get pods,svc
NAME      READY   STATUS    RESTARTS   AGE
pod/pod   1/1     Running   0          94s

NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/frontend-svc   ClusterIP   10.97.170.163   <none>        80/TCP    10s
service/kubernetes     ClusterIP   10.96.0.1       <none>        443/TCP   4d23h

root@master:/home/mohamed/cks/ingress# curl http://10.97.170.163
<html><body><h1>It works!</h1></body></html>

```

* create ingress to expose the httpd pod

```
root@master:/home/mohamed/cks/ingress# kubectl -f ingress.yaml create
ingress.networking.k8s.io/frontend-ingress created
root@master:/home/mohamed/cks/ingress# cat ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: frontend-svc
            port:
              number: 80
root@master:/home/mohamed/cks/ingress# kubectl get ingress
Warning: extensions/v1beta1 Ingress is deprecated in v1.14+, unavailable in v1.22+; use networking.k8s.io/v1 Ingress
NAME               CLASS    HOSTS   ADDRESS    PORTS   AGE
frontend-ingress   <none>   *       10.0.0.3   80      12s
root@master:/home/mohamed/cks/ingress#
```

* test from outside the cluster:
```
 mohamed@Mohameds-MacBook-Pro  ~  curl http://34.83.45.155:30796/api
<html><body><h1>It works!</h1></body></html>
 mohamed@Mohameds-MacBook-Pro  ~ 
```

# Secure Ingress

* Access the service using the https node port [32584] .. you should get the default nginx self signed cert `subject: O=Acme Co; CN=Kubernetes Ingress Controller Fake Certificate`

```
oot@master:/home/mohamed/cks/ingress# kubectl get pod,svc,ingress -n ingress-nginx
Warning: extensions/v1beta1 Ingress is deprecated in v1.14+, unavailable in v1.22+; use networking.k8s.io/v1 Ingress
NAME                                            READY   STATUS      RESTARTS   AGE
pod/ingress-nginx-admission-create-k2xkt        0/1     Completed   0          14m
pod/ingress-nginx-admission-patch-w5zq4         0/1     Completed   0          14m
pod/ingress-nginx-controller-785557f9c9-6rzrx   1/1     Running     0          14m

NAME                                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/ingress-nginx-controller             NodePort    10.108.169.210   <none>        80:30796/TCP,443:32584/TCP   14m
service/ingress-nginx-controller-admission   ClusterIP   10.110.3.40      <none>        443/TCP                      14m


 mohamed@Mohameds-MacBook-Pro  ~  curl -v https://34.83.45.155:32584/api -k
*   Trying 34.83.45.155...
* TCP_NODELAY set
* Connected to 34.83.45.155 (34.83.45.155) port 32584 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-AES128-GCM-SHA256
* ALPN, server accepted to use h2
* Server certificate:
*  subject: O=Acme Co; CN=Kubernetes Ingress Controller Fake Certificate
*  start date: May 24 05:41:42 2021 GMT
*  expire date: May 24 05:41:42 2022 GMT
*  issuer: O=Acme Co; CN=Kubernetes Ingress Controller Fake Certificate
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7faae380d600)
> GET /api HTTP/2
> Host: 34.83.45.155:32584
> User-Agent: curl/7.64.1
> Accept: */*
>
* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
< HTTP/2 200
< date: Mon, 24 May 2021 05:56:12 GMT
< content-type: text/html
< content-length: 45
< last-modified: Mon, 11 Jun 2007 18:53:14 GMT
< etag: "2d-432a5e4a73a80"
< accept-ranges: bytes
< strict-transport-security: max-age=15724800; includeSubDomains
<
<html><body><h1>It works!</h1></body></html>
* Connection #0 to host 34.83.45.155 left intact
* Closing connection 0
 mohamed@Mohameds-MacBook-Pro  ~ 
```

* create our own certificate:
1) generate private key and certificates
```
root@master:/home/mohamed/cks/ingress# openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
Can't load /root/.rnd into RNG
139854281695680:error:2406F079:random number generator:RAND_load_file:Cannot open file:../crypto/rand/randfile.c:88:Filename=/root/.rnd
Generating a RSA private key
..............................................................................................................................................++++
..................................++++
writing new private key to 'key.pem'
-----
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
Common Name (e.g. server FQDN or YOUR name) []:secure-ingress.com
Email Address []:
```

2) create kubernetes secret using generated key & cert

```
root@master:/home/mohamed/cks/ingress# kubectl create secret tls secure-ingress-tls --cert=cert.pem --key=key.pem
secret/secure-ingress-tls created

root@master:/home/mohamed/cks/ingress# kubectl get secret secure-ingress-tls
NAME                 TYPE                DATA   AGE
secure-ingress-tls   kubernetes.io/tls   2      13s
```

3) create kubernetes secure ingress object

```
root@master:/home/mohamed/cks/ingress# kubectl -f secure-ingress.yaml create
ingress.networking.k8s.io/tls-ingress created
root@master:/home/mohamed/cks/ingress# cat secure-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  tls:
  - hosts:
      -  secure-ingress.com
    secretName: secure-ingress-tls
  rules:
  - host: secure-ingress.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: frontend-svc
            port:
              number: 80

```

* test the secrure ingress
NOTE: if  we used `curl -v https://34.83.45.155:32584/api -k` we will get the default ingress cert , so we have to pass the hostname to curl. CN should be `CN=secure-ingress.com`

```
 mohamed@Mohameds-MacBook-Pro  ~  curl  https://secure-ingress.com:32584/api -kv --resolve secure-ingress.com:32584:34.83.45.155
* Added secure-ingress.com:32584:34.83.45.155 to DNS cache
* Hostname secure-ingress.com was found in DNS cache
*   Trying 34.83.45.155...
* TCP_NODELAY set
* Connected to secure-ingress.com (34.83.45.155) port 32584 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-AES128-GCM-SHA256
* ALPN, server accepted to use h2
* Server certificate:
*  subject: C=AU; ST=Some-State; O=Internet Widgits Pty Ltd; CN=secure-ingress.com
*  start date: May 24 06:02:20 2021 GMT
*  expire date: May 24 06:02:20 2022 GMT
*  issuer: C=AU; ST=Some-State; O=Internet Widgits Pty Ltd; CN=secure-ingress.com
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7faf1780d600)
> GET /api HTTP/2
> Host: secure-ingress.com:32584
> User-Agent: curl/7.64.1
> Accept: */*
>
* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
< HTTP/2 200
< date: Mon, 24 May 2021 06:45:02 GMT
< content-type: text/html
< content-length: 45
< last-modified: Mon, 11 Jun 2007 18:53:14 GMT
< etag: "2d-432a5e4a73a80"
< accept-ranges: bytes
< strict-transport-security: max-age=15724800; includeSubDomains
<
<html><body><h1>It works!</h1></body></html>
* Connection #0 to host secure-ingress.com left intact
* Closing connection 0
```