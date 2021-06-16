* Install dependency and other software to get started:

$  sudo apt-get install wget apt-transport-https gnupg lsb-release

*  download the public key from Aquasecurity:

$ wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -


$ echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | \
sudo tee -a /etc/apt/sources.list.d/trivy.list


$ sudo apt-get update

$ sudo apt-get install trivy -y

$ trivy image nginx

