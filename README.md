# RS School DevOps course

## Files structure:

`backend.tf` - setups s3 bucket to store Terraform state.
`general.tf` - general Terraform settings.
`providers.tf` - defines providers here.
`variables.tf` - definition of variables can be used.

`github-oidc.tf` - settings for setup OIDC connection of GitHub actions with AWS.
`github-policies.tf` - attaching required policies for GitHub actions being able to run the code.
`.github/workflows/terraform.yml` - the code for GitHub actions.

`vpc.tf` - the definition for VPC.
`key-pair.tf` - the code for creating the key pair.
`security-groups.tf` - all the code related to security groups.
`network-acls.tf` - ACLs releated code.

`ec2-instances.tf` - the code for EC2 instances creation in public and private subnets.
`nat-instance.tf` - the code for NAT instance (and related resources) creation.
`bastion.tf` - definition of bastion host to access private instances. Also these file includes the code for creating the Kubernetes cluster on private instances.

The code in current state creates the next infrastructure:

1. VPC with 2 public and 2 private subnets.
2. EC2 instances in public and private subnets.
3. NAT instance - through which the private instances can access the Internet.
4. Bastion host - through which you can access private instances.
5. Kubernetes cluster deployed on private instances.
