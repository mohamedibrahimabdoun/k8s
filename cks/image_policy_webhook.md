git clone https://github.com/flavio/kube-image-bouncer.git

* hostfile
```
vagrant@k8smaster:/etc/kubernetes$ cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

172.16.25.100 k8smaster
172.16.25.101 kube01
172.16.25.102 kube02


```
* Build docker image from kube-image-bouncer repo

```docker
FROM golang:1.8-alpine

RUN  apk update && apk add git && git clone https://github.com/flavio/kube-image-bouncer.git && mkdir -p /go/src/github.com/flavio
RUN  cp -r kube-image-bouncer /go/src/github.com/flavio
WORKDIR /go/src/github.com/flavio/kube-image-bouncer
RUN go build -v
EXPOSE 1323

```
sudo docker build --network=host -t imagepolicyserver  .

```
$ sudo docker images | grep imagepolicyserver
imagepolicyserver                    latest       b582f937288f   About a minute ago   45.3MB
vagrant@k8smaster:~/kube-image-bouncer$
```

The webhook endpoint must be secured by tls to be used by kubernetes. This certificate can also be a self-signed one.

* In k8s master node Ensure the ImagePolicyWebhook admission controller is enabled.
```bash
sudo mkdir -p /etc/kubernetes/admission/


```

* Create a server key and certificate with the following command:
```bash
$ sudo openssl req  -nodes -new -x509 -keyout /etc/kubernetes/admission/webhook-svc-key.pem -out /etc/kubernetes/admission/webhook-svc-cert.pem
Can't load /home/vagrant/.rnd into RNG
140115928318400:error:2406F079:random number generator:RAND_load_file:Cannot open file:../crypto/rand/randfile.c:88:Filename=/home/vagrant/.rnd
Generating a RSA private key
....................................................................................+++++
...............................................................................+++++
writing new private key to '/etc/kubernetes/admission/webhook-svc-key.pem'
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
Common Name (e.g. server FQDN or YOUR name) []:k8smaster
Email Address []:

```



The API server uses a certificate to prove its identity. This certificate can also be a self-signed one.

* Create a server key and certificate with the following command:
```bash
$ sudo openssl req  -nodes -new -x509 -keyout /etc/kubernetes/admission/apiserver-client-key.pem -out /etc/kubernetes/admission/apiserver-client-cert.pem

Can't load /home/vagrant/.rnd into RNG
140285096223168:error:2406F079:random number generator:RAND_load_file:Cannot open file:../crypto/rand/randfile.c:88:Filename=/home/vagrant/.rnd
Generating a RSA private key
..+++++
....................+++++
writing new private key to '/etc/kubernetes/admission/apiserver-client-key.pem'
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
Common Name (e.g. server FQDN or YOUR name) []:k8smaster
Email Address []:
```



* Create an admission control configuration file named /etc/kubernetes/admission_configuration.yaml file with the following contents:

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
  - name: ImagePolicyWebhook
    configuration:
      imagePolicy:
        kubeConfigFile: /etc/kubernetes/admission/kubeconf
        allowTTL: 50
        denyTTL: 50
        retryBackoff: 500
        defaultAllow: false
```

Create a kubeconfig file /etc/kubernetes/admission/kubeconf with the following contents:

```yaml
apiVersion: v1
kind: Config

# clusters refers to the remote service.
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/admission/webhook-svc-cert.pem  # CA for verifying the remote service.
    server: https://k8smaster:1323/image_policy                  # URL of remote service to query. Must use 'https'.
  name: image-checker

contexts:
- context:
    cluster: image-checker
    user: api-server
  name: image-checker
current-context: image-checker
preferences: {}

# users refers to the API server's webhook configuration.
users:
- name: api-server
  user:
    client-certificate: /etc/kubernetes/admission/apiserver-client-cert.pem     # cert for the webhook admission controller to use
    client-key:  /etc/kubernetes/admission/apiserver-client-key.pem             # key matching the cert
```


* start the imagewebhook webservice container
```docker
sudo docker run -d --network=host  --name imagepolicywebhook_service --rm -v /etc/kubernetes/admission/webhook-svc-key.pem:/certs/webhook-svc-key.pem:ro -v /etc/kubernetes/admission/webhook-svc-cert.pem:/certs/webhook-svc-cert.pem:ro -p 1323:1323 imagepolicyserver:latest ./kube-image-bouncer -k /certs/webhook-svc-key.pem -c /certs/webhook-svc-cert.pem --debug


```
* test the services is running :
```
sudo curl https://k8smaster:1323/image_policy -v --cert /etc/kubernetes/admission/webhook-svc-cert.pem  --key /etc/kubernetes/admission/webhook-svc-key.pem -k -d @/etc/kubernetes/admission/image_review_obj.json
*   Trying 172.16.25.100...
* TCP_NODELAY set
* Connected to k8smaster (172.16.25.100) port 1323 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Client hello (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-AES128-GCM-SHA256
* ALPN, server accepted to use h2
* Server certificate:
*  subject: C=AU; ST=Some-State; O=Internet Widgits Pty Ltd; CN=k8smaster
*  start date: Sep 18 00:34:22 2021 GMT
*  expire date: Oct 18 00:34:22 2021 GMT
*  issuer: C=AU; ST=Some-State; O=Internet Widgits Pty Ltd; CN=k8smaster
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x5653d516d600)
> POST /image_policy HTTP/2
> Host: k8smaster:1323
> User-Agent: curl/7.58.0
> Accept: */*
> Content-Length: 400
> Content-Type: application/x-www-form-urlencoded
>
* Connection state changed (MAX_CONCURRENT_STREAMS updated)!
* We are completely uploaded and fine
< HTTP/2 200
< content-type: application/json; charset=UTF-8
< content-length: 75
< date: Sat, 18 Sep 2021 00:42:12 GMT
<
* Connection #0 to host k8smaster left intact
{"metadata":{"creationTimestamp":null},"spec":{},"status":{"allowed":true}}


#####
cat /etc/kubernetes/admission/image_review_obj.json
{
  "apiVersion":"imagepolicy.k8s.io/v1alpha1",
  "kind":"ImageReview",
  "spec":{
    "containers":[
      {
        "image":"k8s.gcr.io/myimage:v1"
      },
      {
        "image":"k8s.gcr.io/myimage@sha256:beb6bd6a68f114c1dc2ea4b28db81bdf91de202a9014972bec5e4d9171d90ed"
      }
    ],
    "annotations":{
      "mycluster.image-policy.k8s.io/ticket-1234": "break-glass"
    },
    "namespace":"kube-system"
  }
}

```
* run test pod while the service is up and health
```
$ kubectl run test-latest --image=nginx
Error from server (Forbidden): pods "test-latest" is forbidden: image policy webhook backend denied one or more images: Images using latest tag are not allowed
###
 kubectl run test-119 --image=nginx:1.19
pod/test-119 created

```

* create test pod while the imagepolicy webhook service is down and defaultAllow: false
```
 sudo docker ps | grep image
6fb4cc9ad0f3   imagepolicyserver:latest   "./kube-image-bounce…"   9 minutes ago    Up 9 minutes              imagepolicywebhook_service
vagrant@k8smaster:/etc/kubernetes$ sudo docker kill 6fb4cc9ad0f3
6fb4cc9ad0f3
vagrant@k8smaster:/etc/kubernetes$ kubectl run test-119-v2 --image=nginx:1.19
Error from server (Forbidden): pods "test-119-v2" is forbidden: Post "https://k8smaster:1323/image_policy?timeout=30s": dial tcp 172.16.25.100:1323: connect: connection refused
vagrant@k8smaster:/etc/kubernetes$

```
