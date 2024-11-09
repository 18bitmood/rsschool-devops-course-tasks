# RS School DevOps course

## Files structure:

`general.tf` - general Terraform settings.
`providers.tf` - defines providers here.
`backend.tf` - setups s3 bucket to store Terraform state.
`variables.tf` - definition of variables can be used.

`.github/workflows/terraform.yml` - the code for GitHub actions.
`github-oidc.tf` - settings for setup OIDC connection of GitHub actions with AWS.
`github-policies.tf` - attaching required policies for GitHub actions being able to run the code.

`vpc.tf` - the definition for VPC.
`key-pair.tf` - the code for creating the key pair.
`security-groups.tf` - all the code related to security groups.
`network-acls.tf` - ACLs releated code.

`server.tf` - the code for creating EC2 instance that will be used as K3S and Jenkins server.
`agent.tf` - the code for creating EC2 instance that will be used as K3S agent.

Outdated files:
`ec2-instances.tf` - the code for EC2 instances creation in public and private subnets.
`nat-instance.tf` - the code for NAT instance (and related resources) creation.
`bastion.tf` - definition of bastion host to access private instances. Also these file includes the code for creating the Kubernetes cluster on private instances.

The code in current state creates the next infrastructure:

1. VPC with public subnet.
2. EC2 instances in public subnet. One of them is used as K3S server and the other two are used as K3S agent.

Then it installs Jenkins on the first agent instance.

# Jenkins

## Accessing Jenkins

After the infrastructure is deployed:

1. Get Jenkins NodePort by running this command on the server:
```bash
sudo kubectl get svc -n jenkins
```

2. Retrieve the admin password by running this command on the server:
```bash
sudo kubectl exec -n jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password
```

3. Open http://AGENT_2_PUBLIC_IP:NODEPORT and login with user 'admin' and password.


## Jenkins plugins

Here are the plugins you need to install through Jenkins UI:

- Pipeline
- Pipeline: Stage View
- Git
- Pipeline: GitHub


## WordPress APP deployment pipeline:

- In Jenkins UI click "New Item"
- Select "Pipeline"
- Name it "deploy-wordpress"
- In Pipeline configuration, select "Pipeline script from SCM"
- Choose Git as SCM
- Enter repository URL: https://github.com/18bitmood/rsschool-wordpress.git
- Set branch to */main
- Set Script Path to "Jenkinsfile"
- Save and click "Build Now" to run the pipeline


## Fix helm installation on container

On agent instance:

```bash
sudo kubectl exec -it -n jenkins jenkins-0 -- /bin/bash

# Then inside the container:
export PATH=$PATH:/var/jenkins_home/bin
mkdir -p /var/jenkins_home/bin
cd /var/jenkins_home
curl -LO https://get.helm.sh/helm-v3.12.3-linux-amd64.tar.gz
tar -zxvf helm-v3.12.3-linux-amd64.tar.gz
mv linux-amd64/helm /var/jenkins_home/bin/

# Then from agent instance:
sudo kubectl rollout restart statefulset jenkins -n jenkins
```

## Troubleshoot unavailable updates.jenkins.io


This is a resolution issue that can be fixed on AGENT:

```bash
sudo kubectl -n kube-system rollout restart deployment coredns
sudo kubectl rollout restart statefulset jenkins -n jenkins
```

If it doen't work, then try the next:

Initial Testing:
```bash
sudo kubectl run dns-debug -n kube-system --image=busybox:1.28 -- sleep 3600
sudo kubectl exec -it -n kube-system dns-debug -- nslookup google.com 10.0.0.2
```

Then edit the k3s config file:

```bash
sudo vi /etc/rancher/k3s/config.yaml
# And add the following lines:

kubelet-arg:
  - "cluster-dns=10.0.0.2"
  - "cluster-domain=cluster.local"
  - "resolv-conf=/run/systemd/resolve/resolv.conf"
```

Apply Changes:

```bash
sudo systemctl restart k3s
```

After that, need to be run on SERVER:

```bash
sudo kubectl create configmap k3s-config --from-file=/etc/rancher/k3s/k3s.yaml -n jenkins
```
