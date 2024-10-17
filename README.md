# rsschool-devops-course-tasks

Files structure:

`backend.tf` - for setup s3 bucket for terraform to store the state.
`general.tf` - general terraform settings.
`github-oidc.tf` - settings for setup OIDC connection of GitHub actions with AWS.
`github-policies.tf` - attaching required policies for GitHub actions being able to run the code.
`providers.tf` - defines providers here.
`resources.tf` - what resources will be created.
`variables.tf` - definition of variables can be used.
`bastion.tf` - definition of bastion host to access private instances.
`ec2-instances.tf` - the code for EC2 instances creation in public and private subnets.
`network-acls.tf` - ACLs releated code.
`security-groups.tf` - all the code related to security groups.
`vpc.tf` - the definition for vpc.

Github actions workflow are defined in  `.github/workflows/terraform.yml`.
