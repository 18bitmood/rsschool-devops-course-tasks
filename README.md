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

1. VPC with 2 public subnet.
2. EC2 instances in public subnet. One of them is used as K3S server and the other one is used as K3S agent.

## Accessing Jenkins

After the infrastructure is deployed:

1. Get Jenkins NodePort by running this command on the server:
```bash
sudo kubectl get svc -n jenkins
```

2. Retrieve the admin password by running this command on the server:
```bash
kubectl exec -n jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password
```

3. Open http://AGENT_PUBLIC_IP:NODEPORT and login with admin user and password.
