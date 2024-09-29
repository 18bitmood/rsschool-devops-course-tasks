# Create the OIDC provider for GitHub
resource "aws_iam_openid_connect_provider" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98b3f39f4c3c92b8c4e3a9b9c3b0b2a6", # GitHub's OIDC thumbprint
  ]
}

# Define the trust policy for GitHub OIDC
data "aws_iam_policy_document" "github_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_oidc.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:18bitmood/rsschool-devops-course-tasks:ref:refs/heads/main",
        "repo:18bitmood/rsschool-devops-course-tasks:ref:refs/heads/task_1_submission",
        "repo:18bitmood/rsschool-devops-course-tasks:ref:refs/heads/*"
      ]
    }
  }
}
