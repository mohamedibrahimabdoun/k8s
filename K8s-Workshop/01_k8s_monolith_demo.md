 Provision a cluster to work with, this step takes a bit of time.

```bash
$ gcloud container clusters create k8s-apps --num-nodes=5
```

 Run the "monolith" Docker image: ```askcarter/monolith:1.0.0```

```bash
$ kubectl run monolith --image askcarter/monolith:1.0.0
```

  Expose it to the world so we can interact with it.  
The external LoadBalancer will take ~1m to provision.  (Then you'll be able to see its external IP address)

```bash
$ kubectl expose deployment monolith --port 80 --type LoadBalancer 
```

 Let us scale it up to 7 replicas.

```bash
 $ kubectl scale deployment monolith --replicas 7
```

See how easy this is?

Now we'd like to interact with our application.

```bash
 $ kubectl get service monolith
```

This will be an example output.

```bash
NAME       TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
monolith   LoadBalancer   10.31.241.198   35.195.252.97   80:32440/TCP   3m
```

```bash
 $ curl http://<EXTERNAL-IP>
```

Now to finish it off, we need to do some clean up. 
(Deleting the Service and it will remove the load balancer too, and delete the deployment)
```bash
$ kubectl delete services monolith 

$ kubectl delete deployment monolith
```