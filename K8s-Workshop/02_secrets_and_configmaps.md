

```bash
kubectl create secret generic tls-certs --from-file=tls/
```


```bash
kubectl create -f pods/secure-monolith.yaml
```