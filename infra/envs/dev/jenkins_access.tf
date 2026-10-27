resource "aws_iam_user" "jenkins" {
  name = "shipit-jenkins"
}

data "aws_iam_policy_document" "jenkins_ecr" {
  # Logging in to ECR can't be limited to one repository, AWS requires "*" here
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Everything else is limited to the one repository
  statement {
    sid = "PushAndInspectOneRepo"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeImageScanFindings",
    ]
    resources = [module.ecr_orders_api.repository_arn]
  }
}

resource "aws_iam_user_policy" "jenkins_ecr" {
  name   = "ecr-push-orders-api"
  user   = aws_iam_user.jenkins.name
  policy = data.aws_iam_policy_document.jenkins_ecr.json
}
