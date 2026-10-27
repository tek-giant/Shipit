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

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

data "aws_iam_policy_document" "jenkins_deploy" {
  statement {
    sid     = "UpdateOneService"
    actions = ["ecs:UpdateService", "ecs:DescribeServices"]
    resources = [
      "arn:aws:ecs:${local.region}:${local.account_id}:service/shipit-dev-cluster/orders-api"
    ]
  }

  # AWS does not support resource-level limits for these two actions
  statement {
    sid       = "TaskDefinitions"
    actions   = ["ecs:RegisterTaskDefinition", "ecs:DescribeTaskDefinition"]
    resources = ["*"]
  }

  statement {
    sid     = "PassOnlyTheServiceRolesToEcs"
    actions = ["iam:PassRole"]
    resources = [
      "arn:aws:iam::${local.account_id}:role/shipit-dev-ecs-execution",
      "arn:aws:iam::${local.account_id}:role/shipit-dev-orders-api-task",
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_user_policy" "jenkins_deploy" {
  name   = "ecs-deploy-orders-api"
  user   = aws_iam_user.jenkins.name
  policy = data.aws_iam_policy_document.jenkins_deploy.json
}
