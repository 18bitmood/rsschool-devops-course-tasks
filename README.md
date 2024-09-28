# rsschool-devops-course-tasks

In the current state, the existing terraform code describing the next infrastructure:

1. In region 'us-east-1' - by default, can be redefined - it creates one t2.micro Ubuntu EC2 instance.
2. It creates GitHubActionsRole and attaches the required permissions to it to run pipelines.
3. It setups the connection with GitHub Actions using OIDC.

