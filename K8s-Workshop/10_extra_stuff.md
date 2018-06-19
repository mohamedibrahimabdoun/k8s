```bash
gcloud auth list
```

```bash
➜  docker-and-kubernetes-workshop git:(master) ✗ gcloud auth list
             Credentialed Accounts
ACTIVE  ACCOUNT
*       demi.benari@gmail.com

To set the active account, run:
    $ gcloud config set account `ACCOUNT`
```

```bash
gcloud config set account demi.benari@gmail.com
```

```bash
gcloud projects create docker-k8s-workshop \
                --name="demi-docker-k8s-workshop"
```

```bash
➜  docker-and-kubernetes-workshop git:(master) ✗ gcloud projects create demi-docker-k8s-workshop --name="demi-docker-k8s-workshop"
Create in progress for [https://cloudresourcemanager.googleapis.com/v1/projects/demi-docker-k8s-workshop].
Waiting for [operations/pc.309581532681580591] to finish...done.  
```

TODO: The the project must be linked to a billing account

```bash
➜  docker-and-kubernetes-workshop git:(master) ✗ gcloud projects list
PROJECT_ID                NAME                      PROJECT_NUMBER
demi-docker-k8s-workshop  demi-docker-k8s-workshop  1101010101010


➜  docker-and-kubernetes-workshop git:(master) ✗ gcloud projects describe demi-docker-k8s-workshop

createTime: '2017-12-09T16:26:40.823Z'
lifecycleState: ACTIVE
name: demi-docker-k8s-workshop
projectId: demi-docker-k8s-workshop
projectNumber: '1101010101010'


➜  docker-and-kubernetes-workshop git:(master) ✗ gcloud config set project demi-docker-k8s-workshop
Updated property [core/project].

➜  docker-and-kubernetes-workshop git:(master) ✗ gcloud config get-value project                   
Your active configuration is: [panorays]
demi-docker-k8s-workshop


docker-and-kubernetes-workshop git:(master) ✗ gcloud beta billing projects link demi-docker-k8s-workshop --billing-account="001122-AA0011-4422BB"
billingAccountName: billingAccounts/001122-AA0011-4422BB
billingEnabled: true
name: projects/demi-docker-k8s-workshop/billingInfo
projectId: demi-docker-k8s-workshop



➜  docker-and-kubernetes-workshop git:(master) ✗ gcloud compute zones list
API [compute.googleapis.com] not enabled on project [665273939836]. 
Would you like to enable and retry?  (Y/n)?  Y

Enabling service compute.googleapis.com on project 665273939836...
Waiting for async operation operations/tmo-acf.e5df523f-0f69-4447-8448-89abfaf29957 to complete...
Operation finished successfully. The following command can describe the Operation details:
 gcloud service-management operations describe operations/tmo-acf.e5df523f-0f69-4447-8448-89abfaf29957
NAME                    REGION                STATUS  NEXT_MAINTENANCE  TURNDOWN_DATE
asia-east1-c            asia-east1            UP
asia-east1-b            asia-east1            UP
asia-east1-a            asia-east1            UP
asia-northeast1-b       asia-northeast1       UP
asia-northeast1-a       asia-northeast1       UP
asia-northeast1-c       asia-northeast1       UP
asia-south1-a           asia-south1           UP
asia-south1-c           asia-south1           UP
asia-south1-b           asia-south1           UP
asia-southeast1-a       asia-southeast1       UP
asia-southeast1-b       asia-southeast1       UP
australia-southeast1-a  australia-southeast1  UP
australia-southeast1-b  australia-southeast1  UP
australia-southeast1-c  australia-southeast1  UP
europe-west1-d          europe-west1          UP
europe-west1-b          europe-west1          UP
europe-west1-c          europe-west1          UP
europe-west2-b          europe-west2          UP
europe-west2-c          europe-west2          UP
europe-west2-a          europe-west2          UP
europe-west3-b          europe-west3          UP
europe-west3-a          europe-west3          UP
europe-west3-c          europe-west3          UP
southamerica-east1-b    southamerica-east1    UP
southamerica-east1-c    southamerica-east1    UP
southamerica-east1-a    southamerica-east1    UP
us-central1-b           us-central1           UP
us-central1-f           us-central1           UP
us-central1-a           us-central1           UP
us-central1-c           us-central1           UP
us-east1-d              us-east1              UP
us-east1-c              us-east1              UP
us-east1-b              us-east1              UP
us-east4-a              us-east4              UP
us-east4-b              us-east4              UP
us-east4-c              us-east4              UP
us-west1-c              us-west1              UP
us-west1-b              us-west1              UP
us-west1-a              us-west1              UP


➜  docker-and-kubernetes-workshop git:(master) ✗ gcloud compute zones list
NAME                    REGION                STATUS  NEXT_MAINTENANCE  TURNDOWN_DATE
asia-east1-c            asia-east1            UP
asia-east1-b            asia-east1            UP
asia-east1-a            asia-east1            UP
asia-northeast1-b       asia-northeast1       UP
asia-northeast1-a       asia-northeast1       UP
asia-northeast1-c       asia-northeast1       UP
asia-south1-a           asia-south1           UP
asia-south1-c           asia-south1           UP
asia-south1-b           asia-south1           UP
asia-southeast1-a       asia-southeast1       UP
asia-southeast1-b       asia-southeast1       UP
australia-southeast1-a  australia-southeast1  UP
australia-southeast1-b  australia-southeast1  UP
australia-southeast1-c  australia-southeast1  UP
europe-west1-d          europe-west1          UP
europe-west1-b          europe-west1          UP
europe-west1-c          europe-west1          UP
europe-west2-b          europe-west2          UP
europe-west2-c          europe-west2          UP
europe-west2-a          europe-west2          UP
europe-west3-b          europe-west3          UP
europe-west3-a          europe-west3          UP
europe-west3-c          europe-west3          UP
southamerica-east1-b    southamerica-east1    UP
southamerica-east1-c    southamerica-east1    UP
southamerica-east1-a    southamerica-east1    UP
us-central1-b           us-central1           UP
us-central1-f           us-central1           UP
us-central1-a           us-central1           UP
us-central1-c           us-central1           UP
us-east1-d              us-east1              UP
us-east1-c              us-east1              UP
us-east1-b              us-east1              UP
us-east4-a              us-east4              UP
us-east4-b              us-east4              UP
us-east4-c              us-east4              UP
us-west1-c              us-west1              UP
us-west1-b              us-west1              UP
us-west1-a              us-west1              UP


➜  docker-and-kubernetes-workshop git:(master) ✗ gcloud config set compute/zone europe-west1-b
Updated property [compute/zone].

➜  docker-and-kubernetes-workshop git:(master) ✗ gcloud container clusters create k8s-apps
Creating cluster k8s-apps...done.                                                                                                                   
Created [https://container.googleapis.com/v1/projects/demi-docker-k8s-workshop/zones/europe-west1-b/clusters/k8s-apps].
kubeconfig entry generated for k8s-apps.
NAME      LOCATION        MASTER_VERSION  MASTER_IP      MACHINE_TYPE   NODE_VERSION  NUM_NODES  STATUS
k8s-apps  europe-west1-b  1.7.8-gke.0     35.195.87.129  n1-standard-1  1.7.8-gke.0   3          RUNNING

```

```bash
➜  docker-and-kubernetes-workshop git:(master) ✗ gcloud container clusters describe k8s-apps
addonsConfig:
  networkPolicyConfig:
    disabled: true
clusterIpv4Cidr: 10.28.0.0/14
createTime: '2017-12-09T20:13:20+00:00'
currentMasterVersion: 1.7.8-gke.0
currentNodeCount: 3
currentNodeVersion: 1.7.8-gke.0
endpoint: 35.195.87.129
initialClusterVersion: 1.7.8-gke.0
instanceGroupUrls:
- https://www.googleapis.com/compute/v1/projects/demi-docker-k8s-workshop/zones/europe-west1-b/instanceGroupManagers/gke-k8s-apps-default-pool-3b3b4edf-grp
labelFingerprint: a9dc16a7
legacyAbac:
  enabled: true
locations:
- europe-west1-b
loggingService: logging.googleapis.com
masterAuth:
  clientCertificate: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMyakNDQWNLZ0F3SUJBZ0lRZHhBbE9vME1HZFYxTUo5UUVCeEJoVEFOQmdrcWhraUc5dzBCQVFzRkFEQXYKTVMwd0t3WURWUVFERXlRME16UTJabVk0TUMwMU5qTmpMVFJoTjJJdFlXWTFaaTFsWmpnME5UVXpZV1EzTUdZdwpIaGNOTVRjeE1qQTVNakF4TXpJeFdoY05Nakl4TWpBNE1qQXhNekl4V2pBUk1ROHdEUVlEVlFRREV3WmpiR2xsCmJuUXdnZ0VpTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFDb1VPdE9kZktXaVRFVnpuVjUKUGRTN0htcm1RclFJRTVyTGZSMXEwQllMNFR0c1ZlU3I0aDNENGdHNGs5dWc2d1JDa0ZVWC8vanJyR1R1WHE2ZAo2d2JXTDM0eHFLckI5ZldQN1ZvZTVMRk5MWWhOeXlmU3NHRzQ4NkxiUTlXaXJ5cnJkaWFoM0hEaWFteWlEc2Y3Cmw5cEdnbzR3c2lsN0c4dmQ0QUszOGZiMDZMVDVQSWRVYll4WXplcVJMQWlNcExoUGJaNEhmVWw0Slp2Y0R0TE4KR0t5RFE2dHFHaldJakI2OGY4WVFNMWdEaGdWMEJnQlBSbkxjdlQvSksvamZ4eEhEYmUrUXhOOUlQME4rOVpFRgp3OWg4TTVmQlRhUXNYdWZpbmdnVnpDWG9zc0hIbzVjdy81eVpPTjZsdkJRMVBSNFVpU1NXY3RjTGlVazEreFc0Clp5anRBZ01CQUFHakVEQU9NQXdHQTFVZEV3RUIvd1FDTUFBd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFJbWoKbFlDL1VzZVZ3ZmRjMDlpbHRFbGMzVGVmVmo1UnVKaTloQkhFNzRWUFJYTXJldm5uMlh2NDA2TUU0Z1FydUpTTwpFL2NGYm9WL1k5aFVYbkJJeEVmUHZOQXFXaDcwcDRGUWpYVmRWTGZQTk5HemJhQWdKSTB4dnZoeHI1OWc4UEk4CklpNEVZVlVSKzVDTXdldEFMSURLV0JFR2lzeDdSVGxrcFNPUjh0UUxxbFk4T3BtTHRUOU83bTBkSmZaMnI5S3QKTW81UkJZY2pxc3NiTEVjd21zRDI5L05Eam9OZW1MVi9ZWENpU3QxVW1waWVmeW16TzhBVnAyb1VLeGpIMWd2OQo1V0ZqV0hacHkxOHJFNFN6d2Jqa0Z4MUxvVUxJWk82WnE0ZGdGNXYrSkZoMUxRUDFSNThRZ1Y3WmpRQWlYYWpMCmorR1oyaTI0Y3ZiVlNxUHdtUEk9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
  clientKey: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb3dJQkFBS0NBUUVBcUZEclRuWHlsb2t4RmM1MWVUM1V1eDVxNWtLMENCT2F5MzBkYXRBV0MrRTdiRlhrCnErSWR3K0lCdUpQYm9Pc0VRcEJWRi8vNDY2eGs3bDZ1bmVzRzFpOStNYWlxd2ZYMWorMWFIdVN4VFMySVRjc24KMHJCaHVQT2kyMFBWb3E4cTYzWW1vZHh3NG1wc29nN0grNWZhUm9LT01MSXBleHZMM2VBQ3QvSDI5T2kwK1R5SApWRzJNV00zcWtTd0lqS1M0VDIyZUIzMUplQ1diM0E3U3pSaXNnME9yYWhvMWlJd2V2SC9HRUROWUE0WUZkQVlBClQwWnkzTDAveVN2NDM4Y1J3MjN2a01UZlNEOURmdldSQmNQWWZET1h3VTJrTEY3bjRwNElGY3dsNkxMQng2T1gKTVArY21UamVwYndVTlQwZUZJa2tsbkxYQzRsSk5mc1Z1R2NvN1FJREFRQUJBb0lCQUFOK3RxYkk3VEljcnRVVApRSk9LdjAyVUNwMDF1bDVHa0pySmJNc2QxSzljekdxVW9xeHRCQTJLdGxyRSt6VUNzWjBlT1I0ZFN4Sm9ZSDk3ClNOTkU5ajNoVU9vQUQyejZuMUE1NzAvMVBneVZDdlVENkdqeXVsSVRBUWt6aGVQeHU0bVZ5UG5vY0JHZzFjT2gKc2ZFSDkxalZJaXNNV3E4bDVjYjVmVStnMUc0WkZFSFNHSVhsWVp3aEhHTjZpbXhBVXdPRkFiMUs4MVpNUXNTbQpsc3pDQTVXS3Rpckx0MExOR25IMnRGQWFwMUFYNHRBajVESDFRVEgybkF3QVd6MG81QmF1MWNNeC9NMHFadFMyCnBMRXc1U2NIMUh0RlVkRk9aTUdFeEVXNnNuSm8rd0R6elFFNThPWVdQeUtyLy94MU5QcHBwQi9WTXk5R3BSOFoKSzYzT1B2TUNnWUVBNDlTdzh2RVQ2R3dlTTRjQ3JYMkVKUVFLSVYzZnk1bERjY2pPakk2aGV3bmFBTFNBRGtNMQp6aWFiRVBsdEwrcGRZSklUaWc0Y0FrUHl6T2xtNWh2Q2R5azF2bGZaMkJnbVphWUc5ZU5jcGpNMmdOaCtqRzBIClpBSCsxU1VPL1M4YnEzalEzL3ZONnBzMTFaQmNqWjVmMWdmNEt3Um5LRGx1WnJveDBqZmUrOXNDZ1lFQXZTQjMKTXJGUUE0VFZmZzNIelhtbWw2YVBiVTVIVHV0WCtrOHh0Rkt4TWY4c1ZPemVaaUdPcEVsTTU3cXlFeU9mN2dabgphTlVScEZINEVOL0J0R09kQjBwZ2ZkZ2RXYzUwdTRaeVByeGs3K1NKTElZMWNkMVdzREk2K0dlSzNkVkI2cFVuCmNNQnh5aEQ4RUllUllSRTdRbW9TSk1mQmIxV3lGdnhudys0SUxOY0NnWUE3SUVlTHhPVFZ2TGxaeGYvNzVrY1YKRkNkTTRYL2k1ck9LSkFMMmwwMXhFTzF5b1dWYVRqYjRlU3hsQzFZNnlTZlNtQlphRGE5WEp5c3I0cWJCc1JLVwp1aXNvYXNRdVFKWTJheEFEWUMzN00rOUJJTzQybzFUM3IwempJK3J2NmZuVVZsWmV5b3AyQ0RIQWF1YWFHaS9rCjY4eUwzV2lvRjc5L0NYTkVpeHRqWVFLQmdRQ2ZUaEI1WjdleEx4dXhzU1BpcFJ5NVVyZ3ZaeWRUaDVNMHFhNkIKYU1JUERoU21lRnNoQmhVanR3YUxqc3ZlcVR4V2Y1aHRTa1F3K0VhTzJCdE91aldUNVlkL21TR24rdXFDNXMybQpvSVFaT1pSK0o1SXZGalNsOTdtS2NaVWNKRDBBdnFCWkxoRHJGd0ZyWHZZTElEdWRSc0YvcjY3MCsrY2x5M2dRCkpwbEdRd0tCZ0ZRY29oWnN1d2ZVOWJZcjdvL0NIQUxpekJEUHhseGlXbm9SdDZkUmJpZFhrZGZnWmI0Q2hNNUUKc1JQT0VXNGg1ZjRLbDV0WWVmZUM3Y1JRYnRPeGlhdi9keDFCWE1SRGU4YjNCSE5RdTJQcnhGa3h5ZUNXL0MxdQptUWlkL2hqN1hRTGNjUFBvdXo2UGdJeXk5NHRsd29JL1NRWWFhUjBNQmhJTkJCZStxQ0JmCi0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==
  clusterCaCertificate: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURDekNDQWZPZ0F3SUJBZ0lRT2NGbmFNa0lBV3UzRkJIR0Z4MXcxekFOQmdrcWhraUc5dzBCQVFzRkFEQXYKTVMwd0t3WURWUVFERXlRME16UTJabVk0TUMwMU5qTmpMVFJoTjJJdFlXWTFaaTFsWmpnME5UVXpZV1EzTUdZdwpIaGNOTVRjeE1qQTVNVGt4TXpJd1doY05Nakl4TWpBNE1qQXhNekl3V2pBdk1TMHdLd1lEVlFRREV5UTBNelEyClptWTRNQzAxTmpOakxUUmhOMkl0WVdZMVppMWxaamcwTlRVellXUTNNR1l3Z2dFaU1BMEdDU3FHU0liM0RRRUIKQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUURRKzRFNjJuN2tkczNIQVBrOXhoZnhBOE1yTkd2VXZjYnZwK0REdmN6LwozMnlTUkdxYU43REJmRlZ4anpkOGMrODg3am0xYnNPK1pHNDB1cUxHUmgzUVpBNXVva2wwQlZYTHROTTc2OWxoCnUwODJLdnB1QUVXbmY1dlgvYnlZNWpxZUR1TmpSZGN5bjdBN0hxSC92K05jdStKeWgwNUFtOXFudTVxdDl6OVkKeXZPSkY0bTl2dzRjbzIzM0MxckNiM2duemxsYkY3UnZPRXpFMW1qMDNNVUx3WGdXRHBzblFha0JKQUNWcmhWawpHK3h6TGJUMXdUdmNXMVYwWTE5NFVYNjYxRS92MmNGREFvSWoyWmdsZGgxaVpaWlh3ajlFT3lydDNTck80aWJ3Ckt1VDk5anFVckQ3enZUWWhVL25TRDdkOG9tNGZOYkQxdEVLVzNJNkVOdkdMQWdNQkFBR2pJekFoTUE0R0ExVWQKRHdFQi93UUVBd0lDQkRBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFEQwpGL29RUm5iNUY3RHNKRUxyS2F3YXRmOWhxQm5YT3pvZy9KaHJuMHQxVGpxMjJrSlNSR0JqYm9kOVBib1lBSHQ4ClRWbHRhTGpkTzRLUlBDOXVYTEh3dllMUkwyVjhWbWx0S3RHcU5qWGlocEl6VFFuai9oZnVjWi9EV3FjaGNQSysKbFdRbHY3RVRiTXRiQmYvbFQyVFBWbUpJbEx5WnpsSUxKa2pIR1laSHVTcTJ5MVhmOEcrNEphOEhoVE4yQ3pUYgoyT2xveE9OeEtJRkV2eHZJUjVkMTNLd0orZCtBa1pkMnZZNHZwdHNVeHJiOGovT2prOGxnclBJUlpCWnlndFFiCng0ekJsdkh4VU4rbVhtcFpvWC81dlhtVkRzcWJyb1dqdVlUb01zK2JHN1hBZnpkbXhTQ29EdmczUFBtamhGaWQKUmFnQVRDK0JQd2QzMXY3YUhCMHYKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
  password: 7Wc05rUxUhf848EL
  username: admin
monitoringService: monitoring.googleapis.com
name: k8s-apps
network: default
nodeConfig:
  diskSizeGb: 100
  imageType: COS
  machineType: n1-standard-1
  oauthScopes:
  - https://www.googleapis.com/auth/compute
  - https://www.googleapis.com/auth/devstorage.read_only
  - https://www.googleapis.com/auth/service.management.readonly
  - https://www.googleapis.com/auth/servicecontrol
  - https://www.googleapis.com/auth/logging.write
  - https://www.googleapis.com/auth/monitoring
  serviceAccount: default
nodeIpv4CidrSize: 24
nodePools:
- config:
    diskSizeGb: 100
    imageType: COS
    machineType: n1-standard-1
    oauthScopes:
    - https://www.googleapis.com/auth/compute
    - https://www.googleapis.com/auth/devstorage.read_only
    - https://www.googleapis.com/auth/service.management.readonly
    - https://www.googleapis.com/auth/servicecontrol
    - https://www.googleapis.com/auth/logging.write
    - https://www.googleapis.com/auth/monitoring
    serviceAccount: default
  initialNodeCount: 3
  instanceGroupUrls:
  - https://www.googleapis.com/compute/v1/projects/demi-docker-k8s-workshop/zones/europe-west1-b/instanceGroupManagers/gke-k8s-apps-default-pool-3b3b4edf-grp
  management: {}
  name: default-pool
  selfLink: https://container.googleapis.com/v1/projects/demi-docker-k8s-workshop/zones/europe-west1-b/clusters/k8s-apps/nodePools/default-pool
  status: RUNNING
  version: 1.7.8-gke.0
selfLink: https://container.googleapis.com/v1/projects/demi-docker-k8s-workshop/zones/europe-west1-b/clusters/k8s-apps
servicesIpv4Cidr: 10.31.240.0/20
status: RUNNING
zone: europe-west1-b


  password: 7Wc05rUxUhf848EL
  username: admin

```


```bash
➜  docker-and-kubernetes-workshop git:(master) ✗ kubectl cluster-info                            
Kubernetes master is running at https://35.195.87.129
GLBCDefaultBackend is running at https://35.195.87.129/api/v1/namespaces/kube-system/services/default-http-backend/proxy
Heapster is running at https://35.195.87.129/api/v1/namespaces/kube-system/services/heapster/proxy
KubeDNS is running at https://35.195.87.129/api/v1/namespaces/kube-system/services/kube-dns/proxy
kubernetes-dashboard is running at https://35.195.87.129/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.


https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/


➜  docker-and-kubernetes-workshop git:(master) ✗ kubectl proxy       
Starting to serve on 127.0.0.1:8001


http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy


➜  docker-and-kubernetes-workshop git:(master) ✗ kubectl run wordpress --image=tutum/wordpress --port=80
deployment "wordpress" created


```

For the pod to be accessible we need to expose it:
 ```bash
➜  docker-and-kubernetes-workshop git:(master) ✗ kubectl expose deployment wordpress --type=LoadBalancer
service "wordpress" exposed

```

```bash
➜  docker-and-kubernetes-workshop git:(master) ✗ kubectl describe services wordpress
Name:                     wordpress
Namespace:                default
Labels:                   run=wordpress
Annotations:              <none>
Selector:                 run=wordpress
Type:                     LoadBalancer
IP:                       10.31.241.72
LoadBalancer Ingress:     35.205.181.96
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  30735/TCP
Endpoints:                10.28.0.4:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason                Age   From                Message
  ----    ------                ----  ----                -------
  Normal  CreatingLoadBalancer  59s   service-controller  Creating load balancer
  Normal  CreatedLoadBalancer   3s    service-controller  Created load balancer
➜  docker-and-kubernetes-workshop git:(master) ✗ kubectl describe svc wordpress
Name:                     wordpress
Namespace:                default
Labels:                   run=wordpress
Annotations:              <none>
Selector:                 run=wordpress
Type:                     LoadBalancer
IP:                       10.31.241.72
LoadBalancer Ingress:     35.205.181.96
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  30735/TCP
Endpoints:                10.28.0.4:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason                Age   From                Message
  ----    ------                ----  ----                -------
  Normal  CreatingLoadBalancer  1m    service-controller  Creating load balancer
  Normal  CreatedLoadBalancer   15s   service-controller  Created load balancer
```

Only after the Load Balancer was created

```bash
➜  docker-and-kubernetes-workshop git:(master) ✗ kubectl get services wordpress
NAME        TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
wordpress   LoadBalancer   10.31.241.72   35.205.181.96   80:30735/TCP   2m
```

Now we want to delete the services

```bash

➜  docker-and-kubernetes-workshop git:(master) ✗ kubectl delete services wordpress
service "wordpress" deleted

➜  docker-and-kubernetes-workshop git:(master) ✗ kubectl delete deployment wordpress
deployment "wordpress" deleted

```

All now is cleaned up.

